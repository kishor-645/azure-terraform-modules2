# Spoke VNet Module Outputs

# ========================================
# VNet Outputs
# ========================================

output "vnet_id" {
  description = "The ID of the spoke virtual network"
  value       = azurerm_virtual_network.spoke.id
}

output "vnet_name" {
  description = "The name of the spoke virtual network"
  value       = azurerm_virtual_network.spoke.name
}

output "vnet_address_space" {
  description = "The address space of the spoke virtual network"
  value       = azurerm_virtual_network.spoke.address_space
}

output "vnet_location" {
  description = "The location of the spoke virtual network"
  value       = azurerm_virtual_network.spoke.location
}

output "resource_group_name" {
  description = "The resource group name of the spoke virtual network"
  value       = azurerm_virtual_network.spoke.resource_group_name
}

# ========================================
# Subnet Outputs - IDs
# ========================================

output "subnet_ids" {
  description = "Map of subnet IDs keyed by logical subnet key"
  value       = { for k, s in azurerm_subnet.spoke : k => s.id }
}

# Legacy outputs for backward compatibility (deprecated - prefer subnet_ids)
output "aks_system_subnet_id" {
  description = "[DEPRECATED] Same as aks_node_pool_subnet_id"
  value       = try(azurerm_subnet.spoke["aks_nodes"].id, null)
}

output "aks_user_subnet_id" {
  description = "[DEPRECATED] Same as aks_node_pool_subnet_id"
  value       = try(azurerm_subnet.spoke["aks_nodes"].id, null)
}

output "aks_node_pool_subnet_id" {
  description = "The ID of the shared AKS node pool subnet (used by both system and user node pools) if present"
  value       = try(azurerm_subnet.spoke["aks_nodes"].id, null)
}

output "private_endpoints_subnet_id" {
  description = "The ID of the private endpoints subnet if present"
  value       = try(azurerm_subnet.spoke["private_endpoints"].id, null)
}

output "jumpbox_subnet_id" {
  description = "The ID of the jumpbox subnet if present"
  value       = try(azurerm_subnet.spoke["jumpbox"].id, null)
}

# ========================================
# Subnet Outputs - Names
# ========================================

output "subnet_names" {
  description = "Map of subnet names keyed by logical subnet key"
  value       = { for k, s in azurerm_subnet.spoke : k => s.name }
}

# ========================================
# Subnet Outputs - Address Prefixes
# ========================================

output "subnet_address_prefixes" {
  description = "Map of subnet primary address prefix keyed by logical subnet key"
  value       = { for k, s in azurerm_subnet.spoke : k => s.address_prefixes[0] }
}

# ========================================
# Consolidated Output
# ========================================

output "spoke_vnet_details" {
  description = "Consolidated details of the spoke VNet and all subnets"
  value = {
    vnet = {
      id            = azurerm_virtual_network.spoke.id
      name          = azurerm_virtual_network.spoke.name
      address_space = azurerm_virtual_network.spoke.address_space
      location      = azurerm_virtual_network.spoke.location
    }
    subnets = { for k, s in azurerm_subnet.spoke :
      k => {
        id             = s.id
        name           = s.name
        address_prefix = s.address_prefixes[0]
      } }
  }
}
