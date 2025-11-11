# Azure Firewall Module
# Creates Azure Firewall Premium with comprehensive security rules

terraform {
  required_version = ">= 1.10.3"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.51.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.4"
    }
  }
}

# ========================================
# Public IP Addresses
# ========================================

# Main Firewall Public IP
resource "azurerm_public_ip" "firewall" {
  name                = var.firewall_public_ip_name
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = var.availability_zones

  tags = merge(
    var.tags,
    {
      Purpose = "Azure Firewall"
    }
  )
}

# Management Public IP (required for forced tunneling)
resource "azurerm_public_ip" "firewall_management" {
  name                = var.firewall_management_ip_name
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = var.availability_zones

  tags = merge(
    var.tags,
    {
      Purpose = "Azure Firewall Management"
    }
  )
}

# ========================================
# Azure Firewall
# ========================================

resource "azurerm_firewall" "this" {
  name                = var.firewall_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Premium"
  firewall_policy_id  = azurerm_firewall_policy.this.id
  zones               = var.availability_zones

  # Main IP Configuration
  ip_configuration {
    name                 = "fw-ipconfig"
    subnet_id            = var.firewall_subnet_id
    public_ip_address_id = azurerm_public_ip.firewall.id
  }

  # Management IP Configuration (required for forced tunneling)
  management_ip_configuration {
    name                 = "fw-mgmt-ipconfig"
    subnet_id            = var.firewall_management_subnet_id
    public_ip_address_id = azurerm_public_ip.firewall_management.id
  }

  tags = merge(
    var.tags,
    {
      Tier = "Premium"
    }
  )

  depends_on = [
    azurerm_firewall_policy.this,
    azurerm_firewall_policy_rule_collection_group.dnat,
    azurerm_firewall_policy_rule_collection_group.network,
    azurerm_firewall_policy_rule_collection_group.application
  ]
}

# ========================================
# Diagnostic Settings
# ========================================

# Diagnostic settings - always create when workspace_id is provided
resource "azurerm_monitor_diagnostic_setting" "firewall" {
  name                       = "diag-${var.firewall_name}"
  target_resource_id         = azurerm_firewall.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  # Firewall Logs
  enabled_log {
    category = "AzureFirewallApplicationRule"
  }

  enabled_log {
    category = "AzureFirewallNetworkRule"
  }

  enabled_log {
    category = "AzureFirewallDnsProxy"
  }

  enabled_log {
    category = "AZFWApplicationRule"
  }

  enabled_log {
    category = "AZFWNetworkRule"
  }

  enabled_log {
    category = "AZFWNatRule"
  }

  enabled_log {
    category = "AZFWThreatIntel"
  }

  enabled_log {
    category = "AZFWIdpsSignature"
  }

  enabled_log {
    category = "AZFWDnsQuery"
  }

  enabled_log {
    category = "AZFWFqdnResolveFailure"
  }

  # Metrics
  enabled_metric {
    category = "AllMetrics"
  }
}
