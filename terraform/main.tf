# Main Terraform Configuration
# Azure Landing Zone Implementation

# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
  }
  
  # Uncomment this block to use Azure Storage for remote state
  # backend "azurerm" {
  #   resource_group_name  = "rg-terraform-state"
  #   storage_account_name = "tfstate<unique_suffix>"
  #   container_name       = "tfstate"
  #   key                  = "landingzone.tfstate"
  # }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
    key_vault {
      purge_soft_delete_on_destroy = false
    }
  }
}

provider "azuread" {}

# Get current client configuration
data "azurerm_client_config" "current" {}

# Generate a random suffix for globally unique resource names
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# Management Groups Module
module "management_groups" {
  source = "./modules/management-groups"
  
  # Optional: Provide subscription ID to associate with Corp management group
  subscription_id = data.azurerm_client_config.current.subscription_id
}

# Networking Module
module "networking" {
  source = "./modules/networking"
  
  environment = var.environment
  location    = var.location
  tags        = var.tags
}

# Security Module
module "security" {
  source = "./modules/security"
  
  environment    = var.environment
  location       = var.location
  tags           = var.tags
  hub_vnet_id    = module.networking.hub_vnet_id
  spoke_vnet_id  = module.networking.spoke_vnet_id
  admin_email    = var.admin_email
}

# AKS Module
module "aks" {
  source = "./modules/aks"
  
  environment              = var.environment
  location                 = var.location
  tags                     = var.tags
  unique_suffix            = random_string.suffix.result
  kubernetes_version       = var.kubernetes_version
  aks_subnet_id            = module.networking.aks_subnet_id
  appgw_subnet_id          = module.networking.appgw_subnet_id
  spoke_resource_group_name = module.networking.spoke_resource_group_name
  log_analytics_workspace_id = module.security.log_analytics_workspace_id
  admin_group_object_ids   = var.admin_group_object_ids
}
