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

# Private Endpoint
resource "azurerm_private_endpoint" "blob" {
  name                = "pe-blob-${local.prefix}"
  location            = azurerm_resource_group.apps.location
  resource_group_name = azurerm_resource_group.apps.name
  subnet_id           = azurerm_subnet.backend.id
  tags                = local.tags

  private_service_connection {
    name                           = "psc-blob-${local.prefix}"
    private_connection_resource_id = azurerm_storage_account.storage.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "dns-group-blob-${local.prefix}"
    private_dns_zone_ids = [azurerm_private_dns_zone.blob.id]
  }
}
