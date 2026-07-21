# ==============================================================================
# OUTPUT: AKS CLUSTER ID
# ==============================================================================
# Unique identifier for the Kubernetes cluster
# ==============================================================================

output "aks_id" {
  description = "AKS cluster ID"
  value       = azurerm_kubernetes_cluster.aks.id
}

# ==============================================================================
# OUTPUT: AKS CLUSTER NAME
# ==============================================================================
# Name of the Kubernetes cluster
# ==============================================================================

output "aks_name" {
  description = "AKS cluster name"
  value       = azurerm_kubernetes_cluster.aks.name
}

# ==============================================================================
# OUTPUT: KUBERNETES CLUSTER VERSION
# ==============================================================================
# Current version of Kubernetes running
# ==============================================================================

output "kubernetes_version" {
  description = "Kubernetes version"
  value       = azurerm_kubernetes_cluster.aks.kubernetes_version
}

# ==============================================================================
# OUTPUT: FQDN (Fully Qualified Domain Name)
# ==============================================================================
# The domain name to access the Kubernetes API
#
# Example: poc-aks-abc123.eastus.cloudapp.azure.com
#
# Used for:
#   1. kubectl configuration
#   2. API server access
#   3. Documentation
# ==============================================================================

output "fqdn" {
  description = "FQDN of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.fqdn
}

# ==============================================================================
# OUTPUT: KUBE CONFIG
# ==============================================================================
# The Kubernetes configuration file needed to access the cluster with kubectl
#
# WARNING - SENSITIVE DATA:
#   - This is your cluster credentials!
#   - Keep this secret!
#   - Never commit to Git!
#   - Store securely!
#
# How to use:
#   1. terraform output kube_config > kubeconfig.yaml
#   2. kubectl --kubeconfig kubeconfig.yaml get nodes
#
# Or use Azure CLI (recommended):
#   az aks get-credentials --resource-group rg-poc-eastus --name poc-aks-cluster
# ==============================================================================

output "kube_config" {
  description = "Kubernetes kubeconfig"
  value       = azurerm_kubernetes_cluster.aks.kube_config
  sensitive   = true
}

# ==============================================================================
# OUTPUT: KUBE CONFIG RAW (Base64 encoded)
# ==============================================================================
# Raw kubeconfig in base64 format
# ==============================================================================

output "kube_config_raw" {
  description = "Raw kubeconfig (base64 encoded)"
  value       = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive   = true
}

# ==============================================================================
# OUTPUT: AKS IDENTITY PRINCIPAL ID
# ==============================================================================
# VERY IMPORTANT OUTPUT!
#
# This is the managed identity of the AKS cluster
# Other modules (like ACR) use this to grant permissions
#
# Example value:
#   "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
#
# Used for:
#   1. ACR role assignment (to pull images)
#   2. Key Vault access (to read secrets)
#   3. Storage account access
#   4. Custom role assignments
#
# This is what Container Registry module uses!
# ==============================================================================

output "aks_identity_principal_id" {
  description = "Principal ID of AKS managed identity"
  value       = azurerm_kubernetes_cluster.aks.identity[0].principal_id
}

# ==============================================================================
# OUTPUT: AKS IDENTITY CLIENT ID
# ==============================================================================
# Client ID of the managed identity
# Used for some Azure SDK operations
# ==============================================================================

output "aks_identity_client_id" {
  description = "Client ID of AKS managed identity"
  value       = try(azurerm_kubernetes_cluster.aks.identity[0].principal_id, "")
}

# ==============================================================================
# OUTPUT: AKS IDENTITY OBJECT ID
# ==============================================================================
# Object ID of the managed identity
# Used in role assignments
# ==============================================================================

output "aks_identity_object_id" {
  description = "Object ID of AKS managed identity"
  value       = try(azurerm_kubernetes_cluster.aks.identity[0].principal_id, "")
}

# ==============================================================================
# OUTPUT: KUBELET IDENTITY
# ==============================================================================
# Identity used by kubelets on nodes
# This is usually the same as AKS identity
# ==============================================================================

output "kubelet_identity" {
  description = "Kubelet identity configuration"
  value       = try({
    client_id   = azurerm_kubernetes_cluster.aks.kubelet_identity[0].client_id
    object_id   = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
    user_assigned_identity_id = azurerm_kubernetes_cluster.aks.kubelet_identity[0].user_assigned_identity_id
  }, null)
}

# ==============================================================================
# OUTPUT: API SERVER FQDN
# ==============================================================================
# The fully qualified domain name of the Kubernetes API server
# ==============================================================================

output "api_server_fqdn" {
  description = "FQDN of the Kubernetes API server"
  value       = azurerm_kubernetes_cluster.aks.api_server_fqdn
}

# ==============================================================================
# OUTPUT: NODE RESOURCE GROUP
# ==============================================================================
# Azure creates a separate resource group for node resources
# (VMs, load balancers, etc.)
#
# Format: MC_<resource_group>_<cluster_name>_<location>
# Example: MC_rg-poc-eastus_poc-aks-cluster_eastus
#
# This RG is managed by Azure, but you can view resources there
# ==============================================================================

output "node_resource_group" {
  description = "Name of the resource group created for AKS nodes"
  value       = azurerm_kubernetes_cluster.aks.node_resource_group
}

# ==============================================================================
# OUTPUT: SERVICE PRINCIPAL ID (if using Service Principal auth)
# ==============================================================================
# If AKS is using Service Principal instead of Managed Identity
# ==============================================================================

output "service_principal_id" {
  description = "Service Principal ID (if applicable)"
  value       = try(azurerm_kubernetes_cluster.aks.service_principal[0].client_id, null)
}

# ==============================================================================
# OUTPUT: Network Profile
# ==============================================================================
# Network configuration details
# ==============================================================================

output "network_profile" {
  description = "Network profile configuration"
  value       = {
    network_plugin    = azurerm_kubernetes_cluster.aks.network_profile[0].network_plugin
    service_cidr      = azurerm_kubernetes_cluster.aks.network_profile[0].service_cidr
    dns_service_ip    = azurerm_kubernetes_cluster.aks.network_profile[0].dns_service_ip
    docker_bridge_cidr = azurerm_kubernetes_cluster.aks.network_profile[0].docker_bridge_cidr
  }
}

# ==============================================================================
# OUTPUT: CLUSTER ENDPOINTS
# ==============================================================================
# All important endpoints to access and manage the cluster
# ==============================================================================

output "cluster_endpoints" {
  description = "Important cluster endpoints"
  value       = {
    fqdn                = azurerm_kubernetes_cluster.aks.fqdn
    api_server_fqdn     = azurerm_kubernetes_cluster.aks.api_server_fqdn
    node_resource_group = azurerm_kubernetes_cluster.aks.node_resource_group
    location            = azurerm_kubernetes_cluster.aks.location
  }
}

# ==============================================================================
# Summary of Critical Outputs
# ==============================================================================
# For next modules, the most important output is:
#   → aks_identity_principal_id
#     Used by ACR module for pull permissions
#
# For kubectl access:
#   → fqdn or api_server_fqdn
#   → kube_config_raw (to connect)
#
# For documentation:
#   → kubernetes_version
#   → node_resource_group
#   → network_profile
# ==============================================================================