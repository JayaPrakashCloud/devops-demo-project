variable "web_image" {
  description = "Docker image for the web application"
  type        = string
  default     = "jayaprakashcloud/devops-demo:v3.0"
}

variable "grafana_password" {
  description = "Password for Grafana admin user"
  type        = string
  default     = "admin123"
  sensitive   = true
}
