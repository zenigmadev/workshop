output "management_groups_platform_id" {
  description = "ID of the Platform management group"
  value       = module.management_groups.platform_mg_id
}

output "management_groups_landing_zones_id" {
  description = "ID of the Landing Zones management group"
  value       = module.management_groups.landing_zones_mg_id
}

output "management_groups_corp_id" {
  description = "ID of the Corp management group"
  value       = module.management_groups.corp_mg_id
}

output "hub_vnet_id" {
  description = "ID of the hub virtual network"
  value       = module.networking.hub_vnet_id
}

output "spoke_vnet_id" {
  description = "ID of the spoke virtual network"
  value       = module.networking.spoke_vnet_id
}

output "aks_subnet_id" {
  description = "ID of the AKS subnet"
  value       = module.networking.aks_subnet_id
}

output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace"
  value       = module.security.log_analytics_workspace_id
}

output "aks_id" {
  description = "ID of the AKS cluster"
  value       = module.aks.aks_id
}

output "acr_login_server" {
  description = "Login server URL for the Azure Container Registry"
  value       = module.aks.acr_login_server
}

output "appgw_public_ip" {
  description = "Public IP address of the Application Gateway"
  value       = module.aks.appgw_public_ip
}

output "kube_config" {
  description = "Kubernetes configuration"
  value       = module.aks.kube_config
  sensitive   = true
}
