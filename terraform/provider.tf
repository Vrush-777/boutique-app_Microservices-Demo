# ==============================================================================
# TERRAFORM CONFIGURATION
# ==============================================================================
# Defines which Terraform version and providers we need
# ==============================================================================

terraform {
  # required_version: Which Terraform versions can run this code
  # ">= 1.3.0" means "version 1.3.0 or newer"
  # This ensures consistency across team members
  required_version = ">= 1.3.0"

  # ==============================================================================
  # REQUIRED PROVIDERS
  # ==============================================================================
  # Tells Terraform which providers we use and where to download them from
  # ==============================================================================

  required_providers {
    # ==============================================================================
    # AZURERM PROVIDER
    # ==============================================================================
    # For managing all Azure resources
    # Source: Official HashiCorp provider on registry.terraform.io
    # ==============================================================================
    azurerm = {
      # source: Where to download the provider from
      # "hashicorp/azurerm" = Official HashiCorp Azure provider
      source = "hashicorp/azurerm"

      # version: Which version(s) of the provider to use
      # "~> 3.0" means:
      #   - 3.0 or newer (>= 3.0)
      #   - But less than 4.0 (< 4.0)
      #   - This gives us: 3.0, 3.1, 3.2, 3.85.0, etc.
      #   - But NOT 4.0 (major version change might break things)
      # This balances between getting bug fixes and not breaking changes
      version = "~> 3.0"
    }

    # ==============================================================================
    # KUBERNETES PROVIDER (Optional, for future use with ArgoCD)
    # ==============================================================================
    # We'll use this in Module 6 (GitOps/ArgoCD)
    # Allows Terraform to manage Kubernetes resources
    # ==============================================================================
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }

    # ==============================================================================
    # HELM PROVIDER (Optional, for Helm charts)
    # ==============================================================================
    # We'll use this to install ArgoCD via Helm in Module 6
    # ==============================================================================
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }

  # ==============================================================================
  # BACKEND CONFIGURATION
  # ==============================================================================
  # Where Terraform stores the state file (current infrastructure state)
  #
  # Local backend (current):
  #   terraform.tfstate is stored on your computer
  #   Problem: Not shared with team, can lose state, no backup
  #
  # Remote backend (recommended for team):
  #   State stored on Azure Storage (or other cloud)
  #   Benefits:
  #   - Shared with team
  #   - Backed up automatically
  #   - Supports locking (prevents concurrent modifications)
  #   - Audit trail (who changed what)
  #
  # For POC, we use local backend (simple)
  # For production, use remote backend:
  #
  # cloud {
  #   organization = "your-org"
  #   workspaces {
  #     name = "boutique-poc"
  #   }
  # }
  #
  # OR Azure backend:
  #
  # backend "azurerm" {
  #   resource_group_name  = "rg-terraform-state"
  #   storage_account_name = "tfstateaccount"
  #   container_name       = "tfstate"
  #   key                  = "boutique-poc.tfstate"
  # }
  # ==============================================================================

  # For POC, we use default local backend
  # Comment out above, add backend block if you want remote state
}

# ==============================================================================
# AZURERM PROVIDER CONFIGURATION
# ==============================================================================
# Configures how Terraform connects to Azure
# ==============================================================================

provider "azurerm" {
  # features: Enable/disable Azure-specific features
  # Empty block means use all defaults (recommended)
  features {}

  # subscription_id: Which Azure subscription to use
  # This is passed from variables.tf
  # Gets: var.subscription_id
  subscription_id = var.subscription_id

  # Optional: Authenticate using environment variables
  # az login sets these automatically
  # You can also set explicitly:
  #   client_id       = var.azure_client_id
  #   client_secret   = var.azure_client_secret
  #   tenant_id       = var.azure_tenant_id
  # But az login is simpler for development
  
  # Skip provider registration: Some Azure providers auto-register
  # Set to true to let Azure auto-register required providers
  skip_provider_registration = false
}

# ==============================================================================
# KUBERNETES PROVIDER CONFIGURATION (for ArgoCD in Module 6)
# ======================================