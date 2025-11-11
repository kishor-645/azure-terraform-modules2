# Bootstrap Outputs
# These values are needed for configuring backend in regional deployments

# ========================================
# Storage Account Outputs (Terraform State)
# ========================================

output "tfstate_storage_accounts" {
  description = "Map of Terraform state storage account names per region"
  value = {
    for region, sa in azurerm_storage_account.tfstate : region => {
      name                = sa.name
      resource_group_name = sa.resource_group_name
      location            = sa.location
      primary_blob_endpoint = sa.primary_blob_endpoint
    }
  }
}

output "tfstate_container_name" {
  description = "Name of the storage container for Terraform state files"
  value       = "tfstate"
}

# ========================================
# Key Vault Outputs
# ========================================

output "key_vaults" {
  description = "Map of Key Vault details per region"
  value = {
    for region, kv in azurerm_key_vault.regional : region => {
      name                = kv.name
      resource_group_name = kv.resource_group_name
      location            = kv.location
      vault_uri           = kv.vault_uri
      id                  = kv.id
    }
  }
}

# ========================================
# DDoS Protection Plan Output
# ========================================

output "ddos_protection_plan_id" {
  description = "ID of the DDoS Protection Plan (if enabled)"
  value       = var.enable_ddos_protection ? azurerm_network_ddos_protection_plan.global[0].id : null
}

# ========================================
# Global Log Analytics Workspace Output
# ========================================

output "global_log_analytics_workspace_id" {
  description = "ID of the global Log Analytics workspace (if created)"
  value       = var.create_global_log_analytics ? azurerm_log_analytics_workspace.global[0].id : null
}

# ========================================
# Backend Configuration Examples
# ========================================

output "backend_config_example_canada_central_dev" {
  description = "Example backend configuration for Canada Central Dev environment"
  value = <<-EOT
    # Add to environments/canada-central/dev/backend.tf:

    terraform {
      backend "azurerm" {
        resource_group_name  = "${azurerm_resource_group.terraform_state["canada_central"].name}"
        storage_account_name = "${azurerm_storage_account.tfstate["canada_central"].name}"
        container_name       = "tfstate"
        key                  = "canadacentral-dev.terraform.tfstate"
      }
    }
  EOT
}

output "backend_config_example_canada_central_prod" {
  description = "Example backend configuration for Canada Central Prod environment"
  value = <<-EOT
    # Add to environments/canada-central/prod/backend.tf:

    terraform {
      backend "azurerm" {
        resource_group_name  = "${azurerm_resource_group.terraform_state["canada_central"].name}"
        storage_account_name = "${azurerm_storage_account.tfstate["canada_central"].name}"
        container_name       = "tfstate"
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
  value = <<-EOT
    ====================================
    Bootstrap Infrastructure Summary
    ====================================

    Regions configured: ${length(local.regions)}
    - Canada Central
    - East US 2
    - Central India
    - UAE North

    Resources created per region:
    - Terraform state storage account
    - Key Vault for secrets

    Global resources:
    - DDoS Protection Plan: ${var.enable_ddos_protection ? "Enabled" : "Disabled"}
    - Global Log Analytics: ${var.create_global_log_analytics ? "Created" : "Not Created"}

    Next Steps:
    1. Note storage account names from 'tfstate_storage_accounts' output
    2. Configure backend.tf in regional environments
    3. Store sensitive values in Key Vaults
    4. Proceed with regional infrastructure deployment

    ====================================
  EOT
}
