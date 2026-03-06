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

# Private ENdpoint
resource "azurerm_private_endpoint" "sql" {
  name                = "pe-sql-${local.prefix}"
  location            = azurerm_resource_group.apps.location
  resource_group_name = azurerm_resource_group.apps.name
  subnet_id           = azurerm_subnet.backend.id
  tags                = local.tags

  private_service_connection {
    name                           = "psc-sql-${local.prefix}"
    private_connection_resource_id = azurerm_mssql_server.sql.id
    subresource_names              = ["sqlServer"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "dns-group-sql-${local.prefix}"
    private_dns_zone_ids = [azurerm_private_dns_zone.sql.id]
  }
}
