# Key Vault Module Variables

# ========================================
# Required Variables
# ========================================

variable "key_vault_name" {
  description = "Name of the Key Vault (3-24 alphanumeric with hyphens)"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{3,24}$", var.key_vault_name))
    error_message = "Key Vault name must be 3-24 alphanumeric characters with hyphens."
  }
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

# ========================================
# Key Vault Configuration
# ========================================

variable "sku_name" {
  description = "SKU (standard or premium)"
  type        = string
  default     = "standard"

  validation {
    condition     = contains(["standard", "premium"], var.sku_name)
    error_message = "SKU must be standard or premium."
  }
}

variable "enabled_for_deployment" {
  description = "Enable for Azure Virtual Machine deployment"
  type        = bool
  default     = false
}

variable "enabled_for_disk_encryption" {
  description = "Enable for Azure Disk Encryption"
  type        = bool
  default     = true
}

variable "enabled_for_template_deployment" {
  description = "Enable for ARM template deployment"
  type        = bool
  default     = false
}

variable "enable_rbac_authorization" {
  description = "Enable RBAC authorization (recommended)"
  type        = bool
  default     = true
}

variable "purge_protection_enabled" {
  description = "Enable purge protection (cannot be disabled once enabled)"
  type        = bool
  default     = false
}

variable "soft_delete_retention_days" {
  description = "Soft delete retention days (7-90)"
  type        = number
  default     = 7

  validation {
    condition     = var.soft_delete_retention_days >= 7 && var.soft_delete_retention_days <= 90
    error_message = "Soft delete retention must be between 7 and 90 days."
  }
}

# ========================================
# Network Configuration
# ========================================

variable "public_network_access_enabled" {
  description = "Enable public network access"
  type        = bool
  default     = false
}

variable "network_acls_bypass" {
  description = "Network ACLs bypass"
  type        = string
  default     = "AzureServices"

  validation {
    condition     = contains(["AzureServices", "None"], var.network_acls_bypass)
    error_message = "Bypass must be AzureServices or None."
  }
}

variable "network_acls_default_action" {
  description = "Default network action"
  type        = string
  default     = "Deny"

  validation {
    condition     = contains(["Allow", "Deny"], var.network_acls_default_action)
    error_message = "Default action must be Allow or Deny."
  }
}

variable "allowed_ip_ranges" {
  description = "Allowed IP ranges"
  type        = list(string)
  default     = []
}

variable "allowed_subnet_ids" {
  description = "Allowed subnet IDs"
  type        = list(string)
  default     = []
}

# ========================================
# Private Endpoint Configuration
# ========================================

variable "enable_private_endpoint" {
  description = "Enable private endpoint"
  type        = bool
  default     = true
}

variable "private_endpoint_subnet_id" {
  description = "Subnet ID for private endpoint"
  type        = string
  default     = null
}

variable "private_dns_zone_ids" {
  description = "Private DNS zone IDs"
  type        = list(string)
  default     = []
}

# ========================================
# Monitoring
# ========================================

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID"
  type        = string
  default     = null
}

# ========================================
# Tags
# ========================================

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
