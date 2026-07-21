variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
  
  # sensitive = true prevents the value from being displayed in logs
  sensitive = true
  
  validation {
    # Validates subscription ID format (UUID)
    condition = can(regex(
      "^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$",
      var.subscription_id
    ))
    error_message = "Subscription ID must be a valid UUID."
  }
}

# ==============================================================================
# ENVIRONMENT NAME
# ==============================================================================
# Determines naming and configuration of all resources
# Examples: "poc", "dev", "staging", "prod"
# ==============================================================================

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "poc"
  
  validation {
    condition = contains(["poc", "dev", "staging", "prod"], var.environment)
    error_message = "Environment must be: poc, dev, staging, or prod."
  }
}

# ==============================================================================
# AZURE LOCATION/REGION
# ==============================================================================
# Which Azure data center region to use
#
# Common locations:
#   "eastus"       = US East (Virginia)
#   "westus"       = US West (California)
#   "northeurope"  = Ireland
#   "westeurope"   = Netherlands
#   "southeastasia" = Singapore
#
# Pick a region close to your users for lower latency
# All resources will be created in this region
# ==============================================================================

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus"
  
  validation {
    condition = can(regex("^[a-z]+$", var.location))
    error_message = "Location must be a valid Azure region name (lowercase)."
  }
}

# ==============================================================================
# RESOURCE GROUP NAMING
# ==============================================================================
# Name of the Resource Group that will contain all resources
# Naming convention: rg-{environment}-{location}-{project}
#
# Example: rg-poc-eastus-boutique
# ==============================================================================

variable "resource_group_name" {
  description = "Name of the Resource Group"
  type        = string
  default     = ""  # If empty, will be generated from other variables
  
  validation {
    condition = (
      var.resource_group_name == "" ||
      (length(var.resource_group_name) >= 1 && length(var.resource_group_name) <= 90)
    )
    error_message = "Resource group name must be empty or 1-90 characters."
  }
}

# ==============================================================================
# KUBERNETES CLUSTER NAMING
# ==============================================================================
# Name for the AKS cluster
# Naming convention: {environment}-aks-cluster
#
# Example: poc-aks-cluster
# ==============================================================================

variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
  default     = ""  # If empty, will be generated
}

# ==============================================================================
# CONTAINER REGISTRY NAMING
# ==============================================================================
# Suffix for ACR name (alphanumeric only)
# Full name: acr{acr_name_suffix}
#
# Example: acrpocboutique
# Requirements:
#   - 5-50 characters total (including "acr" prefix)
#   - Alphanumeric only (no special chars, no hyphens)
#   - Globally unique across Azure
# ==============================================================================

variable "acr_name_suffix" {
  description = "ACR name suffix (alphanumeric)"
  type        = string
  default     = "pocboutique"
  
  validation {
    condition = can(regex("^[a-z0-9]+$", var.acr_name_suffix))
    error_message = "ACR name suffix must be alphanumeric (a-z, 0-9) only."
  }
}

# ==============================================================================
# CONTAINER REGISTRY SKU
# ==============================================================================
# Pricing tier for Azure Container Registry
#
# Options:
#   "Basic"    = $5/month (limited features)
#   "Standard" = $25/month (RECOMMENDED for POC) ← DEFAULT
#   "Premium"  = $50+/month (enterprise features)
# ==============================================================================

variable "acr_sku" {
  description = "SKU for Container Registry"
  type        = string
  default     = "Standard"
  
  validation {
    condition = contains(["Basic", "Standard", "Premium"], var.acr_sku)
    error_message = "ACR SKU must be: Basic, Standard, or Premium."
  }
}

# ==============================================================================
# AKS NODE POOL CONFIGURATION
# ==============================================================================
# Configuration for Kubernetes worker nodes
# ==============================================================================

# Number of initial nodes
variable "node_count" {
  description = "Initial number of AKS nodes"
  type        = number
  default     = 3
  
  validation {
    condition     = var.node_count >= 1 && var.node_count <= 100
    error_message = "Node count must be 1-100."
  }
}

