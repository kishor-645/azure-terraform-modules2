# Route Table Module Outputs

# ========================================
# Route Table Outputs
# ========================================

output "route_table_id" {
  description = "The ID of the route table"
  value       = azurerm_route_table.this.id
}

output "route_table_name" {
  description = "The name of the route table"
  value       = azurerm_route_table.this.name
}

output "route_table_location" {
  description = "The location of the route table"
  value       = azurerm_route_table.this.location
}

output "route_table_resource_group_name" {
  description = "The resource group name of the route table"
  value       = azurerm_route_table.this.resource_group_name
}

output "bgp_route_propagation_disabled" {
  description = "Whether BGP route propagation is disabled"
  value       = null  # disable_bgp_route_propagation not available in current provider
}

# ========================================
# Route Outputs
# ========================================

output "routes" {
  description = "Map of routes in the route table"
  value = {
    for route in azurerm_route.this : 
    route.name => {
      address_prefix         = route.address_prefix
      next_hop_type          = route.next_hop_type
      next_hop_in_ip_address = route.next_hop_in_ip_address
    }
  }
}

output "route_count" {
  description = "Number of routes in the route table"
  value       = length(azurerm_route.this)
}

output "route_names" {
  description = "List of route names"
  value       = [for route in azurerm_route.this : route.name]
}

# ========================================
# Subnet Association Outputs
# ========================================

output "associated_subnet_ids" {
  description = "List of subnet IDs associated with this route table"
  value       = [for assoc in azurerm_subnet_route_table_association.this : assoc.subnet_id]
}

output "subnet_association_count" {
  description = "Number of subnets associated with this route table"
  value       = length(azurerm_subnet_route_table_association.this)
}

# ========================================
# Consolidated Output
# ========================================

output "route_table_details" {
  description = "Consolidated route table details"
  value = {
    id                            = azurerm_route_table.this.id
    name                          = azurerm_route_table.this.name
    location                      = azurerm_route_table.this.location
    resource_group_name           = azurerm_route_table.this.resource_group_name
    bgp_route_propagation_disabled = null  # Not available in current provider
    route_count                   = length(azurerm_route.this)
    associated_subnets            = length(azurerm_subnet_route_table_association.this)
  }
}
