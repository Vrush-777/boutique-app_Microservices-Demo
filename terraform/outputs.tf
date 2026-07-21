output "resource_group_name" {
  description = "Name of the Resource Group"
  value       = module.resource_group.resource_group_name
}

output "resource_group_id" {
  description = "ID of the Resource Group"
  value       = module.resource_group.resource_group_id
}

# ==============================================================================
# NETWORKING OUTPUTS
# ==============================================================================

output "vnet_id" {
  description = "Virtual Network ID"
  value       = module.networking.vnet_id
}

output "vnet_name" {
  description = "Virtual Network name"
  value       = module.networking.vnet_name
}

output "vnet_address_space" {
  description = "VNet address space"
  value       = module.networking.vnet_address_space
}

output "public_subnet_id" {
  description = "Public subnet ID (for Load Balancer)"
  value       = module.networking.public_subnet_id
}

output "private_subnet_id" {
  description = "Private subnet ID (for AKS nodes)"
  value       = module.networking.private_subnet_id
}

output "nat_gateway_ip" {
  description = "NAT Gateway public IP"
  value       = module.networking.nat_gateway_ip
}

# ==============================================================================
# CONTAINER REGISTRY OUTPUTS
# ==============================================================================

output "acr_name" {
  description = "Container Registry name"
  value       = module.container_registry.acr_name
}

output "acr_login_server" {
  description = "Container Registry login server"
  value       = module.container_registry.acr_login_server
  
  # Useful for:
  # docker login acrpocboutique.azurecr.io
  # docker tag myimage:latest acrpocboutique.azurecr.io/myimage:latest
  # docker push acrpocboutique.azurecr.io/myimage:latest
}

output "acr_admin_username" {
  description = "ACR admin username"
  value       = module.container_registry.admin_username
}

output "acr_admin_password" {
  description = "ACR admin password (SENSITIVE)"
  value       = module.container_registry.admin_password
  sensitive   = true
  
  # To view: terraform output acr_admin_password
}

output "acr_id" {
  description = "ACR resource ID"
  value       = module.container_registry.acr_id
}

# ==============================================================================
# KUBERNETES CLUSTER OUTPUTS
# ==============================================================================

output "aks_cluster_name" {
  description = "AKS cluster name"
  value       = module.aks.aks_name
}

output "aks_cluster_id" {
  description = "AKS cluster ID"
  value       = module.aks.aks_id
}

output "aks_fqdn" {
  description = "AKS cluster FQDN"
  value       = module.aks.fqdn
  
  # Used for kubectl configuration
}

output "aks_api_server_fqdn" {
  description = "Kubernetes API server FQDN"
  value       = module.aks.api_server_fqdn
}

output "kubernetes_version" {
  description = "Kubernetes version"
  value       = module.aks.kubernetes_version
}

output "aks_node_resource_group" {
  description = "Resource group containing AKS node resources"
  value       = module.aks.node_resource_group
  
  # Example: MC_rg-poc-eastus_poc-aks-cluster_eastus
  # This is auto-created by Azure for node VMs, disks, etc.
}

# ==============================================================================
# KUBECONFIG OUTPUT
# ==============================================================================

output "kube_config_raw" {
  description = "Kubernetes configuration (raw, base64)"
  value       = module.aks.kube_config_raw
  sensitive   = true
  
  # To use:
  # terraform output -raw kube_config_raw > kubeconfig.yaml
  # kubectl --kubeconfig kubeconfig.yaml get nodes
}

# ==============================================================================
# AKS IDENTITY OUTPUT
# ==============================================================================

output "aks_identity_principal_id" {
  description = "AKS managed identity principal ID"
  value       = module.aks.aks_identity_principal_id
  
  # This is used for role assignments
  # Example: granting ACR pull permissions
}

# ==============================================================================
# CLUSTER CONNECTION SUMMARY
# ==============================================================================

