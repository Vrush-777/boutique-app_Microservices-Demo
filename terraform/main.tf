module "resource_group" {
  # source: Where to find this module
  source = "./modules/resource_group"

  # Inputs to the resource_group module
  # These come from our root variables.tf

  # Generate RG name if not provided
  resource_group_name = (
    var.resource_group_name != "" 
      ? var.resource_group_name 
      : "rg-${var.environment}-${var.location}-boutique"
  )

  location = var.location

  common_tags = var.common_tags

  # Outputs from this module:
  # - module.resource_group.resource_group_id
  # - module.resource_group.resource_group_name
  # - module.resource_group.location
}

# ==============================================================================
# MODULE 2: NETWORKING
# ==============================================================================
# Creates VNet, subnets, NSGs, NAT Gateway, Internet Gateway
# ==============================================================================

module "networking" {
  source = "./modules/networking"

  # Depends on resource group existing first
  # (Terraform automatically handles this, but we make it explicit)
  depends_on = [module.resource_group]

  # Inputs from root variables
  environment = var.environment
  location    = var.location

  # Must be in the same resource group
  resource_group_name = module.resource_group.resource_group_name

  # Network IP ranges
  vnet_address_space           = var.vnet_address_space
  public_subnet_address_space  = var.public_subnet_address_space
  private_subnet_address_space = var.private_subnet_address_space

  common_tags = var.common_tags

  # Outputs from this module:
  # - module.networking.vnet_id
  # - module.networking.public_subnet_id
  # - module.networking.private_subnet_id ← Used by AKS
  # - module.networking.vnet_name ← Used by AKS
  # - module.networking.nat_gateway_ip
  # - module.networking.public_nsg_id
  # - module.networking.private_nsg_id
}

# ==============================================================================
# MODULE 3: CONTAINER REGISTRY
# ==============================================================================
# Creates Azure Container Registry (ACR) for Docker images
# ==============================================================================

module "container_registry" {
  source = "./modules/container_registry"

  # Depends on resource group
  depends_on = [module.resource_group]

  # Inputs
  environment = var.environment
  location    = var.location

  resource_group_name = module.resource_group.resource_group_name

  # ACR naming
  acr_name_suffix = var.acr_name_suffix
  sku             = var.acr_sku

  admin_enabled                = true   # For POC, enable admin access
  public_network_access_enabled = true  # For CI/CD access
  zone_redundancy_enabled      = false  # Not needed for POC

  # Will be set after AKS is created (see below)
  aks_identity_principal_id = ""  # Initially empty, will be set later

  common_tags = var.common_tags

  # Outputs from this module:
  # - module.container_registry.acr_login_server
  # - module.container_registry.acr_name
  # - module.container_registry.admin_username
  # - module.container_registry.admin_password
  # - module.container_registry.acr_id
}

# ==============================================================================
# MODULE 4: AZURE KUBERNETES SERVICE (AKS)
# ==============================================================================
# Creates the Kubernetes cluster where applications run
# ==============================================================================

module "aks" {
  source = "./modules/aks"

  # Depends on all previous modules
  depends_on = [
    module.resource_group,
    module.networking,
    module.container_registry
  ]

  # Basic configuration
  environment     = var.environment
  location        = var.location
  subscription_id = var.subscription_id

  resource_group_name = module.resource_group.resource_group_name

  # Kubernetes configuration
  kubernetes_version = var.kubernetes_version

  # Node pool configuration
  node_count              = var.node_count
  vm_size                 = var.vm_size
  os_disk_size_gb         = 128
  enable_auto_scaling     = var.enable_auto_scaling
  min_node_count          = var.min_node_count
  max_node_count          = var.max_node_count

  # Network configuration - CRITICAL!
  # These come from the networking module
  vnet_subnet_id = module.networking.private_subnet_id  # AKS nodes in private subnet
  vnet_name      = module.networking.vnet_name

  # Kubernetes service and DNS configuration
  service_cidr      = var.service_cidr
  dns_service_ip    = var.dns_service_ip
  docker_bridge_cidr = var.docker_bridge_cidr

  # RBAC and authentication
  enable_rbac                        = var.enable_rbac
  azure_ad_tenant_id                 = var.azure_ad_tenant_id
  admin_group_object_ids             = var.admin_group_object_ids
  api_server_authorized_ip_ranges    = var.api_server_authorized_ip_ranges

  # ACR integration
  acr_name        = module.container_registry.acr_name
  acr_principal_id = ""  # Will be set via local-exec after AKS creation

  # Monitoring
  enable_monitoring = var.enable_monitoring
  enable_azure_monitor_workspace = var.enable_azure_monitor_workspace

  common_tags = var.common_tags

  # Outputs from this module:
  # - module.aks.aks_id
  # - module.aks.aks_name
  # - module.aks.fqdn
  # - module.aks.kube_config_raw ← Your kubectl credentials!
  # - module.aks.aks_identity_principal_id ← For ACR permissions
  # - module.aks.kubernetes_version
  # - module.aks.node_resource_group
}

# ==============================================================================
# LOCAL-EXEC PROVISIONER: Update ACR Role Assignment with AKS Identity
# ==============================================================================
# After AKS is created, we need to update the ACR module with AKS identity
# This allows AKS to pull images from ACR
#
# We can't create the role assignment in ACR module because it needs
# AKS identity, which doesn't exist until AKS module creates it.
#
# Solution: Use local-exec to run Azure CLI after AKS is created
# ==============================================================================

resource "null_resource" "update_acr_aks_permissions" {
  # Only run after AKS is created
  depends_on = [module.aks]

  # Trigger: Run this every time AKS identity changes
  triggers = {
    aks_principal_id = module.aks.aks_identity_principal_id
    acr_id          = module.container_registry.acr_id
  }

  # Local provisioner: Run command on your machine
  provisioner "local-exec" {
    # This Azure CLI command grants AKS permission to pull from ACR
    command = <<-EOT
      # Grant AKS managed identity permission to pull from ACR
      az role assignment create \
        --assignee-object-id "${module.aks.aks_identity_principal_id}" \
        --role "AcrPull" \
        --scope "${module.container_registry.acr_id}" \
        --assignee-principal-type "ServicePrincipal" \
        --query "id" \
        --output table
    EOT

    # Environment variables for Azure CLI
    environment = {
      AZURE_SUBSCRIPTION_ID = var.subscription_id
    }

    # If command fails, don't fail the entire terraform apply
    on_failure = continue
  }
}

# ======================================