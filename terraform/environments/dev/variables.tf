variable "subscription_id" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}
variable "vnet_name" {
  type = string
}

variable "vnet_address_space" {
  type = string
}

variable "aks_subnet_name" {
  type = string
}

variable "aks_subnet_prefix" {
  type = string
}

variable "appgw_subnet_name" {
  type = string
}

variable "appgw_subnet_prefix" {
  type = string
}

variable "acr_name" {
  type = string
}

variable "acr_sku" {
  type    = string
  default = "Basic"
}

variable "acr_admin_enabled" {
  type    = bool
  default = true
}

variable "application_gateway_name" {
  type = string
}

variable "application_gateway_capacity" {
  type    = number
  default = 2
}

variable "cluster_name" {
  type = string
}

variable "dns_prefix" {
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

variable "identity_name" {
  description = "User Assigned Managed Identity Name"
  type        = string
}