output "redis_primary_address" {
  description = "Primary endpoint hostname of the Redis node."
  value       = aws_elasticache_cluster.cart.cache_nodes[0].address
}

output "redis_endpoint" {
  description = "host:port to paste into helm-chart/values-elasticache.yaml (cartDatabase.connectionString)."
  value       = "${aws_elasticache_cluster.cart.cache_nodes[0].address}:${aws_elasticache_cluster.cart.cache_nodes[0].port}"
}

output "redis_security_group_id" {
  description = "Security group ID attached to the cache."
  value       = aws_security_group.redis.id
}
