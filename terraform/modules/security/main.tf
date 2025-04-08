/*
  Security Module
  This module creates security and governance components for the Azure Landing Zone
*/

# Create resource group for management resources
resource "azurerm_resource_group" "management" {
  name     = "rg-management-${var.environment}"
  location = var.location
  tags     = var.tags
}

# Create Log Analytics workspace
resource "azurerm_log_analytics_workspace" "central" {
  name                = "law-central-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.management.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

# Enable Microsoft Defender for Cloud
resource "azurerm_security_center_subscription_pricing" "defender_for_servers" {
  tier          = "Standard"
  resource_type = "VirtualMachines"
}

resource "azurerm_security_center_subscription_pricing" "defender_for_storage" {
  tier          = "Standard"
  resource_type = "StorageAccounts"
}

resource "azurerm_security_center_subscription_pricing" "defender_for_kubernetes" {
  tier          = "Standard"
  resource_type = "KubernetesService"
}

# Configure Security Center to send data to Log Analytics
resource "azurerm_security_center_workspace" "central" {
  scope        = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
  workspace_id = azurerm_log_analytics_workspace.central.id
}

# Create Azure Policy assignment for requiring tags
resource "azurerm_subscription_policy_assignment" "require_environment_tag" {
  name                 = "require-environment-tag"
  subscription_id      = data.azurerm_client_config.current.subscription_id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/871b6d14-10aa-478d-b590-94f262ecfa99" # Built-in policy for requiring a tag
  description          = "Requires Environment tag on all resources"
  display_name         = "Require Environment tag on resources"

  parameters = <<PARAMETERS
  {
    "tagName": {
      "value": "Environment"
    }
  }
  PARAMETERS
}

# Create Azure Policy assignment for allowed locations
resource "azurerm_subscription_policy_assignment" "allowed_locations" {
  name                 = "allowed-locations"
  subscription_id      = data.azurerm_client_config.current.subscription_id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c" # Built-in policy for allowed locations
  description          = "Restricts deployments to approved regions"
  display_name         = "Allowed locations"

  parameters = <<PARAMETERS
  {
    "listOfAllowedLocations": {
      "value": ["${var.location}"]
    }
  }
  PARAMETERS
}

# Create diagnostic settings for virtual networks
resource "azurerm_monitor_diagnostic_setting" "hub_vnet" {
  name                       = "diag-vnet-hub-to-law"
  target_resource_id         = var.hub_vnet_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.central.id

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

resource "azurerm_monitor_diagnostic_setting" "spoke_vnet" {
  name                       = "diag-vnet-spoke-to-law"
  target_resource_id         = var.spoke_vnet_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.central.id

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# Create action group for alerts
resource "azurerm_monitor_action_group" "critical" {
  name                = "ag-critical-${var.environment}"
  resource_group_name = azurerm_resource_group.management.name
  short_name          = "Critical"

  email_receiver {
    name                    = "admin"
    email_address           = var.admin_email
    use_common_alert_schema = true
  }
}

# Create alert for high CPU usage
resource "azurerm_monitor_metric_alert" "high_cpu" {
  name                = "alert-high-cpu-${var.environment}"
  resource_group_name = azurerm_resource_group.management.name
  scopes              = ["/subscriptions/${data.azurerm_client_config.current.subscription_id}"]
  description         = "Alert when CPU usage is high"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 90
  }

  action {
    action_group_id = azurerm_monitor_action_group.critical.id
  }
}

# Get current client configuration
data "azurerm_client_config" "current" {}
