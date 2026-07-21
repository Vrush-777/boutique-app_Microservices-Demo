# ==============================================================================
# AZURE KUBERNETES SERVICE (AKS) CLUSTER
# ==============================================================================
# AKS is a managed Kubernetes service that runs containerized applications.
#
# Key components:
#   1. Control Plane - Managed by Azure (we don't touch this)
#      - API Server: Kubernetes API
#      - etcd: Distributed database storing cluster state
#      - Scheduler: Decides which pod goes on which node
#      - Controller Manager: Manages replicas, jobs, etc.
#
#   2. Worker Nodes - Virtual machines we manage
#      - Run our containerized applications
#      - Scale up/down based on demand
#      - Self-heal if they fail
#
#   3. System Components - Managed by Azure
#      - kube-proxy: Network routing
#      - CoreDNS: Service discovery
#      - Kubelets: Node agents
#      - Container runtime (containerd)
# ==============================================================================

resource "azurerm_kubernetes_cluster" "aks" {
  # name: Name of the Kubernetes cluster
  name = "${var.environment}-aks-cluster"

  # location: Azure region (must match resource group)
  location = var.location

  # resource_group_name: RG from Module 1
  resource_group_name = var.resource_group_name

  # kubernetes_version: Kubernetes version to use
  # Options:
  #   - null (Azure chooses latest stable)
  #   - "1.27.0" (specific version)
  #   - "1.27" (latest 1.27.x)
  #
  # We use null to let Azure choose latest stable version
  # Azure automatically updates the control plane
  kubernetes_version = var.kubernetes_version

  # dns_prefix: Prefix for FQDN of the cluster
  # Example: "poc-aks" becomes "poc-aks-abc123.eastus.cloudapp.azure.com"
  # Used to access Kubernetes API
  dns_prefix = "${var.environment}-aks"

  # ==============================================================================
  # DEFAULT NODE POOL
  # ==============================================================================
  # A node pool is a group of nodes with the same configuration
  # This is the default pool where most workloads run
  # ==============================================================================

  default_node_pool {
    # name: Name of the node pool (max 12 chars, lowercase)
    name = "default"

    # node_count: Initial number of nodes
    # Will be overridden if autoscaling is enabled
    node_count = var.node_count

    # vm_size: Azure VM type for each node
    # Options:
    #   "Standard_B2s"  = 2 vCPU, 4GB RAM (for POC)
    #   "Standard_D2s"  = 2 vCPU, 8GB RAM
    #   "Standard_D4s"  = 4 vCPU, 16GB RAM
    #   "Standard_E4s"  = 4 vCPU, 32GB RAM
    #
    # For POC: Standard_B2s is perfect
    # For production: Choose based on workload needs
    vm_size = var.vm_size

    # vnet_subnet_id: Which subnet to deploy nodes in
    # We use the PRIVATE subnet from Module 2
    # This keeps nodes off the public internet
    vnet_subnet_id = var.vnet_subnet_id

    # os_disk_size_gb: Size of OS disk on each node
    # Default is 128GB, which is good for most workloads
    os_disk_size_gb = var.os_disk_size_gb

    # os_sku: Operating system
    # "Ubuntu" = Linux (recommended)
    # "Windows" = Windows Server (for .NET workloads)
    os_sku = "Ubuntu"

    # ==============================================================================
    # AUTOSCALING CONFIGURATION
    # ==============================================================================
    # Horizontal Pod Autoscaler (HPA) scales pods (not nodes)
    # Cluster Autoscaler scales nodes based on pod resource requests
    # ==============================================================================

    # enable_auto_scaling: Auto-scale number of nodes
    # When true:
    #   - Monitors CPU/memory usage
    #   - Adds nodes when pods can't fit (due to resource limits)
    #   - Removes nodes when they're not needed
    # This saves cost and ensures availability
    enable_auto_scaling = var.enable_auto_scaling

    # min_count: Minimum number of nodes (if autoscaling enabled)
    # Example: min_count = 2 means always keep at least 2 nodes
    # Ensures availability even in low-traffic periods
    min_count = var.min_node_count

    # max_count: Maximum number of nodes (if autoscaling enabled)
    # Example: max_count = 10 means never go above 10 nodes
    # Prevents runaway costs from auto-scaling
    max_count = var.max_node_count

    # ==============================================================================
    # STORAGE AND UPGRADE CONFIGURATION
    # ==============================================================================

    # temporary_name_for_rotation: Temporary name during rolling upgrade
    # Used when upgrading node pools
    temporary_name_for_rotation = "tmpnode"

    # enable_node_public_ip: Assign public IP to each node
    # Options:
    #   true  = Each node has public IP (for testing/debugging)
    #   false = Only accessible via private subnet (recommended for production)
    # We use false because nodes are in private subnet
    enable_node_public_ip = false

    # enable_host_encryption: Encrypt node OS disk
    # true = Encrypt with customer-managed keys (production)
    # false = Encrypt with platform-managed keys (POC)
    enable_host_encryption = false

    # upgrade_settings: How to upgrade nodes
    upgrade_settings {
      # max_surge: How many nodes to upgrade simultaneously
      # Example: max_surge = 1 means one node at a time (slow but safe)
      # For POC: 1 is fine
      # For production: can be higher (e.g., 33%)
      max_surge = "1"
    }

    # tags: Tags for nodes
    tags = merge(
      var.common_tags,
      {
        "NodePool" = "default"
      }
    )
  }

  # ==============================================================================
  # IDENTITY CONFIGURATION
  # ==============================================================================
  # AKS needs an identity to:
  #   - Pull images from ACR
  #   - Access Azure Key Vault for secrets
  #   - Write logs to Azure Monitor
  #   - Create load balancers
  #   - Manage managed disks
  # ==============================================================================

  identity {
    # type: Type of identity
    # Options:
    #   "SystemAssigned" = Azure creates and manages identity (easiest)
    #   "UserAssigned" = You create and manage identity (more control)
    # We use SystemAssigned for simplicity in POC
    type = "SystemAssigned"
  }

  # ==============================================================================
  # NETWORK CONFIGURATION
  # ==============================================================================
  # How pods communicate with each other and the outside world
  # ==============================================================================

  network_profile {
    # network_plugin: CNI (Container Network Interface) plugin
    # Options:
    #   "azure" = Azure CNI (recommended, integrates with Azure VNet)
    #   "kubenet" = Kubenet (older, less flexible)
    # We use "azure" because it integrates with our VNet
    network_plugin = "azure"

    # service_cidr: IP range for Kubernetes services
    # Services get IPs from this range
    # Must NOT overlap with node IP ranges or other networks
    # Example: 10.100.0.0/16 gives 65,536 IPs for services
    service_cidr = var.service_cidr

    # dns_service_ip: IP address for CoreDNS (service discovery)
    # Must be within service_cidr
    # Example: 10.100.0.10
    # When pods do 'nslookup frontend', CoreDNS responds with service IP
    dns_service_ip = var.dns_service_ip

    # docker_bridge_cidr: IP range for Docker bridge network
    # Used by container runtime for internal networking
    # Must NOT overlap with other ranges
    docker_bridge_cidr = var.docker_bridge_cidr

    # network_policy: Kubernetes network policies
    # Options:
    #   null = No network policies (all pods can talk to each other)
    #   "azure" = Use Azure NPM (Network Policy Manager)
    #   "calico" = Use Calico (more advanced)
    # For POC: null is fine
    # For production: "azure" or "calico" for security
    network_policy = "azure"

    # load_balancer_sku: Load balancer SKU
    # Options:
    #   "basic" = Basic LB (older, cheaper)
    #   "standard" = Standard LB (newer, recommended)
    # We use "standard"
    load_balancer_sku = "standard"
  }

  # ==============================================================================
  # RBAC (ROLE-BASED ACCESS CONTROL)
  # ==============================================================================
  # Controls who can do what in Kubernetes
  # ==============================================================================

  role_based_access_control_enabled = var.enable_rbac

  # azure_active_directory_role_based_access_control: Integrate with Azure AD
  azure_active_directory_role_based_access_control {
    # managed: Use Azure-managed Azure AD integration
    managed = true

    # tenant_id: Azure AD tenant ID
    # Your organization's Azure AD
    tenant_id = var.azure_ad_tenant_id

    # admin_group_object_ids: Azure AD groups that get cluster admin access
    # Members of these groups can run 'kubectl' commands
    admin_group_object_ids = var.admin_group_object_ids
  }

  # ==============================================================================
  # LOGGING AND MONITORING
  # ==============================================================================
  # Send logs and metrics to Azure Monitor
  # ==============================================================================

  oms_agent {
    # enabled: Enable Log Analytics agent
    enabled = var.enable_monitoring

    # log_analytics_workspace_id: Where to send logs
    # Will be created in a later module (Module 5: Monitoring)
    # For now, we set it to empty string
    log_analytics_workspace_id = var.log_analytics_workspace_id
  }

  # ==============================================================================
  # INGRESS CONTROLLER CONFIGURATION
  # ==============================================================================
  # Ingress routes HTTP/HTTPS traffic to services
  # ==============================================================================

  http_application_routing_enabled = false

  # We'll use NGINX Ingress Controller instead (separate installation)
  # This is more flexible and widely used

  # ==============================================================================
  # AUTHENTICATION
  # ==============================================================================

  api_server_access_profile {
    # authorized_ip_ranges: IP ranges allowed to access K8s API
    # Examples:
    #   [] = All IPs allowed (for POC/testing)
    #   ["203.0.113.0/24"] = Only this office IP range
    #   ["203.0.113.5/32"] = Only this specific IP
    # For public cluster: leave empty (all IPs allowed)
    authorized_ip_ranges = var.api_server_authorized_ip_ranges
  }

  # ==============================================================================
  # ADDON PROFILES
  # ==============================================================================

  # Tags for the cluster
  tags = merge(
    var.common_tags,
    {
      "Module"   = "aks"
      "Cluster"  = "${var.environment}-aks-cluster"
    }
  )
}

