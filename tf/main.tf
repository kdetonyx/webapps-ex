terraform {
  required_version = ">= 1.3"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0.0"
    }
    random = {
      source  = "hashicorp/random"
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
  default     = "kdetony/webapp:0.1"
}

# Obtener el resource group existente
data "azurerm_resource_group" "rg" {
  name = "rg-webapp-github"
}

# Obtener el App Service Plan existente
data "azurerm_app_service_plan" "asp" {
  name                = "asp-webapp-github"
  resource_group_name = data.azurerm_resource_group.rg.name
}

resource "random_id" "unique" {
  byte_length = 4
}

resource "azurerm_app_service" "webapp" {
  name                = "webapp-github-${random_id.unique.hex}"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  app_service_plan_id = data.azurerm_app_service_plan.asp.id

  site_config {
    linux_fx_version = "DOCKER|${var.docker_image}"
    always_on        = false  # Requerido para el plan Free
    
    # Configuraciones adicionales para contenedores
    health_check_path = "/"  # Ruta de health check
    ftps_state        = "Disabled"  # Deshabilitar FTP
  }

  identity {
    type = "SystemAssigned"  # Identidad administrada
  }

  app_settings = {
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = "false"
    DOCKER_REGISTRY_SERVER_URL          = "https://index.docker.io"  # URL correcta
    
    # Configuraciones recomendadas
    WEBSITES_CONTAINER_START_TIME_LIMIT = "600"
    DOCKER_ENABLE_CI                    = "true"
    
    # Si tu imagen es privada, descomenta estas líneas:
    # DOCKER_REGISTRY_SERVER_USERNAME   = "kdetony"
    # DOCKER_REGISTRY_SERVER_PASSWORD   = "@Microsoft.KeyVault(SecretUri=https://kv-name.vault.azure.net/secrets/docker-pwd/version)"
  }

   tags = var.tags

  # Dependencia explícita en el App Service Plan
  depends_on = [data.azurerm_app_service_plan.asp]
}

# Registrar el provider de Microsoft.Web si es necesario
resource "azurerm_resource_provider_registration" "web" {
  name = "Microsoft.Web"
}
