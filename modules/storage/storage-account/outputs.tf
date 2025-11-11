# Storage Account Module Outputs

# ========================================
# Storage Account Outputs
# ========================================

output "storage_account_id" {
  description = "Storage account ID"
  value       = azurerm_storage_account.this.id
}

output "storage_account_name" {
  description = "Storage account name"
  value       = azurerm_storage_account.this.name
}

output "primary_blob_endpoint" {
  description = "Primary blob endpoint"
  value       = azurerm_storage_account.this.primary_blob_endpoint
}

output "primary_file_endpoint" {
  description = "Primary file endpoint"
  value       = azurerm_storage_account.this.primary_file_endpoint
}

output "primary_dfs_endpoint" {
  description = "Primary DFS endpoint (ADLS Gen2)"
  value       = azurerm_storage_account.this.primary_dfs_endpoint
}

output "primary_access_key" {
  description = "Primary access key"
  value       = azurerm_storage_account.this.primary_access_key
  sensitive   = true
}

output "primary_connection_string" {
  description = "Primary connection string"
  value       = azurerm_storage_account.this.primary_connection_string
  sensitive   = true
}

# ========================================
# Private Endpoint Outputs
# ========================================

output "blob_private_endpoint_id" {
  description = "Blob private endpoint ID"
  value       = var.enable_private_endpoint ? azurerm_private_endpoint.blob[0].id : null
}

output "blob_private_ip" {
  description = "Blob private endpoint IP"
  value       = var.enable_private_endpoint ? azurerm_private_endpoint.blob[0].private_service_connection[0].private_ip_address : null
}

output "file_private_endpoint_id" {
  description = "File private endpoint ID"
  value       = var.enable_private_endpoint && var.enable_file_private_endpoint ? azurerm_private_endpoint.file[0].id : null
}

# ========================================
# Consolidated Output
# ========================================

output "storage_account_details" {
  description = "Consolidated storage account details"
  value = {
    id                     = azurerm_storage_account.this.id
    name                   = azurerm_storage_account.this.name
    primary_blob_endpoint  = azurerm_storage_account.this.primary_blob_endpoint
    primary_file_endpoint  = azurerm_storage_account.this.primary_file_endpoint
    primary_dfs_endpoint   = azurerm_storage_account.this.primary_dfs_endpoint
    is_hns_enabled         = var.enable_hierarchical_namespace
    has_private_endpoint   = var.enable_private_endpoint
    replication_type       = var.account_replication_type
  }
}
