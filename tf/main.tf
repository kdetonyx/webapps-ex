provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-webapp-example"
  location = "West Europe"
}

resource "azurerm_service_plan" "asp" {
  name                = "asp-webapp-example"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = "B1" # Básico para pruebas
}

resource "azurerm_linux_web_app" "webapp" {
  name                = "webapp-${replace(uuid(), "-", "")}" # Nombre único
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_service_plan.asp.location
  service_plan_id     = azurerm_service_plan.asp.id

  site_config {
    application_stack {
      docker_image        = "nginx"
      docker_image_tag    = "latest"
      docker_registry_url = "https://index.docker.io"
    }
  }

  lifecycle {
    ignore_changes = [
      name # Ignora cambios en el nombre generado por uuid()
    ]
  }
}
