# VNet Peering Module Outputs

# ========================================
# Hub to Spoke Peering Outputs
# ========================================

output "hub_to_spoke_peering_id" {
  description = "The ID of the hub-to-spoke peering connection"
  value       = azurerm_virtual_network_peering.hub_to_spoke.id
}

output "hub_to_spoke_peering_name" {
  description = "The name of the hub-to-spoke peering connection"
  value       = azurerm_virtual_network_peering.hub_to_spoke.name
}

# Note: virtual_network_peering_state is not available as an output attribute
# Use Azure Portal or CLI to check peering status

# ========================================
# Spoke to Hub Peering Outputs
# ========================================

output "spoke_to_hub_peering_id" {
  description = "The ID of the spoke-to-hub peering connection"
  value       = azurerm_virtual_network_peering.spoke_to_hub.id
}

output "spoke_to_hub_peering_name" {
  description = "The name of the spoke-to-hub peering connection"
  value       = azurerm_virtual_network_peering.spoke_to_hub.name
}

# Note: virtual_network_peering_state is not available as an output attribute
# Use Azure Portal or CLI to check peering status

# ========================================
# Consolidated Output
# ========================================

output "peering_details" {
  description = "Consolidated details of both peering connections"
  value = {
    hub_to_spoke = {
      id                    = azurerm_virtual_network_peering.hub_to_spoke.id
      name                  = azurerm_virtual_network_peering.hub_to_spoke.name
      allow_gateway_transit = azurerm_virtual_network_peering.hub_to_spoke.allow_gateway_transit
    }
    spoke_to_hub = {
      id                  = azurerm_virtual_network_peering.spoke_to_hub.id
      name                = azurerm_virtual_network_peering.spoke_to_hub.name
      use_remote_gateways = azurerm_virtual_network_peering.spoke_to_hub.use_remote_gateways
    }
  }
}

# Note: Peering state is not available as an attribute
# Peering is considered successful when both resources are created
output "peering_status" {
  description = "Status message indicating peering resources are created"
  value       = "Peering resources created. Check Azure Portal for connection status."
}