# Azure VM type for nodes
variable "vm_size" {
  description = "Azure VM size for AKS nodes"
  type        = string
  default     = "Standard_B2s"
  
  validation {
    condition = contains([
      "Standard_B2s",
      "Standard_B2ms",
      "Standard_B4ms",
      "Standard_D2s_v3",
      "Standard_D4s_v3",
      "Standard_E2s_v3",
      "Standard_E4s_v3"
    ], var.vm_size)
    error_message = "Invalid VM size."
  }
}

# ==============================================================================
# AKS AUTOSCALING
# ==============================================================================
# Configure automatic scaling of nodes
# ==============================================================================

variable "enable_auto_scaling" {
  description = "Enable autoscaling for AKS nodes"
  type        = bool
  default     = true
}

variable "min_node_count" {
  description = "Minimum number of nodes"
  type        = number
  default     = 2
  
  validation {
    condition     = var.min_node_count >= 1
    error_message = "Min node count must be at least 1."
  }
}

variable "max_node_count" {
  description = "Maximum number of nodes"
  type        = number
  default     = 10
  
  validation {
    condition     = var.max_node_count >= var.min_node_count
    error_message = "Max node count must be >= min node count."
  }
}

# ==============================================================================
# KUBERNETES API SERVER ACCESS
# ==============================================================================
# Control who can access the Kubernetes API
#
# For POC: Leave empty (allow all IPs)
# For production: Restrict to office IP ranges
#
# Example: ["203.0.113.0/24", "203.0.113.5/32"]
# ==============================================================================

variable "api_server_authorized_ip_ranges" {
  description = "IP ranges authorized to access Kubernetes API"
  type        = list(string)
  default     = []
}

# ==============================================================================
# AZURE AD CONFIGURATION
# ==============================================================================
# For cluster admin access via Azure AD

# Your Azure AD tenant ID
variable "azure_ad_tenant_id" {
  description = "Azure AD tenant ID"
  type        = string
  sensitive   = true
}

# Azure AD groups with cluster admin access
# Get group object IDs from: az ad group list --output table
variable "admin_group_object_ids" {
  description = "Azure AD group object IDs with cluster admin access"
  type        = list(string)
  default     = []
}

# ==============================================================================
# MONITORING CONFIGURATION
# ==============================================================================
# Enable Container Insights (Azure Monitor)

variable "enable_monitoring" {
  description = "Enable Container Insights for AKS"
  type        = bool
  default     = false
}

variable "enable_azure_monitor_workspace" {
  description = "Enable Azure Monitor workspace for Prometheus"
  type        = bool
  default     = false
}

# ==============================================================================
# NETWORKING CONFIGURATION
# ==============================================================================
# IP ranges for VNet and subnets

variable "vnet_address_space" {
  description = "Address space for Virtual Network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "public_subnet_address_space" {
  description = "Address space for public subnet"
  type        = list(string)
  default     = ["10.0.1.0/24"]
}

variable "private_subnet_address_space" {
  description = "Address space for private subnet"
  type        = list(string)
  default     = ["10.0.2.0/24"]
}

# Kubernetes service IP range
variable "service_cidr" {
  description = "CIDR range for Kubernetes services"
  type        = string
  default     = "10.100.0.0/16"
}

# DNS service IP (must be within service_cidr)
variable "dns_service_ip" {
  description = "IP address for CoreDNS"
  type        = string
  default     = "10.100.0.10"
}

# Docker bridge CIDR
variable "docker_bridge_cidr" {
  description = "Docker bridge CIDR"
  type        = string
  default     = "172.17.0.1/16"
}

# ==============================================================================
# TAGS
# ==============================================================================
# Resource tags for organization and cost tracking
# Applied to ALL resources created by this Terraform

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  
  default = {
    "Environment" = "poc"
    "Project"     = "boutique-app"
    "ManagedBy"   = "terraform"
    "CreatedAt"   = "2026-07-15"
  }
}

# ==============================================================================
# KUBERNETES VERSION
# ==============================================================================
# Which version of Kubernetes to use
# null = Latest stable (recommended)

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = null
}

# ==============================================================================
# OPTIONAL FEATURES
# ==============================================================================

variable "enable_rbac" {
  description = "Enable RBAC for AKS"
  type        = bool
  default     = true
}

variable "enable_storage_contributor" {
  description = "Enable Storage Contributor role for AKS"
  type        = bool
  default     = true
}