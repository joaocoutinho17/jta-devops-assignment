# Static Web App
resource "azurerm_static_web_app" "frontend" {
  name                = "stapp-${local.prefix}"
  resource_group_name = azurerm_resource_group.apps.name
  location            = azurerm_resource_group.apps.location

  sku_tier = var.static_web_app_sku_tier
  sku_size = var.static_web_app_sku_size

  public_network_access_enabled = false

  tags = local.tags
}

# Private Endpoint
resource "azurerm_private_endpoint" "frontend" {
  name                = "pe-stapp-${local.prefix}"
  resource_group_name = azurerm_resource_group.apps.name
  location            = azurerm_resource_group.apps.location
  subnet_id           = azurerm_subnet.frontend.id

  private_service_connection {
    name                           = "psc-stapp-${local.prefix}"
    private_connection_resource_id = azurerm_static_web_app.frontend.id
    subresource_names              = ["staticSites"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "dns-group-stapp-${local.prefix}"
    private_dns_zone_ids = [azurerm_private_dns_zone.static_web_app.id]
  }

  tags = local.tags
}
