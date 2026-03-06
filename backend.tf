# Service Plan
resource "azurerm_service_plan" "appservice" {
  name                = "asp-${local.prefix}"
  resource_group_name = azurerm_resource_group.apps.name
  location            = azurerm_resource_group.apps.location
  os_type             = "Linux"
  sku_name            = var.app_service_sku_name
  tags                = local.tags
}

# App Service
resource "azurerm_linux_web_app" "appservice" {
  name                = "app-${local.prefix}"
  resource_group_name = azurerm_resource_group.apps.name
  location            = azurerm_resource_group.apps.location
  service_plan_id     = azurerm_service_plan.appservice.id
  tags                = local.tags

  site_config {
    always_on = true #avoid cold starts

    #application_stack #tbd
  }

  #app_settings #database connection tbd

  identity {
    type = "SystemAssigned"
  }

  public_network_access_enabled = false
}

# Vnet integration
resource "azurerm_app_service_virtual_network_swift_connection" "this" {
  app_service_id = azurerm_linux_web_app.appservice.id
  subnet_id      = azurerm_subnet.appservice.id
}
