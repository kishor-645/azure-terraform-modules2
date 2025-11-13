# Network Security Group (NSG) Module
# Creates NSG with dynamic security rules supporting service tags, CIDR ranges, and ASGs

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
# Network Security Group
# ========================================

resource "azurerm_network_security_group" "this" {
  name                = var.nsg_name
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = merge(
    var.tags,
    {
      Purpose = "Network Security"
    }
  )
}

# ========================================
# Security Rules - Inbound
# ========================================

resource "azurerm_network_security_rule" "inbound" {
  for_each = { for rule in var.inbound_rules : rule.name => rule }

  name                         = each.value.name
  priority                     = each.value.priority
  direction                    = "Inbound"
  access                       = each.value.access
  protocol                     = each.value.protocol
  source_port_range            = each.value.source_port_range
  destination_port_range       = each.value.destination_port_range
  source_port_ranges           = each.value.source_port_ranges
  destination_port_ranges      = each.value.destination_port_ranges
  source_address_prefix        = each.value.source_address_prefix
  source_address_prefixes      = each.value.source_address_prefixes
  destination_address_prefix   = each.value.destination_address_prefix
  destination_address_prefixes = each.value.destination_address_prefixes
  description                  = each.value.description

  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.this.name

  # Application Security Groups (optional)
  source_application_security_group_ids      = each.value.source_application_security_group_ids
  destination_application_security_group_ids = each.value.destination_application_security_group_ids
}

# ========================================
# Security Rules - Outbound
# ========================================

resource "azurerm_network_security_rule" "outbound" {
  for_each = { for rule in var.outbound_rules : rule.name => rule }

  name                         = each.value.name
  priority                     = each.value.priority
  direction                    = "Outbound"
  access                       = each.value.access
  protocol                     = each.value.protocol
  source_port_range            = each.value.source_port_range
  destination_port_range       = each.value.destination_port_range
  source_port_ranges           = each.value.source_port_ranges
  destination_port_ranges      = each.value.destination_port_ranges
  source_address_prefix        = each.value.source_address_prefix
  source_address_prefixes      = each.value.source_address_prefixes
  destination_address_prefix   = each.value.destination_address_prefix
  destination_address_prefixes = each.value.destination_address_prefixes
  description                  = each.value.description

  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.this.name

  # Application Security Groups (optional)
  source_application_security_group_ids      = each.value.source_application_security_group_ids
  destination_application_security_group_ids = each.value.destination_application_security_group_ids
}

# ========================================
# Subnet Associations
# ========================================

resource "azurerm_subnet_network_security_group_association" "this" {
  count = length(var.subnet_ids)

  subnet_id                 = var.subnet_ids[count.index]
  network_security_group_id = azurerm_network_security_group.this.id
}

# ========================================
# Diagnostic Settings
# ========================================

resource "azurerm_monitor_diagnostic_setting" "nsg" {
  name                       = "diag-${var.nsg_name}"
  target_resource_id         = azurerm_network_security_group.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "NetworkSecurityGroupEvent"
  }

  enabled_log {
    category = "NetworkSecurityGroupRuleCounter"
  }
}
