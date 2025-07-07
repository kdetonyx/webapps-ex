terraform {
  required_version = ">= 1.3"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0.0"
    }
    random = {
      source = "hashicorp/random"
      version = ">= 3.0.0"
    }
  }
}

provider "azurerm" {
  features {}
}

variable "tags" {
  default = {
    source = "Terraform"
    env    = "Dev"
  }
}

variable "docker_image" {
  description = "Docker image to deploy on webapps"
  type        = string
  default     = "kdetony/webapp:0.1"  # Valor por defecto para tu imagen
}

# USAR EL RESOURCE GROUP EXISTENTE (no crear uno nuevo)
data "azurerm_resource_group" "rg" {
  name = "rg-webapp-github"
}

resource "azurerm_app_service_plan" "asp" {
  name                = "asp-webapp-github"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  kind                = "Linux"  # Necesario para contenedores
  reserved            = true     # Necesario para Linux

  sku {
    tier = "Free"
    size = "F1"
  }

  tags = var.tags
}

resource "random_id" "unique" {
  byte_length = 4
}

resource "azurerm_app_service" "webapp" {
  name                = "webapp-github-${random_id.unique.hex}"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  app_service_plan_id = azurerm_app_service_plan.asp.id

  site_config {
    linux_fx_version = "DOCKER|${var.docker_image}"
    always_on        = false  # Requerido para el plan Free
  }

  app_settings = {
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = "false"
    DOCKER_REGISTRY_SERVER_URL          = "https://hub.docker.com/"
    }

  tags = var.tags
}
