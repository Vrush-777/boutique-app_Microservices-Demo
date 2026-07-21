# ==============================================================================
# Output: Resource Group ID
# ==============================================================================
# After creating the Resource Group, we output its ID.
# This is needed by other modules (networking, AKS, etc.)
#
# The ID is a unique identifier like:
# "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/rg-poc-eastus"
# ==============================================================================

output "resource_group_id" {
  description = "ID of the created Resource Group"
  value       = azurerm_resource_group.rg.id
}

# ==============================================================================
# Output: Resource Group Name
# ==============================================================================
# We output the actual name for reference in other modules
# This is useful if you need to reference the RG name in other Terraform code
# ==============================================================================

output "resource_group_name" {
  description = "Name of the created Resource Group"
  value       = azurerm_resource_group.rg.name
}

# ==============================================================================
# Output: Azure Location
# ==============================================================================
# We output the location used, so other modules know which region to use
# This ensures all resources are created in the same region
# ==============================================================================

output "location" {
  description = "Azure location where resources are created"
  value       = azurerm_resource_group.rg.location
}

# ==============================================================================
# Explanation of Outputs:
# ==============================================================================
# Outputs are values we extract from the resources we created.
#
# Why do we need outputs?
# 1. Other modules need these values to reference the RG
# 2. We display them after terraform apply for user information
# 3. They can be used in bash scripts or other tools
#
# Example: After running terraform apply, you'll see:
#   resource_group_id = /subscriptions/xxx/resourceGroups/rg-poc-eastus
#   resource_group_name = rg-poc-eastus
#   location = eastus
#
# Then the networking module uses: resource_group_name = output.resource_group_name
# ==============================================================================