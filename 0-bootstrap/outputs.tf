# Bootstrap Outputs
# These values are needed for configuring backend in deployments

# ========================================
# Storage Account Outputs (Terraform State)
# ========================================

output "tfstate_storage_account_name" {
  description = "Terraform state storage account name"
  value       = azurerm_storage_account.tfstate.name
}

output "tfstate_resource_group_name" {
  description = "Terraform state resource group name"
  value       = azurerm_resource_group.terraform_state.name
}

output "tfstate_container_name" {
  description = "Name of the storage container for Terraform state files"
  value       = azurerm_storage_container.tfstate.name
}

output "tfstate_primary_blob_endpoint" {
  description = "Primary blob endpoint for state storage"
  value       = azurerm_storage_account.tfstate.primary_blob_endpoint
}

# ========================================
# Key Vault Outputs
# ========================================

output "key_vault_name" {
  description = "Key Vault name"
  value       = azurerm_key_vault.main.name
}

output "key_vault_id" {
  description = "Key Vault ID"
  value       = azurerm_key_vault.main.id
}

output "key_vault_uri" {
  description = "Key Vault URI"
  value       = azurerm_key_vault.main.vault_uri
}

# ========================================
# DDoS Protection Plan Output
# ========================================

output "ddos_protection_plan_id" {
  description = "ID of the DDoS Protection Plan (if enabled)"
  value       = var.enable_ddos_protection ? azurerm_network_ddos_protection_plan.main[0].id : null
}

# ========================================
# Backend Configuration Examples
# ========================================

output "backend_config_dev" {
  description = "Example backend configuration for Dev environment"
  value       = <<-EOT
    # Add to environments/canada-central/dev/backend.tf:

    terraform {
      backend "azurerm" {
        resource_group_name  = "${azurerm_resource_group.terraform_state.name}"
        storage_account_name = "${azurerm_storage_account.tfstate.name}"
        container_name       = "${azurerm_storage_container.tfstate.name}"
        key                  = "canadacentral-dev.terraform.tfstate"
      }
    }
  EOT
}

output "backend_config_prod" {
  description = "Example backend configuration for Prod environment"
  value       = <<-EOT
    # Add to environments/canada-central/prod/backend.tf:

    terraform {
      backend "azurerm" {
        resource_group_name  = "${azurerm_resource_group.terraform_state.name}"
        storage_account_name = "${azurerm_storage_account.tfstate.name}"
        container_name       = "${azurerm_storage_container.tfstate.name}"
        key                  = "canadacentral-prod.terraform.tfstate"
      }
    }
  EOT
}

# ========================================
# Summary Output
# ========================================

output "bootstrap_summary" {
  description = "Summary of bootstrap infrastructure"
  value       = <<-EOT
    ====================================
    Bootstrap Infrastructure Summary
    ====================================

    Region: Canada Central

    Resources created:
    - Terraform state storage account: ${azurerm_storage_account.tfstate.name}
    - Key Vault for secrets: ${azurerm_key_vault.main.name}
    - DDoS Protection Plan: ${var.enable_ddos_protection ? "Enabled" : "Disabled"}

    Next Steps:
    1. Note storage account name: ${azurerm_storage_account.tfstate.name}
    2. Configure backend.tf in environments (see backend_config_* outputs)
    3. Store sensitive values in Key Vault: ${azurerm_key_vault.main.name}
    4. Proceed with infrastructure deployment

    ====================================
  EOT
}
