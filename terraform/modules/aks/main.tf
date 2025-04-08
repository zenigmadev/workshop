/*
  AKS Module
  This module creates Azure Kubernetes Service and related resources for the Landing Zone
*/

# Create resource group for AKS
resource "azurerm_resource_group" "aks" {
  name     = "rg-aks-${var.environment}"
  location = var.location
  tags     = var.tags
}

# Create Azure Container Registry
resource "azurerm_container_registry" "acr" {
  name                = "acr${var.unique_suffix}${var.environment}"
  resource_group_name = azurerm_resource_group.aks.name
  location            = var.location
  sku                 = "Standard"
  admin_enabled       = false
  tags                = var.tags
}

# Create Key Vault for AKS secrets
resource "azurerm_key_vault" "aks" {
  name                        = "kv-aks-${var.unique_suffix}-${var.environment}"
  location                    = var.location
  resource_group_name         = azurerm_resource_group.aks.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false
  sku_name                    = "standard"
  tags                        = var.tags

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get", "List", "Create", "Delete", "Update",
    ]

    secret_permissions = [
      "Get", "List", "Set", "Delete",
    ]

    certificate_permissions = [
      "Get", "List", "Create", "Delete", "Update",
    ]
  }
}

# Create public IP for Application Gateway
resource "azurerm_public_ip" "appgw" {
  name                = "pip-appgw-${var.environment}"
  resource_group_name = var.spoke_resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# Create Application Gateway
resource "azurerm_application_gateway" "main" {
  name                = "appgw-${var.environment}"
  resource_group_name = var.spoke_resource_group_name
  location            = var.location
  tags                = var.tags

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "gateway-ip-configuration"
    subnet_id = var.appgw_subnet_id
  }

  frontend_port {
    name = "http-port"
    port = 80
  }

  frontend_port {
    name = "https-port"
    port = 443
  }

  frontend_ip_configuration {
    name                 = "frontend-ip-configuration"
    public_ip_address_id = azurerm_public_ip.appgw.id
  }

  frontend_ip_configuration {
    name                          = "frontend-ip-configuration-private"
    subnet_id                     = var.appgw_subnet_id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.1.4.10"
  }

  backend_address_pool {
    name = "backend-pool"
  }

  backend_http_settings {
    name                  = "http-setting"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 20
  }

  http_listener {
    name                           = "http-listener"
    frontend_ip_configuration_name = "frontend-ip-configuration"
    frontend_port_name             = "http-port"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "routing-rule"
    rule_type                  = "Basic"
    http_listener_name         = "http-listener"
    backend_address_pool_name  = "backend-pool"
    backend_http_settings_name = "http-setting"
    priority                   = 100
  }

  waf_configuration {
    enabled                  = true
    firewall_mode            = "Prevention"
    rule_set_type            = "OWASP"
    rule_set_version         = "3.2"
    file_upload_limit_mb     = 100
    max_request_body_size_kb = 128
  }
}

# Create AKS cluster
resource "azurerm_kubernetes_cluster" "main" {
  name                = "aks-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.aks.name
  dns_prefix          = "aks-${var.environment}"
  kubernetes_version  = var.kubernetes_version
  tags                = var.tags

  default_node_pool {
    name                = "system"
    vm_size             = "Standard_DS2_v2"
    zones               = ["1", "2", "3"]
    auto_scaling_enabled  = true
    min_count           = 1
    max_count           = 3
    vnet_subnet_id      = var.aks_subnet_id
    node_labels = {
      "nodepool-type" = "system"
      "environment"   = var.environment
    }
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin     = "azure"
    network_policy     = "calico"
    service_cidr       = "10.2.0.0/16"
    dns_service_ip     = "10.2.0.10"
  }

  azure_active_directory_role_based_access_control {
    azure_rbac_enabled = true
    admin_group_object_ids = var.admin_group_object_ids
  }

  oms_agent {
    log_analytics_workspace_id = var.log_analytics_workspace_id
  }

  ingress_application_gateway {
    gateway_id = azurerm_application_gateway.main.id
  }
}

# Create user node pool
resource "azurerm_kubernetes_cluster_node_pool" "user" {
  name                  = "user"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size               = "Standard_DS3_v2"
  zones                 = ["1", "2", "3"]
  auto_scaling_enabled = true
  min_count             = 1
  max_count             = 5
  vnet_subnet_id        = var.aks_subnet_id
  
  node_labels = {
    "nodepool-type" = "user"
    "environment"   = var.environment
  }
  
  tags = var.tags
}

# Grant AKS access to ACR
resource "azurerm_role_assignment" "aks_acr" {
  principal_id                     = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.acr.id
  skip_service_principal_aad_check = true
}

# Get current client configuration
data "azurerm_client_config" "current" {}
