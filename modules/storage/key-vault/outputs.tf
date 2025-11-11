# Key Vault Module Outputs

# ========================================
# Key Vault Outputs
# ========================================

output "key_vault_id" {
  description = "Key Vault ID"
  value       = azurerm_key_vault.this.id
}

output "key_vault_name" {
  description = "Key Vault name"
  value       = azurerm_key_vault.this.name
}

output "key_vault_uri" {
  description = "Key Vault URI"
  value       = azurerm_key_vault.this.vault_uri
}

output "key_vault_tenant_id" {
  description = "Key Vault tenant ID"
  value       = azurerm_key_vault.this.tenant_id
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

output "key_vault_details" {
  description = "Consolidated Key Vault details"
  value = {
    id                      = azurerm_key_vault.this.id
    name                    = azurerm_key_vault.this.name
    uri                     = azurerm_key_vault.this.vault_uri
    sku                     = var.sku_name
    rbac_enabled            = var.enable_rbac_authorization
    purge_protection        = var.purge_protection_enabled
    soft_delete_retention   = var.soft_delete_retention_days
    has_private_endpoint    = var.enable_private_endpoint
  }
}

# ========================================
# Usage Instructions
# ========================================

output "usage_instructions" {
  description = "Instructions for using Key Vault with RBAC"
  value = <<-EOT
    ===================================
    Key Vault Usage with RBAC
    ===================================
    
    1. Assign RBAC roles:
       # Key Vault Secrets Officer (manage secrets)
       az role assignment create \
         --role "Key Vault Secrets Officer" \
         --assignee <user-or-sp-object-id> \
         --scope ${azurerm_key_vault.this.id}
       
       # Key Vault Secrets User (read secrets)
       az role assignment create \
         --role "Key Vault Secrets User" \
         --assignee <user-or-sp-object-id> \
         --scope ${azurerm_key_vault.this.id}
    
    2. Create secret:
       az keyvault secret set \
         --vault-name ${var.key_vault_name} \
         --name mysecret \
         --value "my-secret-value"
    
    3. Get secret:
       az keyvault secret show \
         --vault-name ${var.key_vault_name} \
         --name mysecret \
         --query value -o tsv
    
    Vault URI: ${azurerm_key_vault.this.vault_uri}
    RBAC Enabled: ${var.enable_rbac_authorization}
    Private Endpoint: ${var.enable_private_endpoint}
    ===================================
  EOT
}
