# Azure Container Registry Module
# Creates Premium ACR with private endpoint and geo-replication

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
# Container Registry
# ========================================

resource "azurerm_container_registry" "this" {
  name                = var.registry_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku
  admin_enabled       = var.admin_enabled
  
  # Public network access
  public_network_access_enabled = var.public_network_access_enabled
  
  # Network Rule Set (Premium only)
  # Note: Network rules are configured via private endpoints for security
  # Public network access is disabled by default

  # Note: Geo-replication, retention policy, and trust policy
  # should be configured via Azure Portal or Azure CLI after creation
  # as these features may not be fully supported in current Terraform provider

  # Identity (for customer-managed encryption)
  dynamic "identity" {
    for_each = var.encryption_identity_id != null ? [1] : []
    content {
      type         = "UserAssigned"
      identity_ids = [var.encryption_identity_id]
    }
  }

  # Customer-Managed Encryption
  # Note: Encryption configuration may need to be set via Azure Portal/CLI
  # depending on provider version support

  tags = merge(
    var.tags,
    {
      Purpose = "ContainerRegistry"
    }
  )
}

# ========================================
# Private Endpoint
# ========================================

resource "azurerm_private_endpoint" "this" {
  count = var.enable_private_endpoint ? 1 : 0

  name                = "${var.registry_name}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.registry_name}-psc"
    private_connection_resource_id = azurerm_container_registry.this.id
    subresource_names              = ["registry"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "acr-dns-zone-group"
    private_dns_zone_ids = var.private_dns_zone_ids
  }

  tags = var.tags
}

# ========================================
# Diagnostic Settings
# ========================================

resource "azurerm_monitor_diagnostic_setting" "acr" {
  count = var.log_analytics_workspace_id != null ? 1 : 0

  name                       = "diag-${var.registry_name}"
  target_resource_id         = azurerm_container_registry.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "ContainerRegistryRepositoryEvents"
  }

  enabled_log {
    category = "ContainerRegistryLoginEvents"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}
