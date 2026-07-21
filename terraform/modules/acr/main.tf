# ==============================================================================
# AZURE CONTAINER REGISTRY (ACR)
# ==============================================================================
# ACR is a private Docker image registry hosted on Azure.
#
# What it does:
#   1. Stores Docker images (like Docker Hub, but private)
#   2. Allows AKS to pull images securely
#   3. Integrates with CI/CD pipelines
#   4. Provides image scanning for vulnerabilities
#
# Why not use Docker Hub?
#   1. Private - not visible to the public
#   2. Faster - no internet bandwidth needed
#   3. Secure - authentication required
#   4. Integrated with Azure services
#
# Typical image names in ACR:
#   acrpocboutique.azurecr.io/frontend:latest
#   acrpocboutique.azurecr.io/cartservice:v1.0.0
#   acrpocboutique.azurecr.io/currencyservice:main-abc123
# ==============================================================================

resource "azurerm_container_registry" "acr" {
  # name: Registry name (must be unique across Azure)
  # Naming rules:
  #   - 5-50 characters
  #   - Alphanumeric only (no special characters, no hyphens)
  #   - Must be unique across all Azure
  #
  # We create it like: acrpocboutique (acr + environment + project name)
  name = "acr${var.acr_name_suffix}"

  # resource_group_name: Which RG to create this in
  resource_group_name = var.resource_group_name

  # location: Must match resource group location
  location = var.location

  # sku: Pricing tier
  # Options:
  #   "Basic"     = Cheapest, limited features, 10GB storage
  #   "Standard"  = Recommended for most, 100GB storage, better performance
  #   "Premium"   = Most features, 500GB storage, geo-replication
  #
  # We use "Standard" for POC (good balance of cost and features)
  sku = var.sku

  # admin_enabled: Enable admin account (username/password access)
  # Options:
  #   true  = Can login with username/password (easier for POC)
  #   false = Must use Service Principal (more secure for production)
  #
  # For POC, we enable it for simplicity
  # For production, disable and use Azure AD / Service Principals
  admin_enabled = var.admin_enabled

  # public_network_access_enabled: Allow access from public internet
  # Options:
  #   true  = Can pull/push from anywhere (POC setup)
  #   false = Requires private endpoint (production security)
  public_network_access_enabled = var.public_network_access_enabled

  # zone_redundancy_enabled: Replicate across Azure availability zones
  # Options:
  #   true  = Replicate data across zones (high availability, costs more)
  #   false = Single zone (good enough for POC)
  #
  # Only available in Premium SKU, so we set it conditionally
  zone_redundancy_enabled = var.sku == "Premium" ? var.zone_redundancy_enabled : false

  # tags: Metadata for organization and cost tracking
  tags = merge(
    var.common_tags,
    {
      "Module" = "container_registry"
      "Name"   = "acr-${var.environment}"
    }
  )
}

# ==============================================================================
# EXPLANATION OF ROLES AND AUTHENTICATION
# ==============================================================================
# When AKS needs to pull images from ACR, it needs authentication.
# We use Azure's managed identity system:
#
# 1. AKS has an identity (automatically created)
# 2. We give that identity permission to pull from ACR
# 3. AKS uses this permission automatically (no passwords needed)
#
# This is the most secure approach!
# ==============================================================================

# ==============================================================================
# ALLOW AKS TO PULL IMAGES FROM ACR (Role Assignment)
# ==============================================================================
# This role assignment says:
# "AKS cluster, you are allowed to pull (read) images from this ACR"
#
# The role "AcrPull" includes permissions to:
#   - List repositories
#   - Read image metadata
#   - Pull/download images
#   - But NOT push/upload images
#
# Why AcrPull and not AcrPush?
#   - AKS only needs to PULL images, not push them
#   - Principle of least privilege: only give needed permissions
#   - CI/CD pipeline will push images (different service principal)
#
# This assumes:
#   - var.aks_identity_principal_id is provided by AKS module
#   - This will be set up after we create Module 4 (AKS)
#   - For now, this is a placeholder that will be populated later
# ==============================================================================

resource "azurerm_role_assignment" "aks_acr_pull" {
  # scope: What resource this permission applies to
  # We're giving permission to use THIS ACR
  scope = azurerm_container_registry.acr.id

  # role_definition_name: Which role to assign
  # "AcrPull" = Permission to pull images from ACR
  role_definition_name = "AcrPull"

  # principal_id: WHO gets this permission
  # This is the AKS cluster's managed identity
  # Set by: module.aks.aks_identity_principal_id
  principal_id = var.aks_identity_principal_id
}

