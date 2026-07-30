resource "azurerm_user_assigned_identity" "this" {

  name                = var.identity_name
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}


# ACR permission
resource "azurerm_role_assignment" "acr_pull" {

  scope                = var.acr_id
  role_definition_name = "AcrPull"

  principal_id = azurerm_user_assigned_identity.this.principal_id
}


# Reader on Resource Group
resource "azurerm_role_assignment" "agic_rg_reader" {

  scope = var.resource_group_id

  role_definition_name = "Reader"

  principal_id = azurerm_user_assigned_identity.this.principal_id
}


# Contributor on Application Gateway
resource "azurerm_role_assignment" "agic_appgw_contributor" {

  scope = var.application_gateway_id

  role_definition_name = "Contributor"

  principal_id = azurerm_user_assigned_identity.this.principal_id
}


# Network Contributor on App Gateway subnet
resource "azurerm_role_assignment" "agic_subnet_network" {

  scope = var.appgw_subnet_id

  role_definition_name = "Network Contributor"

  principal_id = azurerm_user_assigned_identity.this.principal_id
}