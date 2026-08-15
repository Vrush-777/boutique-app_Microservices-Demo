output "vnet_id" {
  value = azurerm_virtual_network.this.id
}

output "vnet_name" {
  value = azurerm_virtual_network.this.name
}

output "jump_subnet_id" {
  value = azurerm_subnet.jump.id
}

output "aks_subnet_id" {
  value = azurerm_subnet.aks.id
}

output "appgw_subnet_id" {
  value = azurerm_subnet.appgw.id
}

output "aks_subnet_name" {
  value = azurerm_subnet.aks.name
}

output "appgw_subnet_name" {
  value = azurerm_subnet.appgw.name
}