# Plan: Add Amazon ElastiCache (Redis) for the Cart Service

## Context

Today the cart service stores data in an **in-cluster Redis pod** (`redis-cart`) backed by an
`emptyDir` volume ([helm-chart/templates/cartservice.yaml:287-289](helm-chart/templates/cartservice.yaml#L287-L289)).
If that pod restarts, **all cart data is lost**. The goal is to replace it with a **managed
Amazon ElastiCache (Redis)** instance so cart data survives pod/node failures — and to document
the whole thing so it can be handed over (college submission).

Deliverable: **both** a working implementation (Terraform + Helm) **and** a step-by-step README guide.

---

## ✅ Won't break anything (guarantee)

This change is **100% additive** — every change is a **new file**, except one README edit that only
**appends** a section. Nothing existing is modified or removed:

- **`helm-chart/values.yaml` is NOT touched** → the default deployment (local / Docker Compose /
  current AKS CI) renders **exactly as before**, still using the in-cluster `redis-cart` pod.
- **No Helm template is edited** → `cartservice.yaml` etc. stay byte-for-byte identical.
- **The GitHub Actions CI/CD workflow is NOT touched** → your current pipeline keeps working.
- ElastiCache is **opt-in**: it only activates when you explicitly pass `-f values-elasticache.yaml`.
  If you never pass it, the repo behaves identically to today.
- The new `terraform/elasticache/` folder is isolated — it provisions only the Redis instance and
  touches no other infrastructure.
- **Safety check before we finish**: run `helm template` *without* the override and diff it against
  the current output to prove the default render is unchanged.

If you later decide you don't want it, deleting the override file + the terraform folder fully
reverts everything — no cleanup of the core app needed.

### Important constraint (must be stated in the README)
ElastiCache is only reachable from workloads **inside the same AWS VPC**. This means the boutique
app must run on **AWS EKS** (the setup the README already describes), not the Azure AKS cluster the
current GitHub Actions CI targets. If the grader runs on AKS, ElastiCache will not be reachable —
the README will call this out clearly.

### Why this is low-risk
The cart already supports an external Redis with **no application code change**:
[cartservice.yaml:83-89](helm-chart/templates/cartservice.yaml#L83-L89) sets the `REDIS_ADDR`
env var directly from `cartDatabase.connectionString`. We only change Helm values + add infra.
We will use ElastiCache with **in-transit encryption disabled** (plain TCP, no AUTH) so we avoid
the Istio-based TLS path ([cartservice.yaml:370-412](helm-chart/templates/cartservice.yaml#L370-L412)),
which this repo does not run.

---

## Changes

### 1. New Terraform module — `terraform/elasticache/`
Self-contained module that provisions a single-node Redis (cheapest, free-tier eligible
`cache.t4g.micro`). Takes the existing VPC/subnets/EKS-node-SG as inputs so it plugs into whatever
cluster exists (the repo has no Terraform yet, so this is standalone).

- `main.tf`
  - `aws_elasticache_subnet_group` — uses `var.subnet_ids` (private subnets of the EKS VPC).
  - `aws_security_group` "redis" — inbound TCP **6379** from `var.allowed_security_group_ids`
    (the EKS node security group) and/or `var.allowed_cidr_blocks` (VPC CIDR fallback); egress all.
  - `aws_elasticache_cluster` "cart" — `engine = "redis"`, `num_cache_nodes = 1`,
    `node_type = var.node_type`, `port = 6379`, no transit/at-rest encryption (demo simplicity),
    attached to the subnet group + security group.
- `variables.tf` — `name_prefix`, `region`, `vpc_id`, `subnet_ids`, `allowed_security_group_ids`,
  `allowed_cidr_blocks`, `node_type` (default `cache.t4g.micro`), `engine_version` (default `7.1`).
- `outputs.tf` — `redis_endpoint` = `"<primary address>:6379"` (the value to paste into Helm).
- `terraform.tfvars.example` — placeholder values + comments.
- `README.md` (module-level) — one-paragraph usage note.

### 2. New Helm override — `helm-chart/values-elasticache.yaml`
Mirrors the existing `values-aks.yaml` override pattern so the default `values.yaml` stays
working for local/in-cluster use (non-breaking). Contents:

```yaml
cartDatabase:
  type: redis
  # Replace with the `redis_endpoint` output from terraform/elasticache
  connectionString: "REPLACE_WITH_ELASTICACHE_ENDPOINT:6379"
  inClusterRedis:
    create: false        # stop deploying the redis-cart pod
```

This drives [cartservice.yaml:87-89](helm-chart/templates/cartservice.yaml#L87-L89) (sets
`REDIS_ADDR`) and skips the entire in-cluster Redis block
([cartservice.yaml:203](helm-chart/templates/cartservice.yaml#L203), guarded by
`inClusterRedis.create`).

> Note: `values.yaml` itself is **not** edited, so nothing breaks if the override isn't supplied.

### 3. New README section — "Cart Persistence with Amazon ElastiCache (Redis)"
Written in the existing README style (callouts, fenced commands, verify steps). Placed after the
CD / Argo Image Updater section and before `# Observability`. Covers:

1. **Why** — ephemeral `redis-cart` pod vs durable managed Redis (ties back to the README's own
   "most services are stateless" section).
2. **Constraint callout** — must run on AWS EKS, same VPC; not reachable from AKS.
3. **Provision** — two options:
   - Terraform: `cd terraform/elasticache && terraform init && terraform apply`
     (fill `vpc_id`, `subnet_ids`, EKS node SG from the cluster).
   - AWS Console fallback: create ElastiCache Redis (cluster mode disabled, 1 node,
     `cache.t4g.micro`, encryption in-transit OFF), in the EKS VPC's private subnets, SG allowing
     6379 from the node SG.
4. **Get the endpoint** — from `terraform output redis_endpoint` or the console.
5. **Wire it up** — paste endpoint into `helm-chart/values-elasticache.yaml`, deploy:
   `helm upgrade -i ... -f values.yaml -f values-elasticache.yaml` (and the GitOps equivalent:
   commit the override so Argo CD syncs it).
6. **Verify** (the proof cart persistence works):
   - Browse the app, add items to cart.
   - `kubectl delete pod -l app=cartservice -n boutique-app` (kill the cart pod).
   - Reload the site → **cart still has the items** (data lived in ElastiCache, not the pod).
   - Optional: exec a debug pod and `redis-cli -h <endpoint> KEYS '*'` to see stored carts.
   - Confirm the old `redis-cart` pod is gone: `kubectl get pod -n boutique-app | grep redis` → none.
7. **Cost & cleanup** — `cache.t4g.micro` is free-tier eligible (750 hrs/mo, 12 months), else
   ~$12/mo; `terraform destroy` to remove.

---

## Critical files

| File | Action |
|---|---|
| `terraform/elasticache/main.tf` | new — subnet group, SG, ElastiCache cluster |
| `terraform/elasticache/variables.tf` | new — inputs |
| `terraform/elasticache/outputs.tf` | new — `redis_endpoint` |
| `terraform/elasticache/terraform.tfvars.example` | new — sample inputs |
| `terraform/elasticache/README.md` | new — module usage |
| `helm-chart/values-elasticache.yaml` | new — override pointing cart at ElastiCache |
| `README.md` | edit — add ElastiCache section (no existing content removed) |

No application code and no existing Helm template changes are required — the cart already reads
`REDIS_ADDR` from `cartDatabase.connectionString`.

---

## Verification

0. **Prove nothing broke (default render unchanged)**:
   `helm template onlineboutique ./helm-chart -f helm-chart/values.yaml` → confirm it still renders
   the `redis-cart` Deployment/Service and `REDIS_ADDR: redis-cart:6379`, exactly as before the change.
1. **Terraform validates**: `cd terraform/elasticache && terraform init && terraform validate`
   (and `terraform plan` with the example tfvars filled against a real VPC).
2. **Helm renders correctly** (no AWS needed):
   `helm template onlineboutique ./helm-chart -f helm-chart/values.yaml -f helm-chart/values-elasticache.yaml`
   → assert the rendered `cartservice` Deployment has `REDIS_ADDR` = the ElastiCache endpoint, and
   that **no `redis-cart` Deployment/Service** is rendered.
3. **End-to-end (on an EKS cluster)**: apply, then run the cart-persistence test from README step 6
   (kill cart pod → cart survives).

---

## Out of scope (explicitly deferred)
- In-transit TLS / AUTH token for ElastiCache (needs Istio or an app-side TLS change).
- Multi-AZ / replication group (single node is enough for a demo).
- The other managed services discussed earlier (RDS/DynamoDB, Secrets Manager, X-Ray, Karpenter).
