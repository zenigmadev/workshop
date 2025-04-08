output "aks_id" {
  description = "ID of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.id
}

output "aks_name" {
  description = "Name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.name
}

output "aks_resource_group_name" {
  description = "Name of the AKS resource group"
  value       = azurerm_resource_group.aks.name
}

output "acr_id" {
  description = "ID of the Azure Container Registry"
  value       = azurerm_container_registry.acr.id
}

output "acr_name" {
  description = "Name of the Azure Container Registry"
  value       = azurerm_container_registry.acr.name
}

output "acr_login_server" {
  description = "Login server URL for the Azure Container Registry"
  value       = azurerm_container_registry.acr.login_server
}

output "key_vault_id" {
  description = "ID of the Key Vault"
  value       = azurerm_key_vault.aks.id
}

output "key_vault_name" {
  description = "Name of the Key Vault"
  value       = azurerm_key_vault.aks.name
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = azurerm_key_vault.aks.vault_uri
}

output "appgw_id" {
  description = "ID of the Application Gateway"
  value       = azurerm_application_gateway.main.id
}

output "appgw_name" {
  description = "Name of the Application Gateway"
  value       = azurerm_application_gateway.main.name
}

output "appgw_public_ip" {
  description = "Public IP address of the Application Gateway"
  value       = azurerm_public_ip.appgw.ip_address
}

output "kube_config" {
  description = "Kubernetes configuration"
  value       = azurerm_kubernetes_cluster.main.kube_config_raw
  sensitive   = true
}
