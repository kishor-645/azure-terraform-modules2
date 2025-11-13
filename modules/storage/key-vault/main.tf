# Azure Key Vault Module
# Creates Key Vault with RBAC authorization and private endpoint

terraform {
  required_version = ">= 1.10.3"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.51.0"
    }
  }
}

data "azurerm_client_config" "current" {}

# ========================================
# Key Vault
# ========================================

resource "azurerm_key_vault" "this" {
  name                = var.key_vault_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = var.sku_name

  # Security
  enabled_for_deployment          = var.enabled_for_deployment
  enabled_for_disk_encryption     = var.enabled_for_disk_encryption
  enabled_for_template_deployment = var.enabled_for_template_deployment
  rbac_authorization_enabled      = var.enable_rbac_authorization
  purge_protection_enabled        = var.purge_protection_enabled
  soft_delete_retention_days      = var.soft_delete_retention_days

  # Public network access
  public_network_access_enabled = var.public_network_access_enabled

  # Network ACLs
  network_acls {
    bypass                     = var.network_acls_bypass
    default_action             = var.network_acls_default_action
    ip_rules                   = var.allowed_ip_ranges
    virtual_network_subnet_ids = var.allowed_subnet_ids
  }

  tags = merge(
    var.tags,
    {
      Purpose = "KeyVault"
    }
  )
}

# ========================================
# Private Endpoint
# ========================================

resource "azurerm_private_endpoint" "this" {
  count = var.enable_private_endpoint ? 1 : 0

  name                = "${var.key_vault_name}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.key_vault_name}-psc"
    private_connection_resource_id = azurerm_key_vault.this.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "keyvault-dns-zone-group"
    private_dns_zone_ids = var.private_dns_zone_ids
  }

  tags = var.tags
}

# ========================================
# Diagnostic Settings
# ========================================

# Diagnostic settings - always create when workspace_id is provided
resource "azurerm_monitor_diagnostic_setting" "key_vault" {
  name                       = "diag-${var.key_vault_name}"
  target_resource_id         = azurerm_key_vault.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "AuditEvent"
  }

  enabled_log {
    category = "AzurePolicyEvaluationDetails"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}
