variable "cluster_name" {
  type = string
}

variable "dns_prefix" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "kubernetes_version" {
  type = string
}

variable "vm_size" {
  type = string
}

variable "node_count" {
  type = number
}

variable "min_count" {
  type = number
}

variable "max_count" {
  type = number
}

variable "aks_subnet_id" {
  type = string
}

variable "acr_id" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "application_gateway_id" {
  type = string
}