terraform {
  required_version = ">=1.10.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=4.9.0"
    }
  }

  #Poderia omitir e passar os valores no terraform init com "-backend-config=..."
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "jtadevstorage"
    container_name       = "tfstate"
    key                  = "jta.tfstate"
  }
}

provider "azurerm" {
  features {
  }
}