# Bootstrap Infrastructure
# Creates foundational resources for Terraform state management in Canada Central
# Run this ONCE before deploying infrastructure

terraform {
  required_version = ">= 1.10.3"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.51.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
  }
  subscription_id = var.subscription_id
}

# Local variables
locals {
  region         = "canadacentral"
  region_display = "Canada Central"
  region_abbr    = "cc"

  common_tags = {
    Environment = "Shared"
    ManagedBy   = "Terraform"
    Project     = "ERP-Infrastructure"
    Purpose     = "Bootstrap"
    CreatedDate = timestamp()
  }
}

# Random suffix for global uniqueness
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# ========================================
# Resource Groups for Bootstrap Resources
# ========================================

resource "azurerm_resource_group" "terraform_state" {
  name     = "rg-tfstate-${local.region}"
  location = local.region

  tags = merge(local.common_tags, {
    Region = local.region_display
  })
}

resource "azurerm_resource_group" "key_vault" {
  name     = "rg-keyvault-${local.region}"
  location = local.region

  tags = merge(local.common_tags, {
    Region = local.region_display
  })
}

# ========================================
# Storage Accounts for Terraform State
# ========================================

resource "azurerm_storage_account" "tfstate" {
  name                     = "sttfstate${local.region_abbr}${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.terraform_state.name
  location                 = azurerm_resource_group.terraform_state.location
  account_tier             = "Standard"
  account_replication_type = "GRS" # Geo-redundant for disaster recovery
  account_kind             = "StorageV2"

  # Security settings
  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = true

  # Advanced threat protection
  blob_properties {
    versioning_enabled       = true
    change_feed_enabled      = true
    last_access_time_enabled = true

    delete_retention_policy {
      days = 30
    }

    container_delete_retention_policy {
      days = 30
    }
  }

  tags = merge(local.common_tags, {
    Region = local.region_display
  })
}

# Storage container for Terraform state files
resource "azurerm_storage_container" "tfstate" {
  name               = "tfstate"
  storage_account_id = azurerm_storage_account.tfstate.id
}

# ========================================
# Key Vaults for Secrets Management
# ========================================

# Get current Azure AD user/service principal for Key Vault access
data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "main" {
  name                       = "kv-${local.region_abbr}-${random_string.suffix.result}"
  location                   = azurerm_resource_group.key_vault.location
  resource_group_name        = azurerm_resource_group.key_vault.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 90
  purge_protection_enabled   = true

  # RBAC mode (recommended over access policies)
  enable_rbac_authorization = true

  tags = merge(local.common_tags, {
    Region = local.region_display
  })
}

# Grant current user/service principal Key Vault Administrator role
resource "azurerm_role_assignment" "kv_admin" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}

# ========================================
# DDoS Protection Plan (Optional)
# ========================================

resource "azurerm_network_ddos_protection_plan" "main" {
  count = var.enable_ddos_protection ? 1 : 0

  name                = "ddos-${local.region_abbr}-${random_string.suffix.result}"
  location            = local.region
  resource_group_name = azurerm_resource_group.terraform_state.name

  tags = local.common_tags
}
