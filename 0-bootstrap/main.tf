# Bootstrap Infrastructure
# Creates foundational resources for Terraform state management across all regions
# Run this ONCE before deploying any regional infrastructure

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
  regions = {
    canada_central = {
      name          = "canadacentral"
      display_name  = "Canada Central"
      abbreviation  = "cc"
    }
    east_us2 = {
      name          = "eastus2"
      display_name  = "East US 2"
      abbreviation  = "eus2"
    }
    central_india = {
      name          = "centralindia"
      display_name  = "Central India"
      abbreviation  = "cin"
    }
    uae_north = {
      name          = "uaenorth"
      display_name  = "UAE North"
      abbreviation  = "uan"
    }
  }

  common_tags = {
    Environment  = "Shared"
    ManagedBy    = "Terraform"
    Project      = "ERP-Multi-Region"
    Purpose      = "Bootstrap"
    CreatedDate  = timestamp()
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
  for_each = local.regions

  name     = "rg-tfstate-${each.value.name}"
  location = each.value.name

  tags = merge(local.common_tags, {
    Region = each.value.display_name
  })
}

resource "azurerm_resource_group" "key_vault" {
  for_each = local.regions

  name     = "rg-keyvault-${each.value.name}"
  location = each.value.name

  tags = merge(local.common_tags, {
    Region = each.value.display_name
  })
}

# ========================================
# Storage Accounts for Terraform State
# ========================================

resource "azurerm_storage_account" "tfstate" {
  for_each = local.regions

  name                     = "sttfstate${each.value.abbreviation}${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.terraform_state[each.key].name
  location                 = azurerm_resource_group.terraform_state[each.key].location
  account_tier             = "Standard"
  account_replication_type = "GRS"  # Geo-redundant for disaster recovery
  account_kind             = "StorageV2"

  # Security settings
  min_tls_version                 = "TLS1_2"
  enable_https_traffic_only       = true
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

  # Network security (initially allow all, restrict after setup)
  network_rules {
    default_action = "Allow"  # Change to "Deny" after locking down network access (Private Endpoints/firewall rules)
    bypass         = ["AzureServices"]
  }

  tags = merge(local.common_tags, {
    Region = each.value.display_name
  })
}

# Storage container for Terraform state files
resource "azurerm_storage_container" "tfstate" {
  for_each = local.regions

  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.tfstate[each.key].name
  container_access_type = "private"
}

# ========================================
# Key Vaults for Secrets Management
# ========================================

# Get current Azure AD user/service principal for Key Vault access
data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "regional" {
  for_each = local.regions

  name                       = "kv-${each.value.abbreviation}-${random_string.suffix.result}"
  location                   = azurerm_resource_group.key_vault[each.key].location
  resource_group_name        = azurerm_resource_group.key_vault[each.key].name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 90
  purge_protection_enabled   = true

  # RBAC mode (recommended over access policies)
  enable_rbac_authorization = true

  # Network security (initially allow all, restrict after setup)
  network_acls {
    default_action = "Allow"  # Change to "Deny" after configuring private endpoints
    bypass         = "AzureServices"
  }

  tags = merge(local.common_tags, {
    Region = each.value.display_name
  })
}

# Grant current user/service principal Key Vault Administrator role
resource "azurerm_role_assignment" "kv_admin" {
  for_each = local.regions

  scope                = azurerm_key_vault.regional[each.key].id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}

# ========================================
# DDoS Protection Plan (Shared Globally)
# ========================================

resource "azurerm_network_ddos_protection_plan" "global" {
  count = var.enable_ddos_protection ? 1 : 0

  name                = "ddos-global-${random_string.suffix.result}"
  location            = "canadacentral"  # Primary region
  resource_group_name = azurerm_resource_group.terraform_state["canada_central"].name

  tags = merge(local.common_tags, {
    Scope = "Global"
  })
}

# ========================================
# Log Analytics Workspace (Optional - Global)
# ========================================

resource "azurerm_log_analytics_workspace" "global" {
  count = var.create_global_log_analytics ? 1 : 0

  name                = "log-global-${random_string.suffix.result}"
  location            = "canadacentral"
  resource_group_name = azurerm_resource_group.terraform_state["canada_central"].name
  sku                 = "PerGB2018"
  retention_in_days   = 90

  tags = merge(local.common_tags, {
    Scope = "Global"
  })
}
