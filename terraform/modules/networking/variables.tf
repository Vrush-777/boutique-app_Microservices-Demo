# ==============================================================================
# ENVIRONMENT NAME
# ==============================================================================
# Used to create unique names for all resources
# Example: "poc", "dev", "staging", "production"
# ==============================================================================

variable "environment" {
  description = "Environment name (poc, dev, staging, prod)"
  type        = string
  
  validation {
    condition     = contains(["poc", "dev", "staging", "prod"], var.environment)
    error_message = "Environment must be: poc, dev, staging, or prod."
  }
}

# ==============================================================================
# AZURE LOCATION
# ==============================================================================
# Azure region where all resources will be created
# Must match the Resource Group location
# ==============================================================================

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus"
  
  validation {
    condition     = can(regex("^[a-z]+$", var.location))
    error_message = "Location must be a valid Azure region name."
  }
}

# ==============================================================================
# RESOURCE GROUP NAME
# ==============================================================================
# Name of the Resource Group created in Module 1
# ==============================================================================

variable "resource_group_name" {
  description = "Name of the Resource Group"
  type        = string
}

# ==============================================================================
# VNET ADDRESS SPACE
# ==============================================================================
# IP range for the entire Virtual Network
# 
# Common sizes:
#   10.0.0.0/16   = 65,536 IPs (recommended for most projects)
#   10.0.0.0/20   = 4,096 IPs (for small projects)
#   10.0.0.0/8    = 16 million IPs (for very large enterprises)
#
# Why 10.x.x.x?
# 10.0.0.0/8 is a private IP range reserved for internal networks
# (cannot be used on public internet)
# ==============================================================================

variable "vnet_address_space" {
  description = "Address space for the Virtual Network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
  
  validation {
    condition     = length(var.vnet_address_space) > 0
    error_message = "VNet address space must not be empty."
  }
}

# ==============================================================================
# PUBLIC SUBNET ADDRESS SPACE
# ==============================================================================
# IP range for the public subnet
# Must be within the VNet address space (10.0.0.0/16)
#
# 10.0.1.0/24 means:
#   - Network: 10.0.1
#   - /24 = 256 IPs total (10.0.1.0 to 10.0.1.255)
#   - Azure reserves 5 IPs, so ~251 usable
# ==============================================================================

variable "public_subnet_address_space" {
  description = "Address space for the public subnet"
  type        = list(string)
  default     = ["10.0.1.0/24"]
  
  validation {
    condition     = length(var.public_subnet_address_space) > 0
    error_message = "Public subnet address space must not be empty."
  }
}

# ==============================================================================
# PRIVATE SUBNET ADDRESS SPACE
# ==============================================================================
# IP range for the private subnet
# Must be within the VNet address space and NOT overlap with public subnet
#
# 10.0.2.0/24 means:
#   - Network: 10.0.2
#   - /24 = 256 IPs total
#   - This is where AKS nodes will get their IPs
# ==============================================================================

variable "private_subnet_address_space" {
  description = "Address space for the private subnet"
  type        = list(string)
  default     = ["10.0.2.0/24"]
  
  validation {
    condition     = length(var.private_subnet_address_space) > 0
    error_message = "Private subnet address space must not be empty."
  }
}

# ==============================================================================
# COMMON TAGS
# ==============================================================================
# Metadata tags applied to all resources
# Used for cost allocation, compliance, and organization
# ==============================================================================

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  
  default = {
    "Environment" = "poc"
    "Project"     = "boutique-app"
    "ManagedBy"   = "terraform"
  }
}

# ==============================================================================
# Explanation of Naming Convention:
# ==============================================================================
# We use this pattern for resource names:
#   ${var.environment}-resource-type
#
# Examples:
#   poc-vnet              = VNet in POC environment
#   poc-public-subnet     = Public subnet in POC
#   poc-private-subnet    = Private subnet in POC
#   poc-public-nsg        = NSG for public subnet
#   poc-nat-gateway       = NAT Gateway in POC
#
# Benefits:
# 1. Clear what each resource is
# 2. Easy to identify which environment
# 3. Automatically organized alphabetically in Azure
# ==============================================================================