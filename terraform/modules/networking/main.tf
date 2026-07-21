# ==============================================================================
# AZURE VIRTUAL NETWORK (VNet)
# ==============================================================================
# A Virtual Network is like a private network in Azure.
# It defines the IP address space and subnet structure.
#
# Think of it as:
#   VNet = your company's private network
#   Subnets = different departments within the company
#
# We're using:
#   - Address space: 10.0.0.0/16 (65,536 IP addresses available)
#   - This gives us room for multiple subnets
# ==============================================================================

resource "azurerm_virtual_network" "vnet" {
  # name: Name of the VNet
  name = "${var.environment}-vnet"

  # address_space: IP ranges available in this VNet
  # 10.0.0.0/16 means:
  #   - 10.0 = Network
  #   - 0.0 = Subnet
  #   - /16 = 65,536 possible IP addresses (10.0.0.0 to 10.0.255.255)
  address_space = var.vnet_address_space

  # location: Must be the same as Resource Group
  location = var.location

  # resource_group_name: The RG we created in Module 1
  resource_group_name = var.resource_group_name

  # tags: Metadata for organization and billing
  tags = merge(
    var.common_tags,
    {
      "Module" = "networking"
      "Name"   = "${var.environment}-vnet"
    }
  )
}

# ==============================================================================
# PUBLIC SUBNET
# ==============================================================================
# This subnet is for public-facing resources:
#   - Application Load Balancer (ALB)
#   - Public IPs
#   - Resources that need internet access from outside
#
# Address space: 10.0.1.0/24
#   - Can host 256 IP addresses (10.0.1.0 to 10.0.1.255)
#   - Azure reserves first 4 and last 1, so ~250 usable IPs
# ==============================================================================

resource "azurerm_subnet" "public" {
  # name: Subnet name
  name = "${var.environment}-public-subnet"

  # resource_group_name: Must be in the same RG
  resource_group_name = var.resource_group_name

  # virtual_network_name: Which VNet this subnet belongs to
  virtual_network_name = azurerm_virtual_network.vnet.name

  # address_prefixes: IP range for this subnet
  # 10.0.1.0/24 = 256 addresses in this subnet
  address_prefixes = var.public_subnet_address_space

  # service_endpoints: Allows secure connection to Azure services
  # These services don't need to go through internet gateway
  service_endpoints = [
    "Microsoft.Storage",      # For accessing Azure Storage securely
    "Microsoft.KeyVault",     # For accessing Azure Key Vault securely
    "Microsoft.Sql"           # For accessing Azure SQL securely
  ]
}

# ==============================================================================
# PRIVATE SUBNET
# ==============================================================================
# This subnet is for internal resources that don't need public internet:
#   - AKS Nodes (Kubernetes)
#   - Databases
#   - Internal services
#
# Address space: 10.0.2.0/24
#   - Can host 256 IP addresses
# ==============================================================================

resource "azurerm_subnet" "private" {
  # name: Subnet name
  name = "${var.environment}-private-subnet"

  # resource_group_name: Must be in the same RG
  resource_group_name = var.resource_group_name

  # virtual_network_name: Which VNet this subnet belongs to
  virtual_network_name = azurerm_virtual_network.vnet.name

  # address_prefixes: IP range for this subnet
  # 10.0.2.0/24 = 256 addresses in this subnet
  address_prefixes = var.private_subnet_address_space

  # service_endpoints: Same as public subnet
  service_endpoints = [
    "Microsoft.Storage",
    "Microsoft.KeyVault",
    "Microsoft.Sql"
  ]
}

# ==============================================================================
# NETWORK SECURITY GROUP (NSG) - PUBLIC SUBNET
# ==============================================================================
# NSG = Network firewall for subnets
# It controls what traffic is allowed IN and OUT
#
# Think of it as:
#   - Inbound rules: Which traffic can come IN to resources
#   - Outbound rules: Which traffic can go OUT from resources
#
# For PUBLIC subnet, we allow:
#   - HTTP (port 80) and HTTPS (port 443) from internet
#   - Kubernetes API (port 6443) for management
# ==============================================================================

