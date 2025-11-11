# Private DNS Zone Module Outputs

# ========================================
# DNS Zone Outputs
# ========================================

output "dns_zone_id" {
  description = "The ID of the private DNS zone"
  value       = azurerm_private_dns_zone.this.id
}

output "dns_zone_name" {
  description = "The name of the private DNS zone"
  value       = azurerm_private_dns_zone.this.name
}

output "dns_zone_max_number_of_record_sets" {
  description = "Maximum number of record sets in the DNS zone"
  value       = azurerm_private_dns_zone.this.max_number_of_record_sets
}

output "dns_zone_number_of_record_sets" {
  description = "Current number of record sets in the DNS zone"
  value       = azurerm_private_dns_zone.this.number_of_record_sets
}

# ========================================
# VNet Link Outputs
# ========================================

output "vnet_link_ids" {
  description = "List of VNet link IDs"
  value       = [for link in azurerm_private_dns_zone_virtual_network_link.spoke_links : link.id]
}

output "vnet_link_names" {
  description = "List of VNet link names"
  value       = [for link in azurerm_private_dns_zone_virtual_network_link.spoke_links : link.name]
}

output "linked_vnet_count" {
  description = "Number of VNets linked to this DNS zone"
  value       = length(azurerm_private_dns_zone_virtual_network_link.spoke_links)
}

# ========================================
# Consolidated Output
# ========================================

output "dns_zone_details" {
  description = "Consolidated details of the private DNS zone and linked VNets"
  value = {
    dns_zone = {
      id                        = azurerm_private_dns_zone.this.id
      name                      = azurerm_private_dns_zone.this.name
      number_of_record_sets     = azurerm_private_dns_zone.this.number_of_record_sets
      max_number_of_record_sets = azurerm_private_dns_zone.this.max_number_of_record_sets
    }
    vnet_links = [
      for link in azurerm_private_dns_zone_virtual_network_link.spoke_links : {
        id                   = link.id
        name                 = link.name
        virtual_network_id   = link.virtual_network_id
        registration_enabled = link.registration_enabled
      }
    ]
  }
}
