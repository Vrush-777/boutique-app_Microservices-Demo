terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# Subnet group: the cache lives in the same VPC/subnets as the EKS cluster so
# the cart pods can reach it on the private network.
resource "aws_elasticache_subnet_group" "cart" {
  name       = "${var.name_prefix}-cart-redis"
  subnet_ids = var.subnet_ids
}

# Security group: allow Redis (6379) only from the EKS workers (by SG and/or CIDR).
resource "aws_security_group" "redis" {
  name        = "${var.name_prefix}-cart-redis-sg"
  description = "Allow Redis 6379 from EKS workloads"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = length(var.allowed_security_group_ids) > 0 ? [1] : []
    content {
      description     = "Redis from EKS node security group(s)"
      from_port       = 6379
      to_port         = 6379
      protocol        = "tcp"
      security_groups = var.allowed_security_group_ids
    }
  }

  dynamic "ingress" {
    for_each = length(var.allowed_cidr_blocks) > 0 ? [1] : []
    content {
      description = "Redis from allowed CIDR blocks"
      from_port   = 6379
      to_port     = 6379
      protocol    = "tcp"
      cidr_blocks = var.allowed_cidr_blocks
    }
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name_prefix}-cart-redis-sg"
  }
}

# Single-node Redis (cluster mode disabled).
# NOTE: single-node ElastiCache defaults to NO in-transit encryption, so the cart
# connects over plain TCP (host:6379) without needing Istio/TLS. Keep it that way
# for this demo.
resource "aws_elasticache_cluster" "cart" {
  cluster_id           = "${var.name_prefix}-cart-redis"
  engine               = "redis"
  engine_version       = var.engine_version
  node_type            = var.node_type
  num_cache_nodes      = 1
  port                 = 6379
  parameter_group_name = var.parameter_group_name
  subnet_group_name    = aws_elasticache_subnet_group.cart.name
  security_group_ids   = [aws_security_group.redis.id]

  tags = {
    Name = "${var.name_prefix}-cart-redis"
  }
}
