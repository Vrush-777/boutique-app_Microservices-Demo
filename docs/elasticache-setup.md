# Cart Persistence with Amazon ElastiCache (Redis) — Setup Guide

This guide replaces the boutique cart's **in-cluster Redis pod** (`redis-cart`, ephemeral
`emptyDir` storage) with a **managed Amazon ElastiCache (Redis)** instance, so cart data survives
pod and node restarts.

> [!IMPORTANT]
> ElastiCache is reachable **only from inside the same AWS VPC**. Your boutique app must run on
> **AWS EKS** in that VPC. It is **not** reachable from a cluster running in another cloud
> (e.g. Azure AKS). If you don't have an EKS cluster, ElastiCache has nothing to connect to.

> [!NOTE]
> No application code changes are needed. The cart reads `REDIS_ADDR` from
> `cartDatabase.connectionString` in the Helm values — we only repoint it and stop deploying the
> in-cluster Redis pod.

> [!TIP]
> We deliberately use **in-transit encryption OFF** (plain TCP, no AUTH). The chart's TLS path needs
> an Istio sidecar, which this setup doesn't run. Disabling TLS keeps it simple and working.
> Do **not** use this configuration unchanged for production — enable TLS + AUTH there.

---

## The two things people get wrong

| Setting | Must be | Why |
|---|---|---|
| **Cluster mode** | **Disabled** | The cart connects with a plain `host:6379`. Cluster mode on = sharded config endpoint, needs a cluster-aware client. **Not editable after creation** — getting it wrong means delete + recreate. |
| **Encryption in transit** | **Disabled (OFF)** | TLS requires an Istio sidecar, which isn't installed. |

This is why the console's **"Easy create / Demo"** preset does **not** work — it forces *Cluster mode = Enabled* and *Encryption in transit = Enabled*. **Use Standard create instead.**

---

## Step 0 — Find your EKS cluster's VPC, subnets, and node security group

The cache must live in the same VPC as your pods. In AWS CloudShell or your terminal:

```bash
# VPC of your EKS cluster
aws eks describe-cluster --name <your-cluster-name> \
  --query "cluster.resourcesVpcConfig.vpcId" --output text

# Private subnet IDs in that VPC
aws ec2 describe-subnets --filters "Name=vpc-id,Values=<vpc-id>" \
  --query "Subnets[].SubnetId" --output text

# EKS worker node security group
aws eks describe-cluster --name <your-cluster-name> \
  --query "cluster.resourcesVpcConfig.clusterSecurityGroupId" --output text
```

Note down: **VPC id**, **2+ subnet ids**, **node security group id**.

---

## Step 1 — Create a security group for the cache

EC2 → **Security Groups** → **Create security group**:

- **Name:** `boutique-cart-redis-sg`
- **VPC:** your EKS VPC (Step 0)
- **Inbound rule:** Type = **Custom TCP**, Port = **6379**, Source = your **EKS node security group**
- Outbound: leave default (all)

Create.

---

## Step 2 — Create the cache (Standard create)

ElastiCache → **Create cache**:

1. **Engine:** Redis OSS
2. **Deployment option:** **Node-based cluster**
3. **Creation method:** **New cache**
4. ➜ Choose **Standard create** (NOT Easy create)

Then configure:

| Setting | Value |
|---|---|
| **Cluster mode** | **Disabled** ⚠️ |
| **Name** | `boutique-cart-redis` |
| **Engine version** | 7.1 |
| **Node type** | `cache.t4g.micro` (free-tier eligible) |
| **Number of replicas** | `0` |
| **Multi-AZ** | Disabled |
| **Subnet group** | Create new → your **EKS VPC** + subnet ids from Step 0 |
| **Encryption in transit** | **Disabled (OFF)** ⚠️ |
| **Encryption at rest** | leave default (fine) |
| **Security groups** | remove `default`, select **`boutique-cart-redis-sg`** (Step 1) |

Review → **Create**. Wait ~5–7 minutes until status is **available**.

> Prefer infrastructure-as-code? A ready-made Terraform module is in `terraform/elasticache/`
> (`terraform init && terraform apply`, then `terraform output redis_endpoint`).

---

## Step 3 — Copy the endpoint

Open the cache → copy the **Primary endpoint**, e.g.:

```
boutique-cart-redis.xxxxxx.0001.use1.cache.amazonaws.com:6379
```

---

## Step 4 — Point the app at the cache

Edit `helm-chart/values-elasticache.yaml`:

```yaml
cartDatabase:
  type: redis
  connectionString: "boutique-cart-redis.xxxxxx.0001.use1.cache.amazonaws.com:6379"
  inClusterRedis:
    create: false   # stop deploying the in-cluster redis-cart pod
```

---

## Step 5 — Deploy

```bash
helm upgrade -i onlineboutique ./helm-chart \
  -f helm-chart/values.yaml \
  -f helm-chart/values-elasticache.yaml \
  -n boutique-app
```

> [!TIP]
> **GitOps (Argo CD):** commit `values-elasticache.yaml` and reference it from your Kustomize/Argo
> source so Argo CD syncs the change instead of running Helm directly.

---

## Step 6 — Verify

```bash
# the old in-cluster redis pod should be gone:
kubectl get pod -n boutique-app | grep redis        # → no redis-cart pod

# the cart now points at ElastiCache:
kubectl get pod -l app=cartservice -n boutique-app -o yaml | grep -A1 REDIS_ADDR
```

Persistence proof:

1. Open the site and **add items to the cart**.
2. Kill the cart pod:

   ```bash
   kubectl delete pod -l app=cartservice -n boutique-app
   ```

3. Reload the site → **the cart still has your items** (data lives in ElastiCache, not the pod). ✅

*(Optional)* inspect keys directly:

```bash
kubectl run redis-cli --rm -it --image=redis:alpine -n boutique-app -- \
  redis-cli -h <elasticache-endpoint> KEYS '*'
```

---

## Cost & cleanup

- `cache.t4g.micro` is **free-tier eligible** (750 hrs/month for 12 months); otherwise ~$12/month.
- To revert: set `inClusterRedis.create: true` (or drop the override) to go back to the in-cluster
  pod, then delete the cache:

  ```bash
  # console: delete the cache, or with Terraform:
  cd terraform/elasticache && terraform destroy
  ```

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| Cart pod `CrashLoopBackOff` / can't connect | Security group doesn't allow 6379 from EKS nodes | Add inbound 6379 from the node SG (Step 1) |
| Connection times out | Cache in a different VPC than EKS | Recreate the cache/subnet group in the EKS VPC |
| TLS / handshake errors | Encryption in transit left ON | Recreate with in-transit encryption OFF |
| Client errors about MOVED/ASK or cluster | Cluster mode was Enabled | Recreate with **Cluster mode Disabled** |
| Cart empties on cart-pod restart | Override not applied; still using `redis-cart` | Confirm `-f values-elasticache.yaml` was passed and `inClusterRedis.create: false` |
