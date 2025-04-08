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

variable "hub_vnet_id" {
  description = "ID of the hub virtual network"
  type        = string
}

variable "spoke_vnet_id" {
  description = "ID of the spoke virtual network"
  type        = string
}

variable "admin_email" {
  description = "Email address for alerts"
  type        = string
  default     = "admin@example.com"
}
