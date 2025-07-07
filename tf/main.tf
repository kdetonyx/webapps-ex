provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_service_plan" "asp" {
  name                = var.app_service_plan_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = "P1v2" # Ajusta según necesidades
}

resource "azurerm_linux_web_app" "webapp" {
  name                = var.webapp_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_service_plan.asp.location
  service_plan_id     = azurerm_service_plan.asp.id

  site_config {
    # Configuración específica para contenedores
    application_stack {
      docker_image     = split(":", var.docker_image)[0]
      docker_image_tag = split(":", var.docker_image)[1]
    }
    
    # Agrega esto si usas Docker Hub
    container_registry_use_managed_identity = false
  }

  # URL del registro (Docker Hub)
  app_settings = {
    DOCKER_REGISTRY_SERVER_URL = "https://index.docker.io"
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = "false"
  }
} 
