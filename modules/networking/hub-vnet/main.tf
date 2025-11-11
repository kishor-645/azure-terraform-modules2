# Hub VNet Module
# Only 5 subnets: Firewall, Bastion, FW Management, Shared Services, Private Endpoints

terraform {
  required_version = ">= 1.10.3"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.51.0"
    }
  }
}

# ========================================
# Hub Virtual Network
# ========================================

resource "azurerm_virtual_network" "hub" {
  name                = var.vnet_name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = [var.address_space]

  # DDoS Protection Plan (if provided)
  dynamic "ddos_protection_plan" {
    for_each = var.ddos_protection_plan_id != null ? [1] : []
    content {
      id     = var.ddos_protection_plan_id
      enable = true
    }
  }

  tags = merge(
    var.tags,
    {
      VNetType = "Hub"
      Purpose  = "Shared Services"
    }
  )
}

# ========================================
# Subnets
# ========================================

# 1. Azure Firewall Subnet (must be named exactly "AzureFirewallSubnet")
resource "azurerm_subnet" "firewall" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.firewall_subnet_cidr]
}

# 2. Azure Bastion Subnet (must be named exactly "AzureBastionSubnet")
resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.bastion_subnet_cidr]
}

# 3. Azure Firewall Management Subnet (must be named exactly "AzureFirewallManagementSubnet")
resource "azurerm_subnet" "firewall_management" {
  name                 = "AzureFirewallManagementSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.firewall_mgmt_subnet_cidr]
}

# 4. Shared Services Subnet
resource "azurerm_subnet" "shared_services" {
  name                 = var.shared_services_subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.shared_services_subnet_cidr]
}

# 5. Private Endpoints Subnet
resource "azurerm_subnet" "private_endpoints" {
  name                 = var.private_endpoints_subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.private_endpoints_subnet_cidr]

  # Disable private endpoint network policies
  # policy setting omitted for provider compatibility
}