output "cluster_connection_commands" {
  description = "Commands to connect to the cluster"
  value       = <<-EOT
    
    ========== CLUSTER CONNECTION GUIDE ==========
    
    Option 1: Using Azure CLI (Recommended)
      az aks get-credentials \
        --resource-group ${module.resource_group.resource_group_name} \
        --name ${module.aks.aks_name}
      
      kubectl get nodes
    
    Option 2: Using exported kubeconfig
      terraform output -raw kube_config_raw > kubeconfig.yaml
      kubectl --kubeconfig kubeconfig.yaml get nodes
    
    Option 3: View FQDN
      Cluster FQDN: ${module.aks.fqdn}
      API Server: ${module.aks.api_server_fqdn}
    
    =============================================
  EOT
}

# ==============================================================================
# CONTAINER REGISTRY CREDENTIALS SUMMARY
# ==============================================================================

output "acr_credentials_summary" {
  description = "ACR credentials for Docker login"
  value       = <<-EOT
    
    ========== ACR LOGIN CREDENTIALS ==========
    
    Registry URL: ${module.container_registry.acr_login_server}
    Username: ${module.container_registry.admin_username}
    Password: (use 'terraform output acr_admin_password' to view)
    
    To login:
      docker login ${module.container_registry.acr_login_server}
    
    To push images:
      docker tag myimage:latest ${module.container_registry.acr_login_server}/myimage:latest
      docker push ${module.container_registry.acr_login_server}/myimage:latest
    
    ==========================================
  EOT
}

# ==============================================================================
# INFRASTRUCTURE SUMMARY
# ==============================================================================

output "infrastructure_summary" {
  description = "Summary of created infrastructure"
  value       = <<-EOT
    
    ========================================
      BOUTIQUE APP - INFRASTRUCTURE SUMMARY
    ========================================
    
    ENVIRONMENT: ${var.environment}
    LOCATION: ${var.location}
    
    RESOURCE GROUP:
      Name: ${module.resource_group.resource_group_name}
      ID: ${module.resource_group.resource_group_id}
    
    NETWORKING:
      VNet: ${module.networking.vnet_name} (${join(", ", module.networking.vnet_address_space)})
      Private Subnet (AKS): ${join(", ", module.networking.private_subnet_address_space)}
      Public Subnet (LB): ${join(", ", module.networking.public_subnet_address_space)}
      NAT Gateway IP: ${module.networking.nat_gateway_ip}
    
    CONTAINER REGISTRY:
      Name: ${module.container_registry.acr_name}
      Login Server: ${module.container_registry.acr_login_server}
      SKU: ${var.acr_sku}
    
    KUBERNETES CLUSTER:
      Name: ${module.aks.aks_name}
      FQDN: ${module.aks.fqdn}
      API Server: ${module.aks.api_server_fqdn}
      Version: ${module.aks.kubernetes_version}
      Nodes: ${var.node_count} (min: ${var.min_node_count}, max: ${var.max_node_count})
      VM Size: ${var.vm_size}
      Node Resource Group: ${module.aks.node_resource_group}
    
    AUTOSCALING:
      Enabled: ${var.enable_auto_scaling}
      Min Nodes: ${var.min_node_count}
      Max Nodes: ${var.max_node_count}
    
    NEXT STEPS:
      1. Configure kubectl:
         az aks get-credentials --resource-group ${module.resource_group.resource_group_name} --name ${module.aks.aks_name}
      
      2. Verify cluster:
         kubectl get nodes
         kubectl get pods -A
      
      3. Get ACR credentials:
         terraform output acr_admin_password
      
      4. Login to ACR:
         docker login ${module.container_registry.acr_login_server}
      
      5. Push images:
         docker tag myimage:latest ${module.container_registry.acr_login_server}/myimage:latest
         docker push ${module.container_registry.acr_login_server}/myimage:latest
      
      6. Deploy to Kubernetes:
         kubectl apply -f deployment.yaml
    
    ========================================
  EOT
}