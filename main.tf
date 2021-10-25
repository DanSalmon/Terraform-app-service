#Creator    :   Dan Salmon

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.46.0"
    }
  }
  backend "remote" {
    organization = "Salmon "

    workspaces {
      name = "Github-actions"
    }
  }
}




# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

# assigns the environment tag to resources
locals {
  common_tags = {
    "Environment" = "${var.environment}"
    "CreatedDate" = timestamp()
    "ModifiedDate" = timestamp()
  }
}

# Creates environment variable for other deployments
variable "environment" {
  type = string
  default = "Production"
  description = "Sets the environment for the resources"
}

variable "location" {
  type = string
  default = "UK South"
  description = "Sets the location for the resources"
}

variable "app-name" {
  type = string
  default = "default"
  description = "Sets the name for the resources"
}

# Creates a resource group based on the environment and resource type being created
resource "azurerm_resource_group" "App-service" {
    name = "${var.environment}-${var.app-name}-App-Service"
    location = "${var.location}"
}

# Create storage account for log analytics
resource "azurerm_storage_account" "storage" {
  name                     = "${var.app-name}-appserviceinsights"
  resource_group_name      = azurerm_resource_group.App-service.name
  location                 = azurerm_resource_group.App-service.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = local.common_tags
}

# Create storage account container for log analytics
resource "azurerm_storage_container" "storage_container" {
  name                  = "${var.app-name}-appserviceinsightsstorage"
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = "private"
}

# App service plan
resource "azurerm_app_service_plan" "App-service-plan" {
  name                = "${var.environment}-${var.app-name}"
  location            = azurerm_resource_group.App-service.location
  resource_group_name = azurerm_resource_group.App-service.name
  kind                = "windows"

  tags = local.common_tags
  sku {
    tier = "Standard"
    size = "S1"
  }
}