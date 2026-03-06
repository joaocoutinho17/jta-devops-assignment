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
