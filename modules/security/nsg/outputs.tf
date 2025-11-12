# NSG Module Outputs

# ========================================
# NSG Outputs
# ========================================

output "nsg_id" {
  description = "The ID of the Network Security Group"
  value       = azurerm_network_security_group.this.id
}

output "nsg_name" {
  description = "The name of the Network Security Group"
  value       = azurerm_network_security_group.this.name
}

output "nsg_location" {
  description = "The location of the Network Security Group"
  value       = azurerm_network_security_group.this.location
}

output "nsg_resource_group_name" {
  description = "The resource group name of the Network Security Group"
  value       = azurerm_network_security_group.this.resource_group_name
}

# ========================================
# Security Rules Outputs
# ========================================

output "inbound_rules" {
  description = "Map of inbound security rules"
  value = {
    for rule in azurerm_network_security_rule.inbound : 
    rule.name => {
      priority                = rule.priority
      access                  = rule.access
      protocol                = rule.protocol
      source_port_range       = rule.source_port_range
      destination_port_range  = rule.destination_port_range
      source_address_prefix   = rule.source_address_prefix
      destination_address_prefix = rule.destination_address_prefix
    }
  }
}

output "outbound_rules" {
  description = "Map of outbound security rules"
  value = {
    for rule in azurerm_network_security_rule.outbound : 
    rule.name => {
      priority                = rule.priority
      access                  = rule.access
      protocol                = rule.protocol
      source_port_range       = rule.source_port_range
      destination_port_range  = rule.destination_port_range
      source_address_prefix   = rule.source_address_prefix
      destination_address_prefix = rule.destination_address_prefix
    }
  }
}

output "inbound_rule_count" {
  description = "Number of inbound security rules"
  value       = length(azurerm_network_security_rule.inbound)
}

output "outbound_rule_count" {
  description = "Number of outbound security rules"
  value       = length(azurerm_network_security_rule.outbound)
}

# ========================================
# Subnet Association Outputs
# ========================================

output "associated_subnet_ids" {
  description = "List of subnet IDs associated with this NSG"
  value       = [for assoc in azurerm_subnet_network_security_group_association.this : assoc.subnet_id]
}

output "subnet_association_count" {
  description = "Number of subnets associated with this NSG"
  value       = length(var.subnet_ids)
}

# ========================================
# Consolidated Output
# ========================================

output "nsg_details" {
  description = "Consolidated NSG details"
  value = {
    id                   = azurerm_network_security_group.this.id
    name                 = azurerm_network_security_group.this.name
    location             = azurerm_network_security_group.this.location
    resource_group_name  = azurerm_network_security_group.this.resource_group_name
    inbound_rule_count   = length(azurerm_network_security_rule.inbound)
    outbound_rule_count  = length(azurerm_network_security_rule.outbound)
    associated_subnets   = length(var.subnet_ids)
  }
}
