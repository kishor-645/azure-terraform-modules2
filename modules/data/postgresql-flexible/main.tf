# PostgreSQL Flexible Server Module
# Creates PostgreSQL v16 with HA, geo-redundant backup, and private endpoint

terraform {
  required_version = ">= 1.10.3"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.51.0"
    }
  }
}

resource "azurerm_postgresql_flexible_server" "this" {
  name                = var.server_name
  resource_group_name = var.resource_group_name
  location            = var.location
  
  version                      = var.postgresql_version
  administrator_login          = var.administrator_login
  administrator_password       = var.administrator_password
  sku_name                     = var.sku_name
  storage_mb                   = var.storage_mb
  storage_tier                 = var.storage_tier
  
  backup_retention_days        = var.backup_retention_days
  geo_redundant_backup_enabled = var.geo_redundant_backup_enabled
  
  high_availability {
    mode                      = var.high_availability_enabled ? "ZoneRedundant" : "Disabled"
    standby_availability_zone = var.high_availability_enabled ? var.standby_availability_zone : null
  }
  
  delegated_subnet_id = var.delegated_subnet_id
  private_dns_zone_id = var.private_dns_zone_id
  
  public_network_access_enabled = false
  
  zone = var.availability_zone
  
  tags = merge(
    var.tags,
    {
      Purpose = "PostgreSQL"
    }
  )
}

resource "azurerm_postgresql_flexible_server_configuration" "max_connections" {
  name      = "max_connections"
  server_id = azurerm_postgresql_flexible_server.this.id
  value     = var.max_connections
}

resource "azurerm_postgresql_flexible_server_configuration" "shared_buffers" {
  name      = "shared_buffers"
  server_id = azurerm_postgresql_flexible_server.this.id
  value     = var.shared_buffers
}

resource "azurerm_postgresql_flexible_server_configuration" "work_mem" {
  name      = "work_mem"
  server_id = azurerm_postgresql_flexible_server.this.id
  value     = var.work_mem
}

resource "azurerm_postgresql_flexible_server_configuration" "maintenance_work_mem" {
  name      = "maintenance_work_mem"
  server_id = azurerm_postgresql_flexible_server.this.id
  value     = var.maintenance_work_mem
}

resource "azurerm_postgresql_flexible_server_database" "databases" {
  for_each = toset(var.databases)
  
  name      = each.value
  server_id = azurerm_postgresql_flexible_server.this.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}

# Diagnostic settings - always create when workspace_id is provided
resource "azurerm_monitor_diagnostic_setting" "postgresql" {
  name                       = "diag-${var.server_name}"
  target_resource_id         = azurerm_postgresql_flexible_server.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  
  enabled_log {
    category = "PostgreSQLLogs"
  }
  
  enabled_metric {
    category = "AllMetrics"
  }
}