# ==============================================================================
# ROLE ASSIGNMENT: AKS → ACR (Pull Images)
# ==============================================================================
# This allows AKS cluster to pull images from Azure Container Registry
# Without this, AKS can't pull images from ACR
#
# How it works:
#   1. AKS has a managed identity
#   2. We give this identity "AcrPull" role on the ACR
#   3. When AKS needs to pull an image, it uses this identity
#   4. No passwords needed!
# ==============================================================================

resource "azurerm_role_assignment" "aks_acr_pull" {
  # Only create if ACR principal ID is provided
  count = var.acr_principal_id != "" ? 1 : 0

  # scope: Which ACR this applies to
  scope = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.ContainerRegistry/registries/${var.acr_name}"

  # role_definition_name: The role to assign
  # "AcrPull" = Can pull (read) images from ACR
  role_definition_name = "AcrPull"

  # principal_id: WHO gets this role
  # The AKS cluster's managed identity
  principal_id = azurerm_kubernetes_cluster.aks.identity[0].principal_id
}

# ==============================================================================
# ROLE ASSIGNMENT: AKS → Network Contributor
# ==============================================================================
# Allows AKS to manage network resources (load balancers, NSGs, etc.)
# ==============================================================================

resource "azurerm_role_assignment" "aks_network_contributor" {
  # scope: Which VNet this applies to
  scope = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Network/virtualNetworks/${var.vnet_name}"

  # role_definition_name: The role to assign
  # "Network Contributor" = Can create/modify load balancers, NSGs, etc.
  role_definition_name = "Network Contributor"

  # principal_id: AKS managed identity
  principal_id = azurerm_kubernetes_cluster.aks.identity[0].principal_id
}