resource "azurerm_network_security_group" "public_nsg" {
  # name: NSG name
  name = "${var.environment}-public-nsg"

  # location and resource_group_name: Must match VNet
  location            = var.location
  resource_group_name = var.resource_group_name

  # Inbound rules defined below
  
  tags = merge(
    var.common_tags,
    {
      "Name" = "${var.environment}-public-nsg"
    }
  )
}

# ==============================================================================
# NSG INBOUND RULE: ALLOW HTTPS (Port 443)
# ==============================================================================
# Allows encrypted web traffic from anywhere on the internet
# ==============================================================================

resource "azurerm_network_security_rule" "public_allow_https" {
  # name: Rule name (must be unique within NSG)
  name = "AllowHTTPS"

  # priority: Rules are processed in order (lower number = higher priority)
  # Range: 100-4096
  # We use 100 for important rules
  priority = 100

  # direction: Inbound = coming INTO the subnet
  direction = "Inbound"

  # access: Allow or Deny this traffic
  access = "Allow"

  # protocol: TCP, UDP, or both (*)
  protocol = "Tcp"

  # source_port_range: Which ports the request is coming FROM
  # "*" means any port
  source_port_range = "*"

  # destination_port_range: Which ports to allow on our resources
  # 443 = HTTPS (secure web traffic)
  destination_port_range = "443"

  # source_address_prefix: Where traffic comes FROM
  # "*" = from anywhere on the internet
  source_address_prefix = "*"

  # destination_address_prefix: Which resources this applies to
  # "*" = all resources in this subnet
  destination_address_prefix = "*"

  # Link this rule to the NSG
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.public_nsg.name
}

# ==============================================================================
# NSG INBOUND RULE: ALLOW HTTP (Port 80)
# ==============================================================================
# Allows unencrypted web traffic from anywhere on the internet
# (Usually redirects to HTTPS)
# ==============================================================================

resource "azurerm_network_security_rule" "public_allow_http" {
  name              = "AllowHTTP"
  priority          = 101
  direction         = "Inbound"
  access            = "Allow"
  protocol          = "Tcp"
  source_port_range = "*"
  
  # Port 80 = HTTP
  destination_port_range = "80"
  
  # From anywhere
  source_address_prefix      = "*"
  destination_address_prefix = "*"

  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.public_nsg.name
}

# ==============================================================================
# NSG INBOUND RULE: ALLOW KUBERNETES API (Port 6443)
# ==============================================================================
# Allows management traffic to AKS Kubernetes API server
# ==============================================================================

resource "azurerm_network_security_rule" "public_allow_k8s_api" {
  name              = "AllowKubernetesAPI"
  priority          = 102
  direction         = "Inbound"
  access            = "Allow"
  protocol          = "Tcp"
  source_port_range = "*"
  
  # Port 6443 = Kubernetes API Server
  destination_port_range = "6443"
  
  # From anywhere (in real production, restrict this to your office IP)
  source_address_prefix      = "*"
  destination_address_prefix = "*"

  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.public_nsg.name
}

# ==============================================================================
# NETWORK SECURITY GROUP (NSG) - PRIVATE SUBNET
# ==============================================================================
# For PRIVATE subnet, we're more restrictive:
#   - Only allow traffic from within the VNet
#   - Block external access (except through NAT Gateway)
# ==============================================================================

resource "azurerm_network_security_group" "private_nsg" {
  name                = "${var.environment}-private-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = merge(
    var.common_tags,
    {
      "Name" = "${var.environment}-private-nsg"
    }
  )
}

# ==============================================================================
# NSG INBOUND RULE: ALLOW TRAFFIC FROM WITHIN VNet (Private Subnet)
# ==============================================================================
# Allow all traffic coming from the VNet itself
# This allows AKS nodes to communicate with each other
# ==============================================================================

