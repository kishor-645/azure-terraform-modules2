# Azure File Share Module
# Creates Premium Azure File Share with NFS 4.1 protocol

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
# Storage Account for File Share
# ========================================

resource "azurerm_storage_account" "this" {
  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Premium"
  account_replication_type = "LRS"
  account_kind             = "FileStorage"
  
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  public_network_access_enabled   = var.public_network_access_enabled
  
  network_rules {
    default_action             = var.default_network_action
    bypass                     = ["AzureServices"]
    virtual_network_subnet_ids = var.allowed_subnet_ids
  }

  tags = merge(
    var.tags,
    {
      Purpose = "PremiumFileShare"
    }
  )
}

# ========================================
# File Share
# ========================================

resource "azurerm_storage_share" "this" {
  name                 = var.file_share_name
  storage_account_name = azurerm_storage_account.this.name
  quota                = var.file_share_quota_gb
  enabled_protocol     = var.enabled_protocol
  
  # Access Tier (for Premium)
  access_tier = var.access_tier

  metadata = var.metadata
}

# ========================================
# Private Endpoint
# ========================================

resource "azurerm_private_endpoint" "this" {
  count = var.enable_private_endpoint ? 1 : 0

  name                = "${var.storage_account_name}-file-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.storage_account_name}-file-psc"
    private_connection_resource_id = azurerm_storage_account.this.id
    subresource_names              = ["file"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "file-dns-zone-group"
    private_dns_zone_ids = var.private_dns_zone_ids
  }

  tags = var.tags
}

# ========================================
# Diagnostic Settings
# ========================================

resource "azurerm_monitor_diagnostic_setting" "file_share" {
  count = var.log_analytics_workspace_id != null ? 1 : 0

  name                       = "diag-${var.storage_account_name}-file"
  target_resource_id         = "${azurerm_storage_account.this.id}/fileServices/default"
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "StorageRead"
  }

  enabled_log {
    category = "StorageWrite"
  }

  enabled_log {
    category = "StorageDelete"
  }

  enabled_metric {
    category = "Transaction"
  }
}
