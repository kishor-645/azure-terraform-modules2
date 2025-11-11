# Hub VNet Module Outputs

# ========================================
# VNet Outputs
# ========================================

output "vnet_id" {
  description = "The ID of the hub virtual network"
  value       = azurerm_virtual_network.hub.id
}

output "vnet_name" {
  description = "The name of the hub virtual network"
  value       = azurerm_virtual_network.hub.name
}

output "vnet_address_space" {
  description = "The address space of the hub virtual network"
  value       = azurerm_virtual_network.hub.address_space
}

output "vnet_location" {
  description = "The location of the hub virtual network"
  value       = azurerm_virtual_network.hub.location
}

output "resource_group_name" {
  description = "The resource group name of the hub virtual network"
  value       = azurerm_virtual_network.hub.resource_group_name
}

# ========================================
# Subnet Outputs - IDs
# ========================================

output "firewall_subnet_id" {
  description = "The ID of the Azure Firewall subnet"
  value       = azurerm_subnet.firewall.id
}

output "bastion_subnet_id" {
  description = "The ID of the Azure Bastion subnet"
  value       = azurerm_subnet.bastion.id
}

output "firewall_management_subnet_id" {
  description = "The ID of the Azure Firewall Management subnet"
  value       = azurerm_subnet.firewall_management.id
}

output "shared_services_subnet_id" {
  description = "The ID of the shared services subnet"
  value       = azurerm_subnet.shared_services.id
}

output "private_endpoints_subnet_id" {
  description = "The ID of the private endpoints subnet"
  value       = azurerm_subnet.private_endpoints.id
}

# Note: Jumpbox subnet is in spoke VNet, not hub VNet

# ========================================
# Subnet Outputs - Names
# ========================================

output "subnet_names" {
  description = "Map of subnet names"
  value = {
    firewall            = azurerm_subnet.firewall.name
    bastion             = azurerm_subnet.bastion.name
    firewall_management = azurerm_subnet.firewall_management.name
    shared_services     = azurerm_subnet.shared_services.name
    private_endpoints   = azurerm_subnet.private_endpoints.name
  }
}

# ========================================
# Subnet Outputs - Address Prefixes
# ========================================

output "subnet_address_prefixes" {
  description = "Map of subnet address prefixes"
  value = {
    firewall            = azurerm_subnet.firewall.address_prefixes[0]
    bastion             = azurerm_subnet.bastion.address_prefixes[0]
    firewall_management = azurerm_subnet.firewall_management.address_prefixes[0]
    shared_services     = azurerm_subnet.shared_services.address_prefixes[0]
    private_endpoints   = azurerm_subnet.private_endpoints.address_prefixes[0]
  }
}

# ========================================
# Consolidated Output
# ========================================

output "hub_vnet_details" {
  description = "Consolidated details of the hub VNet and all subnets"
  value = {
    vnet = {
      id            = azurerm_virtual_network.hub.id
      name          = azurerm_virtual_network.hub.name
      address_space = azurerm_virtual_network.hub.address_space
      location      = azurerm_virtual_network.hub.location
    }
    subnets = {
      firewall = {
        id             = azurerm_subnet.firewall.id
        name           = azurerm_subnet.firewall.name
        address_prefix = azurerm_subnet.firewall.address_prefixes[0]
      }
      bastion = {
        id             = azurerm_subnet.bastion.id
        name           = azurerm_subnet.bastion.name
        address_prefix = azurerm_subnet.bastion.address_prefixes[0]
      }
      firewall_management = {
        id             = azurerm_subnet.firewall_management.id
        name           = azurerm_subnet.firewall_management.name
        address_prefix = azurerm_subnet.firewall_management.address_prefixes[0]
      }
      shared_services = {
        id             = azurerm_subnet.shared_services.id
        name           = azurerm_subnet.shared_services.name
        address_prefix = azurerm_subnet.shared_services.address_prefixes[0]
      }
      private_endpoints = {
        id             = azurerm_subnet.private_endpoints.id
        name           = azurerm_subnet.private_endpoints.name
        address_prefix = azurerm_subnet.private_endpoints.address_prefixes[0]
      }
    }
  }
}
