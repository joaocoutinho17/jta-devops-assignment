# Resource Group for apps deployment
resource "azurerm_resource_group" "apps" {
  name     = "rg-${local.prefix}-apps"
  location = var.location
}

# Resource Group for Network configuration
resource "azurerm_resource_group" "networking" {
  name     = "rg-${local.prefix}-networking"
  location = var.location
}

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

# Azure SQL Server
resource "azurerm_mssql_server" "sql" {
  name                         = "sql-${local.prefix}"
  resource_group_name          = azurerm_resource_group.apps.name
  location                     = azurerm_resource_group.apps.location
  version                      = var.sql_server_version
  administrator_login          = var.sql_admin_login
  administrator_login_password = var.sql_admin_password
  tags                         = local.tags

  public_network_access_enabled = false
}

# Azure SQL Database
resource "azurerm_mssql_database" "db" {
  name      = "sqldb-${local.prefix}"
  server_id = azurerm_mssql_server.sql.id
  sku_name  = var.sql_sku_name
  tags      = local.tags

  lifecycle {
    prevent_destroy = true
  }
}

# Storage account
resource "azurerm_storage_account" "storage" {
  name                = "st${replace(local.prefix, "-", "")}"
  resource_group_name = azurerm_resource_group.apps.name
  location            = azurerm_resource_group.apps.location

  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_replication_type

  public_network_access_enabled = false

  shared_access_key_enabled = false

  tags = local.tags
}

# Container

resource "azurerm_storage_container" "uploads" {
  name                  = "uploads"
  storage_account_id    = azurerm_storage_account.storage.id #argument changed in version 4.9.0
  container_access_type = "private"
}

# RBAC permission to access Blob Storage from app service
resource "azurerm_role_assignment" "app_blob_access" {
  scope                = azurerm_storage_account.storage.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_linux_web_app.backend.identity[0].principal_id
}