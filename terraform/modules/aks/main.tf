resource "azurerm_kubernetes_cluster" "this" {

  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.dns_prefix
  kubernetes_version  = var.kubernetes_version
  sku_tier            = "Free"

  ingress_application_gateway {
    gateway_id = var.application_gateway_id
  }


  default_node_pool {
    name    = "system"
    vm_size = var.vm_size

    upgrade_settings {
      max_surge = "10%"
    }
    vnet_subnet_id       = var.aks_subnet_id
    os_disk_size_gb      = 50
    type                 = "VirtualMachineScaleSets"
    auto_scaling_enabled = true
    min_count            = var.min_count
    max_count            = var.max_count
  }

  identity {
    type = "SystemAssigned"
  }


  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
    outbound_type     = "loadBalancer"
    service_cidr      = "10.100.0.0/16"
    dns_service_ip    = "10.100.0.10"
  }

  role_based_access_control_enabled = true
  oidc_issuer_enabled               = true
  workload_identity_enabled         = true
  tags                              = var.tags

}

resource "azurerm_role_assignment" "acr_pull" {
  scope                = var.acr_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id
}