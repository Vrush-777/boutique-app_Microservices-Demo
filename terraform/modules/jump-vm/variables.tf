variable "vm_name" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "admin_username" {
  type = string
}

variable "public_key" {
  type      = string
  sensitive = true
}

variable "acr_id" {
  type = string
}

variable "admin_source_ip" {
  type = string
}

variable "vm_size" {
  type    = string
  default = "Standard_D2s_v3"
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "subscription_id" {
  type = string
}

variable "aks_name" {
  type = string
}