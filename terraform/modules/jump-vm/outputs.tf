output "public_ip" {
  value = azurerm_public_ip.jump.ip_address
}

output "private_ip" {
  value = azurerm_network_interface.jump.private_ip_address
}

output "identity_principal_id" {
  value = azurerm_linux_virtual_machine.jump.identity[0].principal_id
}

output "vm_id" {
  value = azurerm_linux_virtual_machine.jump.id
}