resource "azurerm_network_security_rule" "private_allow_vnet" {
  name              = "AllowVNetInbound"
  priority          = 100
  direction         = "Inbound"
  access            = "Allow"
  protocol          = "*"  # All protocols
  source_port_range = "*"
  destination_port_range = "*"
  
  # Source: Traffic from the VNet address space
  source_address_prefix = var.vnet_address_space[0]
  
  # Destination: All resources in private subnet
  destination_address_prefix = "*"

  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.private_nsg.name
}

# ==============================================================================
# NSG INBOUND RULE: ALLOW TRAFFIC FROM PUBLIC SUBNET
# ==============================================================================
# Allow traffic from Load Balancer to AKS nodes
# ==============================================================================

resource "azurerm_network_security_rule" "private_allow_public_subnet" {
  name              = "AllowPublicSubnetInbound"
  priority          = 101
  direction         = "Inbound"
  access            = "Allow"
  protocol          = "*"
  source_port_range = "*"
  destination_port_range = "*"
  
  # Source: Public subnet
  source_address_prefix = var.public_subnet_address_space[0]
  
  # Destination: All private subnet
  destination_address_prefix = "*"

  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.private_nsg.name
}

# ==============================================================================
# NSG INBOUND RULE: DENY ALL OTHER INBOUND TRAFFIC
# ==============================================================================
# This is a catch-all rule that denies everything not explicitly allowed
# Priority 4096 means it's processed last (default deny)
# ==============================================================================

resource "azurerm_network_security_rule" "private_deny_all_inbound" {
  name              = "DenyAllInbound"
  priority          = 4096
  direction         = "Inbound"
  access            = "Deny"
  protocol          = "*"
  source_port_range = "*"
  destination_port_range = "*"
  
  # Deny from anywhere
  source_address_prefix      = "*"
  destination_address_prefix = "*"

  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.private_nsg.name
}

# ==============================================================================
# ASSOCIATE NSG WITH PUBLIC SUBNET
# ==============================================================================
# This links the NSG rules to the subnet
# Now the subnet uses these firewall rules
# ==============================================================================

resource "azurerm_subnet_network_security_group_association" "public_nsg_assoc" {
  # subnet_id: Which subnet to attach to
  subnet_id = azurerm_subnet.public.id

  # network_security_group_id: Which NSG to attach
  network_security_group_id = azurerm_network_security_group.public_nsg.id
}

# ==============================================================================
# ASSOCIATE NSG WITH PRIVATE SUBNET
# ==============================================================================
# This links the NSG rules to the private subnet
# ==============================================================================

resource "azurerm_subnet_network_security_group_association" "private_nsg_assoc" {
  subnet_id              = azurerm_subnet.private.id
  network_security_group_id = azurerm_network_security_group.private_nsg.id
}

# ==============================================================================
# PUBLIC IP ADDRESS FOR NAT GATEWAY
# ==============================================================================
# The NAT Gateway needs a static public IP address
# This IP is used for all outbound traffic from private subnet
#
# NAT = Network Address Translation
# It translates private IPs to public IP for outbound connections
# ==============================================================================

resource "azurerm_public_ip" "nat_gateway_ip" {
  # name: Public IP name
  name = "${var.environment}-nat-gateway-ip"

  # location and resource_group_name: Must match VNet
  location            = var.location
  resource_group_name = var.resource_group_name

  # allocation_method: Static or Dynamic
  # "Static" = IP stays the same (recommended for NAT Gateway)
  allocation_method = "Static"

  # sku: Standard or Basic
  # "Standard" = for NAT Gateway compatibility and better performance
  sku = "Standard"

  tags = merge(
    var.common_tags,
    {
      "Name" = "${var.environment}-nat-gateway-ip"
    }
  )
}

# ==============================================================================
# NAT GATEWAY
# ==============================================================================
# NAT Gateway allows outbound internet access from private subnet
# while keeping inbound access restricted
#
# Without NAT Gateway:
#   - Private subnet resources CANNOT reach the internet
#   - They're completely isolated
#
# With NAT Gateway:
#   - Private subnet resources CAN reach the internet (for updates, etc.)
#   - But internet CANNOT initiate connections to them
#
# This is the security pattern we want!
# ==============================================================================

