variable "resource_group_name" {
  description = "Nombre del Resource Group"
  default     = "rg-webappc"
}

variable "location" {
  description = "Región de Azure"
  default     = "South Central US"
}

variable "app_service_plan_name" {
  description = "Nombre del App Service Plan"
  default     = "asp-webappc"
}

variable "webapp_name" {
  description = "Nombre de la Web App"
  default     = "webappcntnr-20251"
}

variable "docker_image" {
  description = "Imagen de Docker (Docker Hub)"
  default     = "kdetony/webapp:0.1" 
}

variable "docker_username" {
  sensitive = true
}

variable "docker_password" {
  sensitive = true
}
