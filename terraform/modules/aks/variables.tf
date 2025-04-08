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

variable "unique_suffix" {
  description = "Unique suffix for globally unique resource names"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version for AKS cluster"
  type        = string
  default     = "1.25.5"
}

variable "aks_subnet_id" {
  description = "ID of the AKS subnet"
  type        = string
}

variable "appgw_subnet_id" {
  description = "ID of the Application Gateway subnet"
  type        = string
}

variable "spoke_resource_group_name" {
  description = "Name of the spoke network resource group"
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace"
  type        = string
}

variable "admin_group_object_ids" {
  description = "List of Azure AD group object IDs for AKS admin access"
  type        = list(string)
  default     = []
}
