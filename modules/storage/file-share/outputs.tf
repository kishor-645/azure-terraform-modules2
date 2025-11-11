# File Share Module Outputs

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

# ========================================
# File Share Outputs
# ========================================

output "file_share_id" {
  description = "File share ID"
  value       = azurerm_storage_share.this.id
}

output "file_share_name" {
  description = "File share name"
  value       = azurerm_storage_share.this.name
}

output "file_share_url" {
  description = "File share URL"
  value       = azurerm_storage_share.this.url
}

output "file_share_resource_manager_id" {
  description = "File share resource manager ID"
  value       = azurerm_storage_share.this.resource_manager_id
}

# ========================================
# Private Endpoint Outputs
# ========================================

output "private_endpoint_id" {
  description = "Private endpoint ID"
  value       = var.enable_private_endpoint ? azurerm_private_endpoint.this[0].id : null
}

output "private_ip" {
  description = "Private endpoint IP"
  value       = var.enable_private_endpoint ? azurerm_private_endpoint.this[0].private_service_connection[0].private_ip_address : null
}

# ========================================
# Consolidated Output
# ========================================

output "file_share_details" {
  description = "Consolidated file share details"
  value = {
    storage_account_name   = azurerm_storage_account.this.name
    file_share_name        = azurerm_storage_share.this.name
    file_share_url         = azurerm_storage_share.this.url
    quota_gb               = var.file_share_quota_gb
    protocol               = var.enabled_protocol
    access_tier            = var.access_tier
    has_private_endpoint   = var.enable_private_endpoint
  }
}

# ========================================
# Mount Instructions
# ========================================

output "mount_instructions" {
  description = "Mount instructions for the file share"
  value = var.enabled_protocol == "NFS" ? <<-EOT
    ===================================
    NFS 4.1 Mount Instructions
    ===================================
    
    1. Install NFS client:
       sudo apt-get install nfs-common
    
    2. Create mount point:
       sudo mkdir -p /mnt/${var.file_share_name}
    
    3. Mount file share:
       sudo mount -t nfs4 -o sec=sys,vers=4.1,nolock \
         ${azurerm_storage_account.this.name}.file.core.windows.net:/${azurerm_storage_account.this.name}/${var.file_share_name} \
         /mnt/${var.file_share_name}
    
    4. Add to /etc/fstab for persistence:
       ${azurerm_storage_account.this.name}.file.core.windows.net:/${azurerm_storage_account.this.name}/${var.file_share_name} /mnt/${var.file_share_name} nfs4 sec=sys,vers=4.1,nolock 0 0
    
    ===================================
  EOT : "SMB protocol selected. Use Azure Portal for mount instructions."
}
