# Private DNS Zone Module
# Creates Azure Private DNS zones for private endpoint resolution

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
# Private DNS Zone
# ========================================

resource "azurerm_private_dns_zone" "this" {
  name                = var.dns_zone_name
  resource_group_name = var.resource_group_name

  tags = merge(
    var.tags,
    {
      DNSZoneType = "Private"
      Purpose     = "Private Endpoint Resolution"
    }
  )
}

# ========================================
# VNet Links (Spoke VNets)
# ========================================

# Use count instead of for_each to avoid unknown value issues
resource "azurerm_private_dns_zone_virtual_network_link" "spoke_links" {
  count = length(var.linked_vnet_ids)

  name                  = "link-${replace(basename(var.linked_vnet_ids[count.index]), "/", "-")}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.this.name
  virtual_network_id    = var.linked_vnet_ids[count.index]
  registration_enabled  = var.enable_auto_registration

  tags = var.tags
}
