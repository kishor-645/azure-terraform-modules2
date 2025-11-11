# Route Table (UDR) Module
# Creates route table with user-defined routes for traffic steering

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
# Route Table
# ========================================

resource "azurerm_route_table" "this" {
  name                = var.route_table_name
  location            = var.location
  resource_group_name = var.resource_group_name
  # Note: disable_bgp_route_propagation is not a valid attribute in current azurerm provider
  # BGP route propagation is controlled at the subnet association level if needed

  tags = merge(
    var.tags,
    {
      Purpose = "User Defined Routing"
    }
  )
}

# ========================================
# Routes
# ========================================

resource "azurerm_route" "this" {
  for_each = { for route in var.routes : route.name => route }

  name                   = each.value.name
  resource_group_name    = var.resource_group_name
  route_table_name       = azurerm_route_table.this.name
  address_prefix         = each.value.address_prefix
  next_hop_type          = each.value.next_hop_type
  next_hop_in_ip_address = each.value.next_hop_in_ip_address
}

# ========================================
# Subnet Associations
# ========================================

resource "azurerm_subnet_route_table_association" "this" {
  for_each = toset(var.subnet_ids)

  subnet_id      = each.value
  route_table_id = azurerm_route_table.this.id
}
