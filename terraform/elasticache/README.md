# ElastiCache (Redis) for the Cart Service

Provisions a single-node **Amazon ElastiCache (Redis)** so the boutique cart has durable storage
instead of the ephemeral in-cluster `redis-cart` pod.

> The cache **must** be created in the **same VPC** as your EKS cluster, otherwise the cart pods
> cannot reach it.

## Usage

```bash
cd terraform/elasticache
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars: set region, vpc_id, subnet_ids, and the EKS node security group id

terraform init
terraform plan
terraform apply
```

## Output

After apply, grab the endpoint to paste into `helm-chart/values-elasticache.yaml`:

```bash
terraform output redis_endpoint
# e.g. boutique-cart-redis.xxxx.0001.use1.cache.amazonaws.com:6379
```

## Notes

- Uses `cache.t4g.micro` (free-tier eligible) and **no in-transit encryption** so the cart connects
  over plain TCP without an Istio sidecar. This is intentional for a demo — do not use as-is for
  production without enabling TLS/AUTH.
- Single node, no replica. Fine for a demo; add replicas / Multi-AZ for production.

## Cleanup

```bash
terraform destroy
```
