# Azure Bastion Module
# Creates Azure Bastion Standard with native client and IP-based connections

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
# Public IP for Bastion
# ========================================

resource "azurerm_public_ip" "bastion" {
  name                = var.bastion_public_ip_name
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = var.availability_zones

  tags = merge(
    var.tags,
    {
      Purpose = "Azure Bastion"
    }
  )
}

# ========================================
# Azure Bastion Host
# ========================================

resource "azurerm_bastion_host" "this" {
  name                = var.bastion_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.bastion_sku

  # Standard SKU Features
  copy_paste_enabled     = var.copy_paste_enabled
  file_copy_enabled      = var.file_copy_enabled
  ip_connect_enabled     = var.ip_connect_enabled
  scale_units            = var.scale_units
  shareable_link_enabled = var.shareable_link_enabled
  tunneling_enabled      = var.tunneling_enabled

  ip_configuration {
    name                 = "bastion-ipconfig"
    subnet_id            = var.bastion_subnet_id
    public_ip_address_id = azurerm_public_ip.bastion.id
  }

  tags = merge(
    var.tags,
    {
      SKU = var.bastion_sku
    }
  )
}

# ========================================
# Diagnostic Settings (Optional)
# ========================================

# Diagnostic settings - always create when workspace_id is provided
resource "azurerm_monitor_diagnostic_setting" "bastion" {
  name                       = "diag-${var.bastion_name}"
  target_resource_id         = azurerm_bastion_host.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "BastionAuditLogs"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}
