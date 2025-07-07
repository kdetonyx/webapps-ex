terraform {
  required_version = ">= 1.3"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.87.0"  
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0.0"
    }
  }
}

provider "azurerm" {
  features {}
  # Si usas azurerm < 3.87.0, comenta esta línea
  # resource_provider_registrations = "all"
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

variable "service_principal_object_id" {
  description = "Object ID of the Azure Service Principal"
  type        = string
}

# Obtener recursos existentes
data "azurerm_resource_group" "rg" {
  name = "rg-webapp-github"
}

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

resource "azurerm_linux_web_app" "webapp" {
  name                = "webapp-${random_id.unique.hex}"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  service_plan_id     = data.azurerm_app_service_plan.asp.id

  site_config {
    application_stack {
      docker_image     = var.docker_image
      docker_image_tag = "latest"
    }

    always_on         = true
    health_check_path = "/"
    ftps_state        = "Disabled"
  }

  identity {
    type = "SystemAssigned"
  }

  app_settings = {
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = "false"
    DOCKER_REGISTRY_SERVER_URL          = "https://index.docker.io"
    APPINSIGHTS_INSTRUMENTATIONKEY      = azurerm_application_insights.appinsights.instrumentation_key
    WEBSITES_PORT                       = "8080"
    DOCKER_ENABLE_CI                    = "true"
    SCM_DO_BUILD_DURING_DEPLOYMENT     = "false"
  }

  lifecycle {
    ignore_changes = [
      site_config[0].scm_type,
      tags
    ]
  }

  tags = var.tags
}

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

resource "azurerm_role_assignment" "example" {
  scope              = data.azurerm_resource_group.rg.id
  role_definition_id = azurerm_role_definition.webapp_role.id
  principal_id       = var.service_principal_object_id
}
