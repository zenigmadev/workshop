output "hub_vnet_id" {
  description = "ID of the hub virtual network"
  value       = azurerm_virtual_network.hub.id
}

output "hub_vnet_name" {
  description = "Name of the hub virtual network"
  value       = azurerm_virtual_network.hub.name
}

output "spoke_vnet_id" {
  description = "ID of the spoke virtual network"
  value       = azurerm_virtual_network.spoke.id
}

output "spoke_vnet_name" {
  description = "Name of the spoke virtual network"
  value       = azurerm_virtual_network.spoke.name
}

output "hub_resource_group_name" {
  description = "Name of the hub network resource group"
  value       = azurerm_resource_group.hub_network.name
}

output "spoke_resource_group_name" {
  description = "Name of the spoke network resource group"
  value       = azurerm_resource_group.spoke_network.name
}

output "aks_subnet_id" {
  description = "ID of the AKS subnet"
  value       = azurerm_subnet.spoke_aks.id
}

output "appgw_subnet_id" {
  description = "ID of the Application Gateway subnet"
  value       = azurerm_subnet.spoke_appgw.id
}

output "firewall_private_ip" {
  description = "Private IP address of the Azure Firewall"
  value       = azurerm_firewall.hub.ip_configuration[0].private_ip_address
}

output "firewall_public_ip" {
  description = "Public IP address of the Azure Firewall"
  value       = azurerm_public_ip.firewall.ip_address
}
