# Cart Persistence with Azure Cache for Redis — Setup Guide

This guide replaces the boutique cart's **in-cluster Redis pod** (`redis-cart`, ephemeral
`emptyDir` storage) with a **managed Azure Cache for Redis** instance, so cart data survives pod and
node restarts. Use this when the app runs on **Azure AKS**.

> [!IMPORTANT]
> The boutique app is deployed on **Azure (AKS)**. AWS ElastiCache cannot be reached from Azure pods,
> so we use **Azure Cache for Redis** here. (The AWS ElastiCache files in this repo —
> `terraform/elasticache/`, `helm-chart/values-elasticache.yaml`, `docs/elasticache-setup.md` — are
> a reference for an AWS/EKS deployment only.)

> [!NOTE]
> No application code changes are needed. The cart sets `options.Configuration = REDIS_ADDR`
> ([src/cartservice/src/Startup.cs](../src/cartservice/src/Startup.cs)), which is a full
> **StackExchange.Redis configuration string**. Azure Cache for Redis requires TLS + an access key,
> and we pass both inline in the connection string. StackExchange.Redis performs TLS itself, so
> **no Istio sidecar is required**.

---

## Step 1 — Create the cache (Azure Portal)

**Create a resource → Azure Cache for Redis**:

| Field | Value |
|---|---|
| **Resource group** | same as your AKS cluster |
| **DNS name** | `boutique-cart-redis` |
| **Region** | same region as your AKS cluster |
| **Cache SKU** | **Basic** |
| **Cache size** | **C0 (250 MB)** — cheapest, fine for a demo |
| **Advanced → TLS** | leave **enabled** (port 6380); the non-TLS port is **not** needed |

Review + create → wait ~10–15 minutes until status is **Running**.

> CLI alternative:
> ```bash
> az redis create \
>   --name boutique-cart-redis \
>   --resource-group <your-rg> \
>   --location <your-region> \
>   --sku Basic --vm-size c0
> ```

---

## Step 2 — Get the host name and access key

Open the cache resource:

- **Host name** (Overview): `boutique-cart-redis.redis.cache.windows.net`
- **Primary access key** (Settings → **Authentication** / **Access keys**)

> CLI alternative:
> ```bash
> az redis show       --name boutique-cart-redis --resource-group <rg> --query hostName -o tsv
> az redis list-keys  --name boutique-cart-redis --resource-group <rg> --query primaryKey -o tsv
> ```

---

## Step 3 — Build the connection string

```
boutique-cart-redis.redis.cache.windows.net:6380,password=<PRIMARY_ACCESS_KEY>,ssl=True,abortConnect=False
```

- `:6380` — the TLS port
- `ssl=True` — Azure Cache for Redis requires TLS
- `password=<key>` — the primary access key
- `abortConnect=False` — keep retrying if Redis is briefly unavailable at startup

---

## Step 4 — Point the app at the cache

Edit `helm-chart/values-azure-redis.yaml` and paste your host + key into `connectionString`:

```yaml
cartDatabase:
  type: redis
  connectionString: "boutique-cart-redis.redis.cache.windows.net:6380,password=<PRIMARY_ACCESS_KEY>,ssl=True,abortConnect=False"
  inClusterRedis:
    create: false   # stop deploying the in-cluster redis-cart pod
```

> [!WARNING]
> The access key is a secret. Inline is acceptable for a demo/college handover. For production, store
> it in a Kubernetes Secret and reference it instead of hardcoding it in the values file.

---

## Step 5 — Deploy

```bash
helm upgrade -i onlineboutique ./helm-chart \
  -f helm-chart/values.yaml \
  -f helm-chart/values-azure-redis.yaml \
  -n boutique-app
```

---

## Step 6 — Verify

```bash
# the old in-cluster redis pod should be gone:
kubectl get pod -n boutique-app | grep redis        # → no redis-cart pod

# the cart now points at Azure Cache for Redis:
kubectl get pod -l app=cartservice -n boutique-app -o yaml | grep -A1 REDIS_ADDR
```

Persistence proof:

1. Open the site and **add items to the cart**.
2. Kill the cart pod:

   ```bash
   kubectl delete pod -l app=cartservice -n boutique-app
   ```

3. Reload the site → **the cart still has your items** (data lives in Azure Cache for Redis, not the
   pod). ✅

---

## Cost & cleanup

- Azure Cache for Redis has **no free tier**. Basic **C0** ≈ **$16/month**. Delete it when finished:

  ```bash
  az redis delete --name boutique-cart-redis --resource-group <rg> --yes
  ```

- To revert the app to the in-cluster pod: drop the `-f values-azure-redis.yaml` override (or set
  `inClusterRedis.create: true`).

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| Cart can't connect / timeouts | Missing `ssl=True` or wrong port | Use port **6380** and `ssl=True` in the connection string |
| Auth errors (`NOAUTH` / `WRONGPASS`) | Wrong or missing access key | Re-copy the **primary access key**; ensure `password=<key>` is set |
| Cart empties on cart-pod restart | Override not applied; still using `redis-cart` | Confirm `-f values-azure-redis.yaml` was passed and `inClusterRedis.create: false` |
| Slow first connection / startup blips | Cache still warming up | `abortConnect=False` handles this; give it a moment |
