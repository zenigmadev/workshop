/*
  Networking Module
  This module creates the hub-spoke network topology for the Azure Landing Zone
*/

# Create resource group for hub network
resource "azurerm_resource_group" "hub_network" {
  name     = "rg-hub-network-${var.environment}"
  location = var.location
  tags     = var.tags
}

# Create resource group for spoke network
resource "azurerm_resource_group" "spoke_network" {
  name     = "rg-spoke-network-${var.environment}"
  location = var.location
  tags     = var.tags
}

# Create hub virtual network
resource "azurerm_virtual_network" "hub" {
  name                = "vnet-hub-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.hub_network.name
  address_space       = ["10.0.0.0/16"]
  tags                = var.tags
}

# Create subnets in hub virtual network
resource "azurerm_subnet" "hub_gateway" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.hub_network.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = ["10.0.0.0/24"]
}

resource "azurerm_subnet" "hub_firewall" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.hub_network.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "hub_bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.hub_network.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_subnet" "hub_shared" {
  name                 = "snet-shared-${var.environment}"
  resource_group_name  = azurerm_resource_group.hub_network.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = ["10.0.3.0/24"]
}

# Create spoke virtual network
resource "azurerm_virtual_network" "spoke" {
  name                = "vnet-spoke-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.spoke_network.name
  address_space       = ["10.1.0.0/16"]
  tags                = var.tags
}

# Create subnets in spoke virtual network
resource "azurerm_subnet" "spoke_app" {
  name                 = "snet-app-${var.environment}"
  resource_group_name  = azurerm_resource_group.spoke_network.name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = ["10.1.0.0/24"]
}

resource "azurerm_subnet" "spoke_db" {
  name                 = "snet-db-${var.environment}"
  resource_group_name  = azurerm_resource_group.spoke_network.name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = ["10.1.1.0/24"]
}

resource "azurerm_subnet" "spoke_aks" {
  name                 = "snet-aks-${var.environment}"
  resource_group_name  = azurerm_resource_group.spoke_network.name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = ["10.1.2.0/24"]
}

resource "azurerm_subnet" "spoke_pe" {
  name                 = "snet-pe-${var.environment}"
  resource_group_name  = azurerm_resource_group.spoke_network.name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = ["10.1.3.0/24"]
}

resource "azurerm_subnet" "spoke_appgw" {
  name                 = "snet-appgw-${var.environment}"
  resource_group_name  = azurerm_resource_group.spoke_network.name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = ["10.1.4.0/24"]
}

# Create network security groups
resource "azurerm_network_security_group" "hub_shared" {
  name                = "nsg-shared-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.hub_network.name
  tags                = var.tags
}

resource "azurerm_network_security_group" "spoke_app" {
  name                = "nsg-app-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.spoke_network.name
  tags                = var.tags
}

resource "azurerm_network_security_group" "spoke_db" {
  name                = "nsg-db-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.spoke_network.name
  tags                = var.tags
}

resource "azurerm_network_security_group" "spoke_aks" {
  name                = "nsg-aks-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.spoke_network.name
  tags                = var.tags
}

resource "azurerm_network_security_group" "spoke_appgw" {
  name                = "nsg-appgw-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.spoke_network.name
  tags                = var.tags
}

# Create NSG rules for Application Gateway
resource "azurerm_network_security_rule" "appgw_allow_http_https" {
  name                        = "Allow-HTTP-HTTPS"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["80", "443"]
  source_address_prefix       = "Internet"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.spoke_network.name
  network_security_group_name = azurerm_network_security_group.spoke_appgw.id
}

resource "azurerm_network_security_rule" "appgw_allow_gateway_manager" {
  name                        = "Allow-GatewayManager"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "65200-65535"
  source_address_prefix       = "GatewayManager"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.spoke_network.name
  network_security_group_name = azurerm_network_security_group.spoke_appgw.id
}

# Associate NSGs with subnets
resource "azurerm_subnet_network_security_group_association" "hub_shared" {
  subnet_id                 = azurerm_subnet.hub_shared.id
  network_security_group_id = azurerm_network_security_group.hub_shared.id
}

resource "azurerm_subnet_network_security_group_association" "spoke_app" {
  subnet_id                 = azurerm_subnet.spoke_app.id
  network_security_group_id = azurerm_network_security_group.spoke_app.id
}

resource "azurerm_subnet_network_security_group_association" "spoke_db" {
  subnet_id                 = azurerm_subnet.spoke_db.id
  network_security_group_id = azurerm_network_security_group.spoke_db.id
}

resource "azurerm_subnet_network_security_group_association" "spoke_aks" {
  subnet_id                 = azurerm_subnet.spoke_aks.id
  network_security_group_id = azurerm_network_security_group.spoke_aks.id
}

resource "azurerm_subnet_network_security_group_association" "spoke_appgw" {
  subnet_id                 = azurerm_subnet.spoke_appgw.id
  network_security_group_id = azurerm_network_security_group.spoke_appgw.id
}

# Create virtual network peering
resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  name                         = "peer-hub-to-spoke"
  resource_group_name          = azurerm_resource_group.hub_network.name
  virtual_network_name         = azurerm_virtual_network.hub.name
  remote_virtual_network_id    = azurerm_virtual_network.spoke.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
}

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                         = "peer-spoke-to-hub"
  resource_group_name          = azurerm_resource_group.spoke_network.name
  virtual_network_name         = azurerm_virtual_network.spoke.name
  remote_virtual_network_id    = azurerm_virtual_network.hub.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  use_remote_gateways          = false # Set to true if you have a gateway in the hub
}

# Create public IP for Azure Firewall
resource "azurerm_public_ip" "firewall" {
  name                = "pip-fw-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.hub_network.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# Create Azure Firewall
resource "azurerm_firewall" "hub" {
  name                = "fw-hub-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.hub_network.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"
  tags                = var.tags

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.hub_firewall.id
    public_ip_address_id = azurerm_public_ip.firewall.id
  }
}

# Create a basic firewall network rule collection
resource "azurerm_firewall_network_rule_collection" "allow_outbound" {
  name                = "allow-outbound"
  azure_firewall_name = azurerm_firewall.hub.name
  resource_group_name = azurerm_resource_group.hub_network.name
  priority            = 100
  action              = "Allow"

  rule {
    name                  = "allow-dns"
    source_addresses      = ["10.0.0.0/8"]
    destination_ports     = ["53"]
    destination_addresses = ["8.8.8.8", "8.8.4.4"]
    protocols             = ["UDP"]
  }

  rule {
    name                  = "allow-http-https"
    source_addresses      = ["10.0.0.0/8"]
    destination_ports     = ["80", "443"]
    destination_addresses = ["*"]
    protocols             = ["TCP"]
  }
}

# Create public IP for Azure Bastion
resource "azurerm_public_ip" "bastion" {
  name                = "pip-bastion-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.hub_network.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# Create Azure Bastion
resource "azurerm_bastion_host" "hub" {
  name                = "bastion-hub-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.hub_network.name
  tags                = var.tags

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.hub_bastion.id
    public_ip_address_id = azurerm_public_ip.bastion.id
  }
}
