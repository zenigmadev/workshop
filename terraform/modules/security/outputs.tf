output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.central.id
}

output "log_analytics_workspace_name" {
  description = "Name of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.central.name
}

output "management_resource_group_name" {
  description = "Name of the management resource group"
  value       = azurerm_resource_group.management.name
}

output "action_group_id" {
  description = "ID of the critical action group"
  value       = azurerm_monitor_action_group.critical.id
}
