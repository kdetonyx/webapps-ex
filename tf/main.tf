terraform {
  required_version = ">= 1.3"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0.0"
      configuration_aliases = [azurerm.management]
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0.0"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  
  # Registra automáticamente los proveedores necesarios
  resource_provider_registrations = "Microsoft.Web"
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

resource "azurerm_application_insights" "appinsights" {
  name                = "appi-webapp-${random_id.unique.hex}"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  application_type    = "web"
}

resource "azurerm_app_service" "webapp" {
  name                = "webapp-${random_id.unique.hex}"  # Nombre más corto
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  app_service_plan_id = data.azurerm_app_service_plan.asp.id

  site_config {
    linux_fx_version = "DOCKER|${var.docker_image}"
    always_on        = false
    health_check_path = "/"  # Ruta de health check obligatoria
    
    # Configuración de contenedores
    container_registry_use_managed_identity = true
  }

  identity {
    type = "SystemAssigned"
  }

  app_settings = {
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = "false"
    DOCKER_REGISTRY_SERVER_URL          = "https://index.docker.io"
    APPINSIGHTS_INSTRUMENTATIONKEY      = azurerm_application_insights.appinsights.instrumentation_key
    
    # Configuraciones recomendadas
    WEBSITES_PORT                       = "8080"  # Puerto que usa tu contenedor
    DOCKER_ENABLE_CI                    = "true"
    SCM_DO_BUILD_DURING_DEPLOYMENT      = "false"
  }

  lifecycle {
    ignore_changes = [
      site_config[0].scm_type,  # Ignorar cambios en scm_type
      tags                        # Ignorar cambios en tags
    ]
  }

  tags = var.tags
}

# Crear un rol personalizado si es necesario
resource "azurerm_role_definition" "webapp_role" {
  name        = "WebAppDeploymentRole-${random_id.unique.hex}"
  scope       = data.azurerm_resource_group.rg.id
  description = "Custom role for App Service deployment"

  permissions {
    actions = [
      "Microsoft.Web/sites/*",
      "Microsoft.Insights/components/*",
      "Microsoft.Resources/subscriptions/resourceGroups/read"
    ]
    not_actions = []
  }

  assignable_scopes = [
    data.azurerm_resource_group.rg.id
  ]
}

# Asignar el rol a la entidad de servicio
resource "azurerm_role_assignment" "example" {
  scope              = data.azurerm_resource_group.rg.id
  role_definition_id = azurerm_role_definition.webapp_role.id
  principal_id       = var.service_principal_object_id
}
