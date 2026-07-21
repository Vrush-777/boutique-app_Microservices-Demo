# ==============================================================================
# Variable: Resource Group Name
# ==============================================================================
# This variable defines what the Resource Group will be called in Azure
#
# Example value: "rg-poc-eastus" or "rg-production-boutique"
# ==============================================================================

variable "resource_group_name" {
  description = "Name of the Azure Resource Group"
  type        = string
  
  # Validation ensures the name follows Azure naming conventions
  validation {
    condition     = length(var.resource_group_name) >= 1 && length(var.resource_group_name) <= 90
    error_message = "Resource group name must be between 1 and 90 characters."
  }
}

# ==============================================================================
# Variable: Azure Location/Region
# ==============================================================================
# This determines which Azure data center region to use
#
# Common values:
#   "eastus"          = US East (Virginia)
#   "westus"          = US West (California)
#   "northeurope"     = Ireland
#   "southeastasia"   = Singapore
#
# Pick a region close to your users for lower latency
# ==============================================================================

variable "location" {
  description = "Azure region where resources will be created"
  type        = string
  default     = "eastus"
}

# ==============================================================================
# Variable: Common Tags
# ==============================================================================
# These are metadata labels applied to ALL resources we create.
# Very useful for:
#   - Organizing resources
#   - Cost allocation and billing
#   - Compliance tracking
#   - Resource management
#
# Example:
#   tags = {
#     "Environment" = "poc"
#     "Project"     = "boutique"
#     "Team"        = "devops"
#   }
# ==============================================================================

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  
  default = {
    "Environment" = "poc"
    "Project"     = "boutique-app"
    "ManagedBy"   = "terraform"
    "CreatedAt"   = "2026"
  }
}

# ==============================================================================
# Explanation of Variables:
# ==============================================================================
# 1. variable "resource_group_name" = Input variable for RG name
#    - description: Explains what this variable does
#    - type: Must be a string
#    - validation: Ensures name is between 1-90 characters (Azure requirement)
#
# 2. variable "location" = Input variable for Azure region
#    - type: String
#    - default: If not provided, uses "eastus"
#
# 3. variable "common_tags" = Input variable for resource tags
#    - type: map(string) means it's a dictionary/object
#    - default: Default tags applied to all resources
#
# These variables will be overridden by the root module (terraform/variables.tf)
# ==============================================================================