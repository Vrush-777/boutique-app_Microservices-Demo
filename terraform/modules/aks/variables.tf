# ==============================================================================
# ENVIRONMENT NAME
# ==============================================================================

variable "environment" {
  description = "Environment name"
  type        = string
  
  validation {
    condition     = contains(["poc", "dev", "staging", "prod"], var.environment)
    error_message = "Environment must be: poc, dev, staging, or prod."
  }
}

# ==============================================================================
# AZURE SUBSCRIPTION ID
# ==============================================================================
# Your Azure subscription ID
# Get it with: az account show --query id --output tsv
# ==============================================================================

variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

# ==============================================================================
# AZURE LOCATION
# ==============================================================================

variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus"
}

# ==============================================================================
# RESOURCE GROUP NAME
# ==============================================================================
# From Module 1

variable "resource_group_name" {
  description = "Name of the Resource Group"
  type        = string
}

# ==============================================================================
# KUBERNETES VERSION
# ==============================================================================
# Which version of Kubernetes to use
#
# Options:
#   null = Latest stable version (recommended, Azure manages updates)
#   "1.27.0" = Specific version
#   "1.27" = Latest 1.27.x version
#
# For POC: Use null (let Azure choose latest)
# For production: Pin specific version for stability
# ==============================================================================

variable "kubernetes_version" {
  description = "Kubernetes version to use"
  type        = string
  default     = null
}

# ==============================================================================
# NODE POOL CONFIGURATION
# ==============================================================================

# Initial number of nodes
# If autoscaling enabled, this is overridden by min_count
variable "node_count" {
  description = "Initial number of nodes"
  type        = number
  default     = 3
  
  validation {
    condition     = var.node_count >= 1 && var.node_count <= 100
    error_message = "Node count must be between 1 and 100."
  }
}

# Azure VM size for nodes
# See: https://docs.microsoft.com/en-us/azure/virtual-machines/sizes-general
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
    error_message = "VM size must be a valid Azure VM type."
  }
}

# OS disk size per node
variable "os_disk_size_gb" {
  description = "OS disk size per node in GB"
  type        = number
  default     = 128
  
  validation {
    condition     = var.os_disk_size_gb >= 30 && var.os_disk_size_gb <= 1023
    error_message = "OS disk size must be between 30 and 1023 GB."
  }
}

# ==============================================================================
# AUTOSCALING CONFIGURATION
# ==============================================================================

variable "enable_auto_scaling" {
  description = "Enable autoscaling for node pool"
  type        = bool
  default     = true
}

variable "min_node_count" {
  description = "Minimum number of nodes (if autoscaling enabled)"
  type        = number
  default     = 2
}

variable "max_node_count" {
  description = "Maximum number of nodes (if autoscaling enabled)"
  type        = number
  default     = 10
}

# ==============================================================================
# NETWORK CONFIGURATION
# ==============================================================================

# Subnet where AKS nodes will be deployed
# This is the PRIVATE subnet from Module 2
variable "vnet_subnet_id" {
  description = "Subnet ID for AKS nodes"
  type        = string
}

# VNet name (for role assignment)
variable "vnet_name" {
  description = "Virtual Network name"
  type        = string
}

# Service CIDR - IP range for Kubernetes services
# Must not overlap with node subnet
variable "service_cidr" {
  description = "CIDR range for Kubernetes services"
  type        = string
  default     = "10.100.0.0/16"
  
  validation {
    condition = can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}/[0-9]{1,2}$", var.service_cidr))
    error_message = "Service CIDR must be a valid CIDR notation (e.g., 10.100.0.0/16)."
  }
}

# DNS service IP (must be within service_cidr)
variable "dns_service_ip" {
  description = "IP address for CoreDNS service"
  type        = string
  default     = "10.100.0.10"
  
  validation {
    condition = can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}$", var.dns_service_ip))
    error_message = "DNS service IP must be a valid IP address."
  }
}

# Docker bridge CIDR
variable "docker_bridge_cidr" {
  description = "Docker bridge CIDR"
  type        = string
  default     = "172.17.0.1/16"
}

# ==============================================================================
# RBAC CONFIGURATION
# ==============================================================================

