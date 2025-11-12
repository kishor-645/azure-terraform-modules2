# VNet Peering Module
# Creates bidirectional hub-spoke VNet peering

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
# Local Variables
# ========================================

locals {
  # Auto-generate peering names if not provided
  hub_to_spoke_name = var.hub_to_spoke_peering_name != null ? var.hub_to_spoke_peering_name : "peer-${var.hub_vnet_name}-to-${var.spoke_vnet_name}"
  spoke_to_hub_name = var.spoke_to_hub_peering_name != null ? var.spoke_to_hub_peering_name : "peer-${var.spoke_vnet_name}-to-${var.hub_vnet_name}"
}

# ========================================
# Hub to Spoke Peering
# ========================================

resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  name                         = local.hub_to_spoke_name
  resource_group_name          = var.hub_resource_group_name
  virtual_network_name         = var.hub_vnet_name
  remote_virtual_network_id    = var.spoke_vnet_id

  # Traffic settings
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true

  # Gateway transit disabled - not using VPN Gateway
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

# ========================================
# Spoke to Hub Peering
# ========================================

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                         = local.spoke_to_hub_name
  resource_group_name          = var.spoke_resource_group_name
  virtual_network_name         = var.spoke_vnet_name
  remote_virtual_network_id    = var.hub_vnet_id

  # Traffic settings
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true

  # Gateway transit disabled - not using VPN Gateway
  allow_gateway_transit        = false
  use_remote_gateways          = false

  # Ensure hub peering is created first
  depends_on = [
    azurerm_virtual_network_peering.hub_to_spoke
  ]
}