# ==============================================================================
# ENABLE WEBHOOK (Optional - for CI/CD automation)
# ==============================================================================
# A webhook is like a notification:
#   "When an image is pushed to ACR, notify someone/something"
#
# We create a webhook that:
#   1. Listens for image push events
#   2. Can trigger automated deployments
#   3. Can run custom scripts
#
# For POC with GitHub Actions:
#   - GitHub Actions builds the image
#   - GitHub Actions pushes to ACR
#   - ACR webhook could trigger ArgoCD to deploy
#   - ArgoCD would pull from Git and deploy to K8s
#
# For now, this is optional. We'll set it up later in the CI/CD module.
# ==============================================================================

resource "azurerm_container_registry_webhook" "image_push_webhook" {
  # Only create if var.create_webhook is true
  count = var.create_webhook ? 1 : 0

  # name: Webhook name
  name = "${var.environment}-push-webhook"

  # registry_name and resource_group_name: Which ACR
  registry_name       = azurerm_container_registry.acr.name
  resource_group_name = var.resource_group_name

  # location: Azure region
  location = var.location

  # service_uri: URL to call when an image is pushed
  # This would be something like:
  #   https://argocd.example.com/api/webhook
  #   https://your-webhook-server.com/push-notification
  service_uri = var.webhook_service_uri

  # events: Which events trigger the webhook
  # Options: "push", "delete", "quarantine", "chart_push", "chart_delete"
  events = ["push"]  # Trigger on image push

  # status: Enable or disable the webhook
  status = "Enabled"

  # scope: Which repositories trigger this webhook
  # "*" = all repositories
  # "frontend:*" = only frontend images
  scope = "*"

  # custom_headers: Extra HTTP headers to send with webhook
  # Useful for authentication
  custom_headers = {
    "X-Webhook-Token" = var.webhook_token
  }

  # auth_header: HTTP Basic auth header (if needed)
  # Format: base64(username:password)
  # Or leave empty if not needed
  auth_header = ""

  tags = merge(
    var.common_tags,
    {
      "Name" = "${var.environment}-acr-webhook"
    }
  )
}

# ==============================================================================
# ENABLE IMAGE SCANNING (Vulnerability Assessment)
# ==============================================================================
# Azure can automatically scan images for security vulnerabilities
# when they're pushed to ACR
#
# What it does:
#   1. Scans image for known vulnerabilities
#   2. Reports critical, high, medium, low severity issues
#   3. Can prevent deployment if vulnerabilities found
#
# For production, this is ESSENTIAL for security!
# For POC, it's nice to have but not critical.
#
# Example:
#   Image contains old version of OpenSSL with CVE-2023-1234
#   Scanner detects this and reports it
#   You can choose to patch and rebuild, or accept the risk
# ==============================================================================

# Note: Image scanning is managed by Azure Policy, not directly in Terraform
# We document this as a best practice
# To enable manually:
#   1. Go to ACR in Azure Portal
#   2. Settings → Security Features → Vulnerability assessment
#   3. Click "Register with Microsoft Defender for Cloud"

# ==============================================================================
# RETENTION POLICY (Auto-delete old images)
# ==============================================================================
# Over time, you'll have many versions of images:
#   - frontend:latest
#   - frontend:v1.0.0
#   - frontend:v2.0.0
#   - frontend:v2.1.0
#   - frontend:main-abc123
#   - frontend:main-def456
#   ...and hundreds more
#
# This policy automatically deletes old unused images to save storage costs
#
# Example policy:
#   "Keep only images tagged as 'latest' or 'v*' (release versions)"
#   "Delete images older than 90 days that don't have keep tag"
#
# This prevents ACR from filling up with old images
# ==============================================================================

# Note: Retention policy requires Premium SKU
# For Standard SKU (our POC), we can't use auto-cleanup
# We'll need to manually delete old images occasionally
# Or use Azure CLI to create retention policies

# ==============================================================================
# END OF ACR MAIN.TF
# ==============================================================================
# Summary of what we created:
#
# 1. Azure Container Registry (ACR)
#    - Private Docker image storage
#    - Integrated with Azure services
#    - Can authenticate with multiple methods
#
# 2. Role Assignment (ACS → AKS)
#    - Allows AKS cluster to pull images
#    - Uses managed identity (secure, no passwords)
#
# 3. Optional: Webhook
#    - Notifies systems when images are pushed
#    - Can trigger automated deployments
#
# Why ACR over Docker Hub?
#   1. Private - only authorized users can access
#   2. Faster - no internet bandwidth
#   3. Secure - integrated with Azure authentication
#   4. Controlled - can enforce image signing, scanning
#   5. Cost-effective - included in Azure subscription
# ==============================================================================