module "resource_group" {

  source = "../../modules/resource-group"

  resource_group_name = var.resource_group_name
  location            = var.location

  tags = {
    Environment = "dev"
    Project     = "online-boutique"
    ManagedBy   = "Terraform"
  }
}

module "network" {

  source = "../../modules/network"

  resource_group_name = module.resource_group.resource_group_name
  location            = module.resource_group.location

  vnet_name          = var.vnet_name
  vnet_address_space = var.vnet_address_space

  aks_subnet_name   = var.aks_subnet_name
  aks_subnet_prefix = var.aks_subnet_prefix

  appgw_subnet_name   = var.appgw_subnet_name
  appgw_subnet_prefix = var.appgw_subnet_prefix

  tags = {
    Environment = "dev"
    Project     = "online-boutique"
    ManagedBy   = "Terraform"
  }
}

module "acr" {

  source = "../../modules/acr"

  acr_name            = var.acr_name
  resource_group_name = module.resource_group.resource_group_name
  location            = module.resource_group.location

  sku           = var.acr_sku
  admin_enabled = var.acr_admin_enabled

  tags = {
    Environment = "dev"
    Project     = "online-boutique"
    ManagedBy   = "Terraform"
  }
}

# module "managed_identity" {

#   source = "../../modules/managed-identity"

#   identity_name = var.identity_name

#   resource_group_name = module.resource_group.resource_group_name

#   location = module.resource_group.location


#   acr_id = module.acr.acr_id


#   resource_group_id = module.resource_group.resource_group_id


#   appgw_subnet_id = module.network.appgw_subnet_id


#   tags = {
#     Environment = "dev"
#     Project     = "online-boutique"
#     ManagedBy   = "Terraform"
#   }
# }

module "application_gateway" {

  source = "../../modules/application-gateway"

  application_gateway_name = var.application_gateway_name

  resource_group_name = module.resource_group.resource_group_name
  location            = module.resource_group.location

  subnet_id = module.network.appgw_subnet_id

  capacity = var.application_gateway_capacity

  tags = {
    Environment = "dev"
    Project     = "online-boutique"
    ManagedBy   = "Terraform"
  }
}


module "aks" {

  source = "../../modules/aks"

  cluster_name = var.cluster_name

  dns_prefix = var.dns_prefix

  resource_group_name = module.resource_group.resource_group_name

  location = module.resource_group.location

  kubernetes_version = var.kubernetes_version

  vm_size = var.vm_size

  node_count = var.node_count

  min_count = var.min_count

  max_count = var.max_count

  aks_subnet_id = module.network.aks_subnet_id

  acr_id = module.acr.acr_id

  application_gateway_id = module.application_gateway.application_gateway_id

  depends_on = [
    module.application_gateway
  ]

  tags = {
    Environment = "dev"
    Project     = "online-boutique"
    ManagedBy   = "Terraform"
  }
}