terraform {
  required_version = ">= 1.3"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0.0"
    }
  }
}

provider "azurerm" {
  features {}
}

variable "docker_image" {
  description = "Docker image to deploy on webapps"
  type        = string
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-webapp-github"
  location = "East US"
}

resource "azurerm_app_service_plan" "asp" {
  name                = "asp-webapp-github"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  sku {
    tier = "Basic"
    size = "B1"
  }
}

resource "random_id" "unique" {
  byte_length = 4
}

resource "azurerm_app_service" "webapp" {
  name                = "webapp-github-${random_id.unique.hex}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  app_service_plan_id = azurerm_app_service_plan.asp.id

  site_config {
    linux_fx_version = "DOCKER|${var.docker_image}"
  }

  app_settings = {
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = "false"
    DOCKER_REGISTRY_SERVER_URL         = "https://index.docker.io"
  }
}
