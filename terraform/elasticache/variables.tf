variable "region" {
  description = "AWS region to deploy ElastiCache into (same region as the EKS cluster)."
  type        = string
}

variable "name_prefix" {
  description = "Prefix for resource names."
  type        = string
  default     = "boutique"
}

variable "vpc_id" {
  description = "VPC ID of the EKS cluster (the cache must live in the same VPC)."
  type        = string
}

variable "subnet_ids" {
  description = "Private subnet IDs (same VPC as EKS) for the cache subnet group."
  type        = list(string)
}

variable "allowed_security_group_ids" {
  description = "Security group IDs allowed to reach Redis on 6379 (e.g. the EKS node security group)."
  type        = list(string)
  default     = []
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to reach Redis on 6379 (e.g. the VPC CIDR). Optional fallback."
  type        = list(string)
  default     = []
}

variable "node_type" {
  description = "ElastiCache node type. cache.t4g.micro is free-tier eligible."
  type        = string
  default     = "cache.t4g.micro"
}

variable "engine_version" {
  description = "Redis engine version."
  type        = string
  default     = "7.1"
}

variable "parameter_group_name" {
  description = "ElastiCache parameter group (cluster mode disabled)."
  type        = string
  default     = "default.redis7"
}
