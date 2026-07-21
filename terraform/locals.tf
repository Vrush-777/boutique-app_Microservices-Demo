# ==============================================================================
# LOCAL VALUES
# ==============================================================================
# These are computed values used throughout Terraform
# They're not input variables, they're derived values
# ==============================================================================

locals {
  # ==============================================================================
  # RESOURCE NAMING LOCALS
  # ==============================================================================
  # Centralized naming for consistency
  # ==============================================================================

  # Generate resource group name if not provided
  resource_group_name = (
    var.resource_group_name != "" 
      ? var.resource_group_name 
      : "rg-${var.environment}-${var.location}-boutique"
  )

  # Generate cluster name if not provided
  cluster_name = (
    var.cluster_name != "" 
      ? var.cluster_name 
      : "${var.environment}-aks-cluster"
  )

  # ==============================================================================
  # ACR NAMING LOCALS
  # ==============================================================================
  # Create full ACR name from suffix
  acr_name = "acr${var.acr_name_suffix}"

  # ==============================================================================
  # COMMON NAMING PATTERN
  # ==============================================================================
  # Pattern for all resources: {environment}-{resource-type}
  name_prefix = "${var.environment}-"

  # ==============================================================================
  # TAGS LOCALS
  # ==============================================================================
  # Enhanced tags with additional metadata
  tags = merge(
    var.common_tags,
    {
      "CreatedBy"   = "Terraform"
      "Environment" = var.environment
      "Location"    = var.location
      "Timestamp"   = timestamp()
    }
  )

  # ==============================================================================
  # NETWORK LOCALS
  # ==============================================================================
  # Network configuration derived from variables
  
  vnet_address_space            = var.vnet_address_space[0]
  public_subnet_address_space   = var.public_subnet_address_space[0]
  private_subnet_address_space  = var.private_subnet_address_space[0]

  # ==============================================================================
  # KUBERNETES LOCALS
  # ==============================================================================
  
  # Full Kubernetes service CIDR
  kubernetes_service_cidr = var.service_cidr
  
  # Full Docker bridge CIDR
  kubernetes_docker_bridge_cidr = var.docker_bridge_cidr

  # ==============================================================================
  # MONITORING LOCALS
  # ==============================================================================
  
  # Enable monitoring if flag is set
  enable_container_insights = var.enable_monitoring ? "true" : "false"

  # ==============================================================================
  # EXAMPLE: Using locals in modules
  # ==============================================================================
  # Instead of: resource_group_name = "rg-${var.environment}-eastus-boutique"
  # We can use: resource_group_name = local.resource_group_name
  # 
  # Benefits:
  # 1. Centralized - change once, everywhere updates
  # 2. Consistent - same naming across all resources
  # 3. Maintainable - easier to update naming schemes
  # ==============================================================================
}

# ==============================================================================
# HOW LOCALS ARE USED
# ==============================================================================
# In main.tf, we reference locals like:
#
#   resource_group_name = local.resource_group_name
#   
# Or combine with other values:
#
#   tags = local.tags
#
# This is much cleaner than repeating calculations everywhere!
# ==============================================================================