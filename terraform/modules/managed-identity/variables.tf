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

variable "tags" {
  type    = map(string)
  default = {}
}