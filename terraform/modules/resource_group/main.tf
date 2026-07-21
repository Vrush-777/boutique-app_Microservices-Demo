# ==============================================================================
# Azure Resource Group
# ==============================================================================
# A Resource Group is a container that holds related resources.
# Think of it like a folder for all Azure resources.
#
# Everything we create (VNet, AKS, ACR, etc.) will be in this group.
# ==============================================================================

resource "azurerm_resource_group" "rg" {
  # name: Unique name for the resource group
  # We're using variables so it's reusable
  name = var.resource_group_name

  # location: Azure region where resources will be created
  # Examples: "eastus", "westus", "northeurope", "southeastasia"
  location = var.location

  # tags: Labels/metadata for organizing and billing purposes
  # Optional but very useful for cost tracking
  tags = merge(
    var.common_tags,
    {
      "Module" = "resource_group"
    }
  )
}

# ==============================================================================
# Explanation:
# ==============================================================================
# 1. resource "azurerm_resource_group" = Tells Terraform to create an Azure resource group
# 2. "rg" = Local reference name (used in this project)
# 3. name = Will be set in variables.tf
# 4. location = Will be set in variables.tf
# 5. tags = Metadata tags for organization and cost tracking
# 6. merge() = Combines common_tags from variables with module-specific tags
#
# After running terraform apply, this creates a new Resource Group in Azure
# ==============================================================================