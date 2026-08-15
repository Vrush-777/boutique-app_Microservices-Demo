subscription_id     = "96f9f983-8879-4a68-b98c-fa5a165f137b"
resource_group_name = "rg-devsecops-poc"

location = "Central India"

vnet_name = "vnet-boutique-dev"

vnet_address_space = "10.1.0.0/16"

aks_subnet_name   = "aks-subnet"
aks_subnet_prefix = "10.1.1.0/24"

appgw_subnet_name   = "appgw-subnet"
appgw_subnet_prefix = "10.1.2.0/24"

jump_subnet_name   = "jump-subnet"
jump_subnet_prefix = "10.1.3.0/24"


acr_name = "vrushacr777"

acr_sku = "Basic"

acr_admin_enabled = true

# identity_name = "aks-managed-identity"

application_gateway_name = "appgw-boutique-dev"

application_gateway_capacity = 2

cluster_name = "aks-boutique-dev"

dns_prefix = "aksboutique"

kubernetes_version = "1.35.6"

vm_size = "Standard_D2s_v3"

node_count = 2

min_count = 2

max_count = 5