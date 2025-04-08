/*
  Management Groups Module
  This module creates the management group hierarchy for the Azure Landing Zone
*/

# Get the tenant root management group
data "azurerm_management_group" "root" {
  name = data.azurerm_client_config.current.tenant_id
}

# Create the Platform management group
resource "azurerm_management_group" "platform" {
  display_name               = "Platform"
  name                       = var.platform_mg_name
  parent_management_group_id = data.azurerm_management_group.root.id

  lifecycle {
    ignore_changes = [
      # Ignore changes to parent_management_group_id after creation
      parent_management_group_id
    ]
  }
}

# Create the Landing Zones management group
resource "azurerm_management_group" "landing_zones" {
  display_name               = "Landing Zones"
  name                       = var.landing_zones_mg_name
  parent_management_group_id = data.azurerm_management_group.root.id

  lifecycle {
    ignore_changes = [
      # Ignore changes to parent_management_group_id after creation
      parent_management_group_id
    ]
  }
}

# Create the Sandbox management group
resource "azurerm_management_group" "sandbox" {
  display_name               = "Sandbox"
  name                       = var.sandbox_mg_name
  parent_management_group_id = data.azurerm_management_group.root.id

  lifecycle {
    ignore_changes = [
      # Ignore changes to parent_management_group_id after creation
      parent_management_group_id
    ]
  }
}

# Create the Decommissioned management group
resource "azurerm_management_group" "decommissioned" {
  display_name               = "Decommissioned"
  name                       = var.decommissioned_mg_name
  parent_management_group_id = data.azurerm_management_group.root.id

  lifecycle {
    ignore_changes = [
      # Ignore changes to parent_management_group_id after creation
      parent_management_group_id
    ]
  }
}

# Create the Corp management group under Landing Zones
resource "azurerm_management_group" "corp" {
  display_name               = "Corp"
  name                       = var.corp_mg_name
  parent_management_group_id = azurerm_management_group.landing_zones.id

  lifecycle {
    ignore_changes = [
      # Ignore changes to parent_management_group_id after creation
      parent_management_group_id
    ]
  }
}

# Create the Online management group under Landing Zones
resource "azurerm_management_group" "online" {
  display_name               = "Online"
  name                       = var.online_mg_name
  parent_management_group_id = azurerm_management_group.landing_zones.id

  lifecycle {
    ignore_changes = [
      # Ignore changes to parent_management_group_id after creation
      parent_management_group_id
    ]
  }
}

# Get current client configuration
data "azurerm_client_config" "current" {}

# Associate subscription with management group if subscription_id is provided
resource "azurerm_management_group_subscription_association" "corp" {
  count               = var.subscription_id != "" ? 1 : 0
  management_group_id = azurerm_management_group.corp.id
  subscription_id     = var.subscription_id
}
