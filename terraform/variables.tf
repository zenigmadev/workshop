variable "environment" {
  description = "Environment name (dev, test, prod)"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus2"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {
    Environment = "Development"
    Project     = "Azure Landing Zone"
    Owner       = "DevOps Team"
  }
}

variable "admin_email" {
  description = "Email address for alerts"
  type        = string
  default     = "admin@example.com"
}

variable "kubernetes_version" {
  description = "Kubernetes version for AKS cluster"
  type        = string
  default     = "1.25.5"
}

variable "admin_group_object_ids" {
  description = "List of Azure AD group object IDs for AKS admin access"
  type        = list(string)
  default     = []
}