# ==============================================================================
# ROLE ASSIGNMENT: AKS → Storage Account Contributor
# ==============================================================================
# Allows AKS to create/manage persistent volumes with Azure disks/files
# ==============================================================================

resource "azurerm_role_assignment" "aks_storage_contributor" {
  count = var.enable_storage_contributor ? 1 : 0

  # scope: Which RG this applies to (where storage accounts are created)
  scope = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}"

  # role_definition_name: The role to assign
  role_definition_name = "Storage Account Contributor"

  # principal_id: AKS managed identity
  principal_id = azurerm_kubernetes_cluster.aks.identity[0].principal_id
}

# ==============================================================================
# ROLE ASSIGNMENT: AKS → Managed Identity Operator
# ==============================================================================
# Allows AKS to work with user-assigned managed identities
# Useful if you want pods to have their own identities
# ==============================================================================

resource "azurerm_role_assignment" "aks_managed_identity_operator" {
  count = var.enable_managed_identity_operator ? 1 : 0

  scope                = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}"
  role_definition_name = "Managed Identity Operator"
  principal_id         = azurerm_kubernetes_cluster.aks.identity[0].principal_id
}

# ==============================================================================
# AZURE MONITOR WORKSPACE (for Prometheus metrics) - Optional
# ==============================================================================
# This allows us to use Azure Monitor for Prometheus metrics
# Recommended for production monitoring
# ==============================================================================

resource "azurerm_monitor_workspace" "aks_monitor" {
  count = var.enable_azure_monitor_workspace ? 1 : 0

  name                = "${var.environment}-aks-monitor"
  resource_group_name = var.resource_group_name
  location            = var.location

  tags = merge(
    var.common_tags,
    {
      "Name" = "${var.environment}-aks-monitor"
    }
  )
}

# ==============================================================================
# ASSOCIATE MONITOR WORKSPACE WITH AKS
# ==============================================================================

resource "azurerm_kubernetes_cluster_monitoring_setting" "aks_monitoring" {
  count = var.enable_azure_monitor_workspace ? 1 : 0

  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  metrics_enabled       = true

  log_analytics_workspace_id = try(azurerm_monitor_workspace.aks_monitor[0].id, null)
}

# ==============================================================================
# END OF AKS MAIN.TF
# ==============================================================================
# Summary of what we created:
#
# 1. AKS Cluster
#    - Kubernetes control plane (managed by Azure)
#    - Default node pool with autoscaling
#    - Network configuration (Azure CNI)
#    - RBAC enabled
#    - Azure AD integration for admin access
#
# 2. Role Assignments
#    - AKS can pull from ACR
#    - AKS can manage network resources
#    - AKS can manage storage
#    - AKS can work with managed identities
#
# 3. Monitoring (optional)
#    - Azure Monitor workspace
#    - Connected to AKS for metrics
#
# After applying this module:
#   ✅ Kubernetes cluster is ready
#   ✅ 3 nodes running
#   ✅ Can deploy applications
#   ✅ Can integrate with ACR
#   ✅ Can access via kubectl
# ==============================================================================