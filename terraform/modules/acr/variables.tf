# ==============================================================================
# ENVIRONMENT NAME
# ==============================================================================
# Used in resource naming and tagging
# Example: "poc", "dev", "staging", "prod"
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
# AZURE LOCATION
# ==============================================================================
# Azure region for ACR
# Must match Resource Group and other resources
# ==============================================================================

variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus"
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
# ACR NAME SUFFIX
# ==============================================================================
# Used to create the full ACR name: acr${acr_name_suffix}
#
# Example:
#   acr_name_suffix = "pocboutique"
#   Full ACR name = "acrpocboutique"
#
# Requirements:
#   - 5-50 characters total
#   - Alphanumeric only (a-z, 0-9)
#   - No special characters or hyphens
#   - Must be globally unique across Azure
#
# Naming convention:
#   acr + environment + project name
#   Example: acr + poc + boutique = acrpocboutique
# ==============================================================================

variable "acr_name_suffix" {
  description = "Suffix for ACR name (alphanumeric only, 5-50 chars total)"
  type        = string
  
  validation {
    condition = (
      length("acr${var.acr_name_suffix}") >= 5 &&
      length("acr${var.acr_name_suffix}") <= 50 &&
      can(regex("^[a-z0-9]+$", var.acr_name_suffix))
    )
    error_message = "ACR name suffix must result in 5-50 character alphanumeric name total."
  }
}

# ==============================================================================
# ACR SKU (Pricing Tier)
# ==============================================================================
# Determines capabilities and costs of the Container Registry
#
# Options:
#   "Basic"    = $5/month
#     - 10 GB storage
#     - Basic features
#     - Good for testing
#     - No geo-replication
#
#   "Standard" = $25/month (RECOMMENDED for POC)
#     - 100 GB storage
#     - Better performance
#     - Webhooks supported
#     - Better throughput
#     - No geo-replication
#
#   "Premium"  = $50+/month
#     - 500 GB storage
#     - Geo-replication (multiple regions)
#     - Image retention policies
#     - Premium features
#     - Highest performance
#     - Network security features
#
# For our POC: Standard is perfect
# For production: Premium recommended
# ==============================================================================

variable "sku" {
  description = "SKU of the Container Registry (Basic, Standard, Premium)"
  type        = string
  default     = "Standard"
  
  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku)
    error_message = "SKU must be Basic, Standard, or Premium."
  }
}

# ==============================================================================
# ADMIN ENABLED
# ==============================================================================
# Whether to enable admin account (username/password) access
#
# Options:
#   true  = Admin account enabled
#     - Can login with username/password
#     - Easier for testing and CI/CD
#     - Less secure (credentials need to be stored)
#     - Good for POC
#
#   false = Admin account disabled
#     - Must use Service Principal or managed identity
#     - More secure (roles can be revoked easily)
#     - Better for production
#     - Requires more setup
#
# For POC: true (easier to get started)
# For production: false (use Service Principals)
# ==============================================================================

variable "admin_enabled" {
  description = "Enable admin account for ACR"
  type        = bool
  default     = true
}

# ==============================================================================
# PUBLIC NETWORK ACCESS
# ==============================================================================
# Whether ACR is accessible from the public internet
#
# Options:
#   true  = Public access allowed
#     - Can pull/push from anywhere
#     - Good for CI/CD (GitHub Actions, etc.)
#     - Less secure
#     - Good for POC and public deployments
#
#   false = Private access only
#     - Requires private endpoint or VPN
#     - More secure
#     - Better for production
#     - Requires additional setup
#
# For POC: true (need GitHub Actions to access)
# For production: false (use private endpoints)
# ==============================================================================

variable "public_network_access_enabled" {
  description = "Allow public network access to ACR"
  type        = bool
  default     = true
}

# ==============================================================================
# ZONE REDUNDANCY
# ==============================================================================
# Replicate ACR data across Azure availability zones
#
# Options:
#   true  = Data replicated across zones
#     - Higher availability
#     - More resilient to failures
#     - Slightly higher cost
#     - Only works with Premium SKU
#
#   false = Single zone
#     - Standard setup
#     - Good enough for POC
#     - Lower cost
#
# For POC: false (Standard SKU doesn't support it anyway)
# For production: true (Premium SKU + zone redundancy)
# ==============================================================================

