# VNet ---------------------------------------------------------------------------------------------------------
resource "azurerm_virtual_network" "this" {
  name                = "vnet-${local.prefix}"
  location            = azurerm_resource_group.networking.location
  resource_group_name = azurerm_resource_group.networking.name
  address_space       = [var.vnet_address_space]
}

# Subnets ---------------------------------------------------------------------------------------------------------
# Subnet VPN Gateway
resource "azurerm_subnet" "gateway" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.networking.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.subnet_gateway_prefix]
}

# Subnet Static Web App
resource "azurerm_subnet" "frontend" {
  name                 = "snet-frontend-${local.prefix}"
  resource_group_name  = azurerm_resource_group.networking.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.subnet_frontend_prefixes]
}

# Subnet App Service 
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/app_service_virtual_network_swift_connection
resource "azurerm_subnet" "appservice" {
  name                 = "snet-appservice-${local.prefix}"
  resource_group_name  = azurerm_resource_group.networking.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.subnet_appservice_prefixes]

  delegation {
    name = "appservice-delegation"

    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

# Subnet Backend
resource "azurerm_subnet" "backend" {
  name                 = "snet-backend-${local.prefix}"
  resource_group_name  = azurerm_resource_group.networking.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.subnet_backend_prefixes]
}


# NSG ---------------------------------------------------------------------------------------------------------
resource "azurerm_network_security_group" "backend" {
  name                = "nsg-backend-${local.prefix}"
  location            = azurerm_resource_group.networking.location
  resource_group_name = azurerm_resource_group.networking.name
  tags                = local.tags

  security_rule {
    name                       = "Allow-Inbound-AppService"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["443", "1433"]
    source_address_prefix      = var.subnet_appservice_prefixes
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Deny-All-Inbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# NSG association 
resource "azurerm_subnet_network_security_group_association" "backend" {
  subnet_id                 = azurerm_subnet.backend.id
  network_security_group_id = azurerm_network_security_group.backend.id
}

# VPN Gateway ---------------------------------------------------------------------------------------------------------
# https://registry.terraform.io/providers/hashicorp/Azurerm/latest/docs/resources/virtual_network_gateway
resource "azurerm_public_ip" "vpn_gateway" {
  name                = "pip-vpngw-${local.prefix}"
  location            = azurerm_resource_group.networking.location
  resource_group_name = azurerm_resource_group.networking.name
  allocation_method   = var.vpn_gateway_allocation_method
  tags                = local.tags
}

resource "azurerm_virtual_network_gateway" "vpn" {
  name                = "vpngw-${local.prefix}"
  location            = azurerm_resource_group.networking.location
  resource_group_name = azurerm_resource_group.networking.name
  type                = "Vpn"
  vpn_type            = "RouteBased"
  sku                 = var.vpn_gateway_sku
  tags                = local.tags

  ip_configuration {
    name                          = "vpngw-ipconfig"
    public_ip_address_id          = azurerm_public_ip.vpn_gateway.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.gateway.id
  }
}

# Private Endpoint and VNet Integration -----------------------------------
# Private Endpoint frontend (azure static web app)
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

# Private ENdpoint Sql
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

# Vnet integration
resource "azurerm_app_service_virtual_network_swift_connection" "this" {
  app_service_id = azurerm_linux_web_app.appservice.id
  subnet_id      = azurerm_subnet.appservice.id
}

# Private DNS Zone ----------------------------------------------------------------------
# Private DNS Zone Static Web App
resource "azurerm_private_dns_zone" "static_web_app" {
  name                = "privatelink.azurestaticapps.net"
  resource_group_name = azurerm_resource_group.networking.name
  tags                = local.tags
}

# Private DNS Zone SQL
resource "azurerm_private_dns_zone" "sql" {
  name                = "privatelink.database.windows.net"
  resource_group_name = azurerm_resource_group.networking.name
  tags                = local.tags
}

# Private DNS Zone Blob Storage
resource "azurerm_private_dns_zone" "blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.networking.name
  tags                = local.tags
}

# Vnet link to private dns zone ----------------------------------------------------------------------
# Vnet link to private dns zone Static Web App
resource "azurerm_private_dns_zone_virtual_network_link" "static_web_app" {
  name                  = "dns-link-stapp-${local.prefix}"
  resource_group_name   = azurerm_resource_group.networking.name
  private_dns_zone_name = azurerm_private_dns_zone.static_web_app.name
  virtual_network_id    = azurerm_virtual_network.this.id
  tags                  = local.tags
}

# Vnet link to private dns zone SQl
resource "azurerm_private_dns_zone_virtual_network_link" "sql" {
  name                  = "dns-link-sql-${local.prefix}"
  resource_group_name   = azurerm_resource_group.networking.name
  private_dns_zone_name = azurerm_private_dns_zone.sql.name
  virtual_network_id    = azurerm_virtual_network.this.id
  registration_enabled  = false
  tags                  = local.tags
}

# Vnet link to private dns zone Blob Storage
resource "azurerm_private_dns_zone_virtual_network_link" "blob" {
  name                  = "dns-link-blob-${local.prefix}"
  resource_group_name   = azurerm_resource_group.networking.name
  private_dns_zone_name = azurerm_private_dns_zone.blob.name
  virtual_network_id    = azurerm_virtual_network.this.id
  registration_enabled  = false
  tags                  = local.tags
}