resource "azurerm_role_assignment" "agic_appgw_contributor" {
  scope                = module.application_gateway.application_gateway_id
  role_definition_name = "Contributor"
  principal_id         = module.aks.agic_identity_object_id
}

resource "azurerm_role_assignment" "agic_rg_reader" {
  scope                = module.resource_group.resource_group_id
  role_definition_name = "Reader"
  principal_id         = module.aks.agic_identity_object_id
}