resource "azurerm_nat_gateway" "nat_gateway" {
  # name: NAT Gateway name
  name = "${var.environment}-nat-gateway"

  # location and resource_group_name: Must match VNet
  location            = var.location
  resource_group_name = var.resource_group_name

  # sku_name: Only option is "Standard"
  sku_name = "Standard"

  tags = merge(
    var.common_tags,
    {
      "Name" = "${var.environment}-nat-gateway"
    }
  )
}

# ==============================================================================
# ASSOCIATE PUBLIC IP WITH NAT GATEWAY
# ==============================================================================
# The NAT Gateway needs to use the public IP we created above
# ==============================================================================

resource "azurerm_nat_gateway_public_ip_association" "nat_ip_assoc" {
  # nat_gateway_id: Which NAT Gateway
  nat_gateway_id = azurerm_nat_gateway.nat_gateway.id

  # public_ip_address_id: Which public IP to use
  public_ip_address_id = azurerm_public_ip.nat_gateway_ip.id
}

# ==============================================================================
# ASSOCIATE NAT GATEWAY WITH PRIVATE SUBNET
# ==============================================================================
# This tells the private subnet to use this NAT Gateway for outbound traffic
# ==============================================================================

resource "azurerm_subnet_nat_gateway_association" "private_nat_assoc" {
  # subnet_id: Which subnet to attach to
  subnet_id = azurerm_subnet.private.id

  # nat_gateway_id: Which NAT Gateway to use
  nat_gateway_id = azurerm_nat_gateway.nat_gateway.id
}

# ==============================================================================
# INTERNET GATEWAY
# ==============================================================================
# This allows resources in public subnet to reach the internet
# and allows internet to reach resources in public subnet
# ==============================================================================

resource "azurerm_route_table" "public_rt" {
  # name: Route table name
  name = "${var.environment}-public-rt"

  # location and resource_group_name
  location            = var.location
  resource_group_name = var.resource_group_name

  # Routes are defined below
  
  tags = merge(
    var.common_tags,
    {
      "Name" = "${var.environment}-public-rt"
    }
  )
}

# ==============================================================================
# DEFAULT ROUTE TO INTERNET GATEWAY
# ==============================================================================
# This route says: "For any traffic going to the internet (0.0.0.0/0),
# send it through the internet gateway"
# ==============================================================================

resource "azurerm_route" "public_internet_route" {
  # name: Route name
  name = "InternetRoute"

  # resource_group_name and route_table_name
  resource_group_name  = var.resource_group_name
  route_table_name     = azurerm_route_table.public_rt.name

  # address_prefix: Which traffic this applies to
  # 0.0.0.0/0 = all internet traffic
  address_prefix = "0.0.0.0/0"

  # next_hop_type: Where to send traffic
  # "Internet" = send to internet gateway
  next_hop_type = "Internet"
}

# ==============================================================================
# ASSOCIATE ROUTE TABLE WITH PUBLIC SUBNET
# ==============================================================================
# This tells the public subnet to use this route table
# ==============================================================================

resource "azurerm_subnet_route_table_association" "public_rt_assoc" {
  # subnet_id: Which subnet
  subnet_id = azurerm_subnet.public.id

  # route_table_id: Which route table
  route_table_id = azurerm_route_table.public_rt.id
}

# ==============================================================================
# END OF NETWORKING MODULE
# ==============================================================================
# Summary of what we created:
#
# 1. VNet (10.0.0.0/16) - Overall network
#    ├── Public Subnet (10.0.1.0/24) - For Load Balancer
#    ├── Private Subnet (10.0.2.0/24) - For AKS nodes
#
# 2. NSG (Public) - Allows HTTP/HTTPS/K8s API
# 3. NSG (Private) - Allows only VNet traffic
#
# 4. NAT Gateway - Allows private subnet outbound internet access
# 5. Internet Gateway - Allows public subnet internet access
#
# Traffic flow:
#   Internet → ALB (Public Subnet) → AKS Nodes (Private Subnet)
#   AKS Nodes → NAT Gateway → Internet (for updates, etc.)
# ==============================================================================