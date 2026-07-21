# Resource Group Module

## Purpose
Creates an Azure Resource Group as the foundation for all other resources.

## What is a Resource Group?
A Resource Group is a container in Azure that holds all related resources:
- Virtual Networks
- Kubernetes Clusters
- Container Registries
- Databases
- etc.

Think of it like a folder that groups related infrastructure.

## Resources Created
- `azurerm_resource_group`: The main Resource Group

## Inputs
| Variable | Type | Description | Default |
|----------|------|-------------|---------|
| `resource_group_name` | string | Name of RG | Required |
| `location` | string | Azure region | "eastus" |
| `common_tags` | map | Tags for all resources | See variables.tf |

## Outputs
| Output | Description |
|--------|-------------|
| `resource_group_id` | Full ID of Resource Group |
| `resource_group_name` | Name of Resource Group |
| `location` | Azure region used |

## Example Usage (in parent module)
```hcl
module "resource_group" {
  source = "./modules/resource_group"
  
  resource_group_name = "rg-poc-eastus"
  location            = "eastus"
}
```

## Best Practices
1. Use meaningful names (include environment, region)
2. Always tag resources for cost tracking
3. Use the same resource group for all related resources
4. Don't create separate RGs for each service

---

**✅ Module 1 is complete!**

We've created the Resource Group module. This is the foundation for everything else.

**Are you ready for Module 2: Networking?**

Let me know once you've reviewed these files! 🚀