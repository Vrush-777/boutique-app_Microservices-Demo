output "cluster_name" {

  value = azurerm_kubernetes_cluster.this.name
}

output "cluster_id" {

  value = azurerm_kubernetes_cluster.this.id
}

output "kubelet_identity" {

  value = azurerm_kubernetes_cluster.this.kubelet_identity
}

output "node_resource_group" {

  value = azurerm_kubernetes_cluster.this.node_resource_group
}

output "kube_config" {

  value = azurerm_kubernetes_cluster.this.kube_config_raw

  sensitive = true
}

output "cluster_identity_principal_id" {
  value = azurerm_kubernetes_cluster.this.identity[0].principal_id
}