variable "enable_rbac" {
  description = "Enable RBAC"
  type        = bool
  default     = true
}

# Azure AD tenant ID
variable "azure_ad_tenant_id" {
  description = "Azure AD tenant ID for cluster admin access"
  type        = string
}

# Azure AD groups with cluster admin access
# Example: ["00000000-0000-0000-0000-000000000000"]
variable "admin_group_object_ids" {
  description = "Azure AD group object IDs with cluster admin access"
  type        = list(string)
  default     = []
}

# ==============================================================================
# API SERVER CONFIGURATION
# ==============================================================================

# Authorized IP ranges for API server access
# Leave empty for public access (POC)
# Restrict to specific IPs for production
variable "api_server_authorized_ip_ranges" {
  description = "Authorized IP ranges for Kubernetes API server"
  type        = list(string)
  default     = []
}

# ==============================================================================
# MONITORING CONFIGURATION
# ==============================================================================

variable "enable_monitoring" {
  description = "Enable Container Insights monitoring"
  type        = bool
  default     = false
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for monitoring"
  type        = string
  default     = ""
}

variable "enable_azure_monitor_workspace" {
  description = "Enable Azure Monitor workspace for Prometheus metrics"
  type        = bool
  default     = false
}

# ==============================================================================
# ACR INTEGRATION
# ==============================================================================

variable "acr_name" {
  description = "Container Registry name"
  type        = string
}

variable "acr_principal_id" {
  description = "Principal ID of Container Registry"
  type        = string
  default     = ""
}

# ==============================================================================
# STORAGE CONFIGURATION
# ==============================================================================

variable "enable_storage_contributor" {
  description = "Enable Storage Account Contributor role for AKS"
  type        = bool
  default     = true
}

variable "enable_managed_identity_operator" {
  description = "Enable Managed Identity Operator role for AKS"
  type        = bool
  default     = false
}

# ==============================================================================
# COMMON TAGS
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
# VM SIZE EXPLANATION
# ==============================================================================
# 
# For POC (Recommended: Standard_B2s or B2ms):
#   Standard_B2s = 2 vCPU, 4GB RAM - Burstable (good for testing)
#   Standard_B2ms = 2 vCPU, 8GB RAM - Burstable with more RAM
#
# For Small Production (Standard_D2s_v3 or D4s_v3):
#   Standard_D2s_v3 = 2 vCPU, 8GB RAM - Consistent performance
#   Standard_D4s_v3 = 4 vCPU, 16GB RAM - Better for microservices
#
# For Large Production (E-series):
#   Standard_E2s_v3 = 2 vCPU, 16GB RAM - Memory optimized
#   Standard_E4s_v3 = 4 vCPU, 32GB RAM - More memory for databases
#
# Pricing (approximately, eastus region, per month):
#   Standard_B2s = $60 + compute
#   Standard_D2s_v3 = $90 + compute
#   Standard_D4s_v3 = $180 + compute
#   Standard_E4s_v3 = $250 + compute
#
# For 3 nodes (minimum for HA):
#   3x Standard_B2s = ~$180/month (POC)
#   3x Standard_D2s_v3 = ~$270/month (Small prod)
#   3x Standard_D4s_v3 = ~$540/month (Medium prod)
# ==============================================================================

# ==============================================================================
# IMPORTANT DESIGN DECISIONS
# ==============================================================================
# 
# 1. Private Subnet
#    - Nodes are NOT directly accessible from internet
#    - More secure
#    - Traffic goes through Load Balancer
#
# 2. System-Assigned Identity
#    - Azure automatically manages the identity
#    - Simpler than User-Assigned
#    - Good enough for POC
#
# 3. Azure CNI Network Plugin
#    - Integrates with Azure VNet
#    - Better than kubenet
#    - Pods get real VNet IPs
#
# 4. Autoscaling Enabled by Default
#    - min_count = 2 (always keep 2 nodes for HA)
#    - max_count = 10 (prevent runaway costs)
#    - Auto-scales based on pod resource requests
#
# 5. Azure AD Integration
#    - Cluster admins authenticate via Azure AD
#    - No separate user management
#    - Enterprise-grade authentication
#
# ==============================================================================