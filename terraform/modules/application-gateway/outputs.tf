output "application_gateway_id" {
  value = azurerm_application_gateway.this.id
}

output "application_gateway_name" {
  value = azurerm_application_gateway.this.name
}

output "public_ip" {
  value = azurerm_public_ip.this.ip_address
}

output "public_ip_id" {
  value = azurerm_public_ip.this.id
}

output "identity_id" {
  value = azurerm_user_assigned_identity.appgw.id
}

output "identity_client_id" {
  value = azurerm_user_assigned_identity.appgw.client_id
}

output "identity_principal_id" {
  description = "User Assigned Managed Identity principal ID used by Application Gateway"
  value       = azurerm_user_assigned_identity.appgw.principal_id
}