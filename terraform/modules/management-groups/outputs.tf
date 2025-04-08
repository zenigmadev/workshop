output "platform_mg_id" {
  description = "ID of the Platform management group"
  value       = azurerm_management_group.platform.id
}

output "landing_zones_mg_id" {
  description = "ID of the Landing Zones management group"
  value       = azurerm_management_group.landing_zones.id
}

output "sandbox_mg_id" {
  description = "ID of the Sandbox management group"
  value       = azurerm_management_group.sandbox.id
}

output "decommissioned_mg_id" {
  description = "ID of the Decommissioned management group"
  value       = azurerm_management_group.decommissioned.id
}

output "corp_mg_id" {
  description = "ID of the Corp management group"
  value       = azurerm_management_group.corp.id
}

output "online_mg_id" {
  description = "ID of the Online management group"
  value       = azurerm_management_group.online.id
}
