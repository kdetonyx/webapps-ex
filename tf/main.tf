# terraform/main.tf
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0" # Usa la versión 3.x más reciente
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-${var.webapp_name}"
  location = var.location
}

resource "azurerm_service_plan" "asp" {
  name                = "asp-${var.webapp_name}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = "B1" # Básico para pruebas
}

resource "azurerm_linux_web_app" "webapp" {
  name                = var.webapp_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_service_plan.asp.location
  service_plan_id     = azurerm_service_plan.asp.id

  site_config {
    always_on = false # Necesario para planes básicos
    docker_image        = "kdetony/webapp"  # Sin "library/"
    docker_image_tag    = "0.1"          # Usa tu tag correcto
    docker_registry_url = "https://index.docker.io"
  }

  app_settings = {
    DOCKER_REGISTRY_SERVER_USERNAME = var.docker_username
    DOCKER_REGISTRY_SERVER_PASSWORD = var.docker_password
    WEBSITES_PORT = "8888"
    APP_ENV = "production"
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = "false"
    DOCKER_REGISTRY_SERVER_URL          = "https://index.docker.io"
    DOCKER_CUSTOM_IMAGE_NAME            = "docker.io/library/${split(":", var.docker_image)[0]}:${split(":", var.docker_image)[1]}"
  }
}
