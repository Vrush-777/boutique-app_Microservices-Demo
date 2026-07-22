
terraform {
  # required_version: Which Terraform versions can run this code
  # ">= 1.3.0" means "version 1.3.0 or newer"
  # This ensures consistency across team members
  required_version = ">= 1.3.0"

  
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~> 3.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }

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