variable "zone_redundancy_enabled" {
  description = "Enable zone redundancy for ACR (requires Premium SKU)"
  type        = bool
  default     = false
}

# ==============================================================================
# AKS IDENTITY PRINCIPAL ID
# ==============================================================================
# This is the identity of the AKS cluster (created in Module 4)
#
# Why do we need this?
#   - AKS needs permission to pull images from ACR
#   - We use Azure's managed identity system
#   - This variable holds the identity ID of the AKS cluster
#
# This will be provided by the AKS module:
#   aks_identity_principal_id = module.aks.aks_identity_principal_id
#
# When should this be provided?
#   - After AKS module is created (Module 4)
#   - In the root main.tf that calls both modules
#
# What if it's not provided?
#   - Terraform will fail with an error
#   - We'll set up the role assignment manually later
# ==============================================================================

variable "aks_identity_principal_id" {
  description = "Principal ID of AKS managed identity (for ACR pull permissions)"
  type        = string
  default     = ""  # Empty by default, set from AKS module
}

# ==============================================================================
# CREATE WEBHOOK
# ==============================================================================
# Whether to create a webhook for image push events
#
# A webhook can:
#   - Notify your system when images are pushed
#   - Trigger automated deployments
#   - Run custom scripts
#   - Integrate with CI/CD
#
# Options:
#   true  = Create webhook (useful for GitOps)
#   false = Skip webhook (simpler setup)
#
# For POC: false initially (we'll add it later with GitOps)
# For production with GitOps: true (enables automated deployments)
# ==============================================================================

variable "create_webhook" {
  description = "Whether to create a webhook for ACR events"
  type        = bool
  default     = false
}

# ==============================================================================
# WEBHOOK SERVICE URI
# ==============================================================================
# URL that ACR will call when an image is pushed
#
# Example values:
#   "https://argocd.example.com/api/webhook"
#   "https://your-webhook-server.com/push-notification"
#   "https://github.com/repos/YOUR-REPO/dispatches"
#
# This URL needs to:
#   1. Be publicly accessible
#   2. Accept HTTP POST requests
#   3. Handle webhook payloads (contains image details)
#   4. Be HTTPS (ACR requires it)
#
# Used for GitOps:
#   1. Image pushed to ACR
#   2. ACR calls webhook
#   3. Webhook triggers ArgoCD
#   4. ArgoCD pulls latest from Git
#   5. ArgoCD deploys to Kubernetes
# ==============================================================================

variable "webhook_service_uri" {
  description = "Service URI for ACR webhook (optional)"
  type        = string
  default     = ""
  
  # Validate it's a valid HTTPS URL if provided
  validation {
    condition = (
      var.webhook_service_uri == "" ||
      can(regex("^https://", var.webhook_service_uri))
    )
    error_message = "Webhook service URI must be HTTPS if provided."
  }
}

# ==============================================================================
# WEBHOOK TOKEN
# ==============================================================================
# Secret token for webhook authentication
#
# Used to verify that webhook requests come from ACR
# (prevents other services from calling your webhook)
#
# Best practices:
#   1. Use a long, random string
#   2. Store in Azure Key Vault (not in code!)
#   3. Rotate periodically
#   4. Use different tokens for different webhooks
#
# Example: "your-super-secret-webhook-token-abc123def456"
#
# In production:
#   variable.tfvars (never committed to Git):
#   webhook_token = "get-from-key-vault-or-environment-variable"
# ==============================================================================

variable "webhook_token" {
  description = "Token for webhook authentication"
  type        = string
  default     = "default-token"
  sensitive   = true  # Hides value from logs
}

# ==============================================================================
# COMMON TAGS
# ==============================================================================
# Tags applied to all resources
# Used for organization, cost tracking, compliance
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
# Explanation of Variable Dependencies
# ==============================================================================
# These variables are provided by other modules:
#
# From Module 1 (Resource Group):
#   - resource_group_name
#   - location
#
# From Module 4 (AKS - not yet created):
#   - aks_identity_principal_id
#
# These are root variables (set by user):
#   - environment
#   - acr_name_suffix
#   - sku
#   - admin_enabled
#   - public_network_access_enabled
#   - create_webhook
#   - webhook_service_uri
#   - webhook_token
#   - common_tags
# ==============================================================================