variable "project" {
  type        = string
  default     = "jta"
  description = "Name of the project"
}

variable "environment" {
  type        = string
  default     = "dev"
  description = "Name of the environment"
}

variable "resource_group_name_apps" {
  type        = string
  default     = ""
  description = "Name of the azure resource group to deploy apps"
}

variable "resource_group_name_networking" {
  type        = string
  default     = ""
  description = "Name of the azure resource group for network configuration"
}

variable "location" {
  type        = string
  default     = "westeurope"
  description = "Azure region"
}

variable "static_web_app_sku_tier" {
  type        = string
  default     = "Standard"
  description = "Specifies the SKU tier of the Static Web App"
}

variable "static_web_app_sku_size" {
  type        = string
  default     = "Standard"
  description = "Specifies the SKU size of Static Web App"
}

variable "vnet_address_space" {
  type        = string
  default     = "10.0.0.0/16"
  description = "The address space that is used by the virtual network"
}

variable "subnet_frontend_prefixes" {
  type        = string
  default     = "10.0.0.0/24"
  description = "The address prefix to use for the frontend subnet"
}

variable "app_service_sku_name" {
  type        = string
  default     = "B1"
  description = "SKU for the APP Service Plan"
}

variable "subnet_appservice_prefixes" {
  type        = string
  default     = "10.0.0.0/24"
  description = "The address prefix to use for the appservice subnet"
}

variable "sql_server_version" {
  type        = string
  default     = "12.0"
  description = "The version for SQL Server"
}

variable "sql_admin_login" {
  type        = string
  default     = "admin"
  description = "Specifies the admnistrator login name for the SQL Server"
}

variable "sql_admin_password" {
  type        = string
  description = "Specifies the admnistrator login password for the SQL Server"
  sensitive   = true
}

variable "sql_sku_name" {
  type        = string
  default     = "S0"
  description = "Specifies the name of the SKU used by database"
}

variable "subnet_backend_prefixes" {
  type        = string
  default     = "10.0.0.0/24"
  description = "The address prefix to use for the backend subnet"
}

variable "storage_account_tier" {
  type        = string
  default     = "Standard"
  description = "Defines the Tier to use for the storage account"
}

variable "storage_replication_type" {
  type        = string
  default     = "LRS"
  description = "Defines the Tier to use for the storage account"
}

variable "subnet_gateway_prefix" {
  type        = string
  default     = "10.0.0.0/27"
  description = "The address prefix to use for the vpn gateway subnet"
}

variable "vpn_gateway_allocation_method" {
  type        = string
  default     = "Static"
  description = "Defines the allocation method for the IP address"
}

variable "vpn_gateway_sku" {
  type        = string
  default     = "VpnGw1"
  description = "Configuration of the size and capacity of the virtual network gateway"
}
