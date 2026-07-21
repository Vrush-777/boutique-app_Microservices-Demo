# ==============================================================================
# OUTPUT: VNET ID
# ==============================================================================
# The unique identifier of the Virtual Network
# Used by other modules (AKS needs to know which VNet to use)
# ==============================================================================

output "vnet_id" {
  description = "ID of the Virtual Network"
  value       = azurerm_virtual_network.vnet.id
}

# ==============================================================================
# OUTPUT: VNET NAME
# ==============================================================================
# The name of the Virtual Network
# ==============================================================================

output "vnet_name" {
  description = "Name of the Virtual Network"
  value       = azurerm_virtual_network.vnet.name
}

# ==============================================================================
# OUTPUT: PUBLIC SUBNET ID
# ==============================================================================
# The unique identifier of the public subnet
# AKS ALB (Load Balancer) will be deployed in this subnet
# ==============================================================================

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = azurerm_subnet.public.id
}

# ==============================================================================
# OUTPUT: PRIVATE SUBNET ID
# ==============================================================================
# The unique identifier of the private subnet
# AKS nodes will be deployed in this subnet
# This is the MOST IMPORTANT output for the AKS module
# ==============================================================================

output "private_subnet_id" {
  description = "ID of the private subnet"
  value       = azurerm_subnet.private.id
}

# ==============================================================================
# OUTPUT: PUBLIC NSG ID
# ==============================================================================
# The unique identifier of the public subnet NSG (firewall)
# ==============================================================================

output "public_nsg_id" {
  description = "ID of the public subnet NSG"
  value       = azurerm_network_security_group.public_nsg.id
}

# ==============================================================================
# OUTPUT: PRIVATE NSG ID
# ==============================================================================
# The unique identifier of the private subnet NSG (firewall)
# ==============================================================================

output "private_nsg_id" {
  description = "ID of the private subnet NSG"
  value       = azurerm_network_security_group.private_nsg.id
}

# ==============================================================================
# OUTPUT: NAT GATEWAY IP ADDRESS
# ==============================================================================
# The public IP address used for outbound traffic from private subnet
# All traffic from AKS nodes will appear to come from this IP
# ==============================================================================

output "nat_gateway_ip" {
  description = "Public IP address of the NAT Gateway"
  value       = azurerm_public_ip.nat_gateway_ip.ip_address
}

# ==============================================================================
# OUTPUT: NAT GATEWAY ID
# ==============================================================================
# The unique identifier of the NAT Gateway
# ==============================================================================

output "nat_gateway_id" {
  description = "ID of the NAT Gateway"
  value       = azurerm_nat_gateway.nat_gateway.id
}

# ==============================================================================
# OUTPUT: VNET ADDRESS SPACE
# ==============================================================================
# The IP range of the entire VNet
# Used for validation and documentation
# ==============================================================================

output "vnet_address_space" {
  description = "Address space of the VNet"
  value       = azurerm_virtual_network.vnet.address_space
}

# ==============================================================================
# OUTPUT: PUBLIC SUBNET ADDRESS SPACE
# ==============================================================================
# The IP range of the public subnet
# ==============================================================================

output "public_subnet_address_space" {
  description = "Address space of the public subnet"
  value       = azurerm_subnet.public.address_prefixes
}

# ==============================================================================
# OUTPUT: PRIVATE SUBNET ADDRESS SPACE
# ==============================================================================
# The IP range of the private subnet
# ==============================================================================

output "private_subnet_address_space" {
  description = "Address space of the private subnet"
  value       = azurerm_subnet.private.address_prefixes
}

# ==============================================================================
# Why So Many Outputs?
# ==============================================================================
# 1. AKS module needs subnet IDs
# 2. We want to display network info to users
# 3. We might need IPs for documentation
# 4. Future modules might need this information
#
# The most critical output for the next module is:
#   - private_subnet_id (where AKS nodes go)
#   - public_subnet_id (where Load Balancer goes)
# ==============================================================================