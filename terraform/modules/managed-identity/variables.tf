variable "identity_name" {
  description = "Managed Identity Name"
  type        = string
}

variable "resource_group_name" {
  description = "Resource Group Name"
  type        = string
}

variable "location" {
  description = "Azure Region"
  type        = string
}

variable "acr_id" {
  description = "Azure Container Registry ID"
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "resource_group_id" {
  type = string
}

variable "appgw_subnet_id" {
  type = string
}