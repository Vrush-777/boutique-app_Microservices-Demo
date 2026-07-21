# ==============================================================================
# OUTPUT: ACR ID
# ==============================================================================
# The unique identifier of the Container Registry
# Used by other modules or for reference
#
# Example format:
#   /subscriptions/12345/resourceGroups/rg-poc-eastus/providers/Microsoft.ContainerRegistry/registries/acrpocboutique
# ==============================================================================

output "acr_id" {
  description = "ID of the Container Registry"
  value       = azurerm_container_registry.acr.id
}

# ==============================================================================
# OUTPUT: ACR NAME
# ==============================================================================
# The name of the Container Registry
# This is what you'll see in Azure Portal and use in commands
#
# Example: "acrpocboutique"
#
# Used for:
#   - Docker login: docker login acrpocboutique.azurecr.io
#   - Image tagging: acrpocboutique.azurecr.io/frontend:latest
#   - Azure CLI commands
# ==============================================================================

output "acr_name" {
  description = "Name of the Container Registry"
  value       = azurerm_container_registry.acr.name
}

# ==============================================================================
# OUTPUT: ACR LOGIN SERVER
# ==============================================================================
# The full domain name to use for Docker login and image operations
#
# Example: "acrpocboutique.azurecr.io"
#
# This is used for:
#   1. Docker login:
#      docker login acrpocboutique.azurecr.io
#
#   2. Tagging images:
#      docker tag myimage:latest acrpocboutique.azurecr.io/myimage:latest
#
#   3. Pushing images:
#      docker push acrpocboutique.azurecr.io/myimage:latest
#
#   4. Pulling images in AKS:
#      containers:
#        - name: frontend
#          image: acrpocboutique.azurecr.io/frontend:latest
#
# This is the MOST IMPORTANT output for CI/CD and deployments!
# ==============================================================================

output "acr_login_server" {
  description = "Login server for the Container Registry"
  value       = azurerm_container_registry.acr.login_server
}

# ==============================================================================
# OUTPUT: ADMIN USERNAME
# ==============================================================================
# Username for admin access to ACR
# Only available if admin_enabled = true
#
# Used for:
#   docker login -u <username> -p <password> <login-server>
#
# WARNING:
#   - This is less secure than using managed identity
#   - Only use for POC/testing
#   - Store password securely (never in code!)
#   - For production, use Service Principals
# ==============================================================================

output "admin_username" {
  description = "Admin username for ACR (if admin enabled)"
  value       = var.admin_enabled ? azurerm_container_registry.acr.admin_username : null
}

# ==============================================================================
# OUTPUT: ADMIN PASSWORD
# ==============================================================================
# Password for admin access to ACR
# Only available if admin_enabled = true
#
# WARNING - SENSITIVE DATA:
#   - This is a password - KEEP IT SECRET!
#   - Marked as sensitive so Terraform hides it
#   - Never commit to Git!
#   - Store in Azure Key Vault!
#   - Rotate regularly!
#
# How to use:
#   1. Get password from Terraform output:
#      terraform output admin_password
#   2. Use for Docker login:
#      docker login -u <username> -p <password> <login-server>
#   3. Or store in Docker config for automated access
#
# Better approach:
#   - Use managed identity instead (no password needed)
#   - Only use this for POC demonstrations
# ==============================================================================

output "admin_password" {
  description = "Admin password for ACR (if admin enabled)"
  value       = var.admin_enabled ? azurerm_container_registry.acr.admin_password : null
  sensitive   = true  # Hides from logs and console output
}

# ==============================================================================
# OUTPUT: ACR SKU
# ==============================================================================
# The pricing tier of the Container Registry
#
# Useful for:
#   - Documenting what tier is in use
#   - Billing/cost tracking
#   - Validating configuration
# ==============================================================================

output "acr_sku" {
  description = "SKU of the Container Registry"
  value       = azurerm_container_registry.acr.sku
}

# ==============================================================================
# OUTPUT: ACR ENDPOINT
# ==============================================================================
# The full endpoint URL for accessing ACR
# Same as login_server, useful for documentation
#
# Example: "acrpocboutique.azurecr.io"
# ==============================================================================

output "acr_endpoint" {
  description = "Endpoint URL for the Container Registry"
  value       = "https://${azurerm_container_registry.acr.login_server}"
}

# ==============================================================================
# OUTPUT: WEBHOOK ID (if created)
# ==============================================================================
# ID of the webhook resource
# Useful for updating or deleting webhook later
# ==============================================================================

output "webhook_id" {
  description = "ID of the ACR webhook (if created)"
  value       = try(azurerm_container_registry_webhook.image_push_webhook[0].id, null)
}

# ==============================================================================
# Summary of Key Outputs
# ==============================================================================
# For CI/CD (GitHub Actions):
#   - registry_name: acrpocboutique
#   - registry_login_server: acrpocboutique.azurecr.io
#   - admin_username: if admin enabled
#   - admin_password: if admin enabled
#
# For Kubernetes Deployments:
#   - image: acrpocboutique.azurecr.io/frontend:latest
#   - AKS pulls from ACR using managed identity (no auth needed)
#
# For Documentation:
#   - acr_sku: What tier we're using
#   - acr_id: Full resource ID
#   - acr_endpoint: Full URL
# ==============================================================================