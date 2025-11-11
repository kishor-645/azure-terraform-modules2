# Storage Account Module Variables

# ========================================
# Required Variables
# ========================================

variable "storage_account_name" {
  description = "Name of the storage account (3-24 lowercase alphanumeric)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.storage_account_name))
    error_message = "Storage account name must be 3-24 lowercase alphanumeric characters."
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
# Storage Configuration
# ========================================

variable "account_tier" {
  description = "Storage account tier (Standard or Premium)"
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Standard", "Premium"], var.account_tier)
    error_message = "Account tier must be Standard or Premium."
  }
}

variable "account_replication_type" {
  description = "Storage account replication type"
  type        = string
  default     = "LRS"

  validation {
    condition     = contains(["LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS"], var.account_replication_type)
    error_message = "Invalid replication type."
  }
}

variable "account_kind" {
  description = "Storage account kind"
  type        = string
  default     = "StorageV2"

  validation {
    condition     = contains(["BlobStorage", "BlockBlobStorage", "FileStorage", "Storage", "StorageV2"], var.account_kind)
    error_message = "Invalid account kind."
  }
}

variable "enable_hierarchical_namespace" {
  description = "Enable hierarchical namespace for ADLS Gen2"
  type        = bool
  default     = false
}

# ========================================
# Network Configuration
# ========================================

variable "public_network_access_enabled" {
  description = "Enable public network access"
  type        = bool
  default     = false
}

variable "default_network_action" {
  description = "Default network action (Allow or Deny)"
  type        = string
  default     = "Deny"

  validation {
    condition     = contains(["Allow", "Deny"], var.default_network_action)
    error_message = "Default network action must be Allow or Deny."
  }
}

variable "network_bypass" {
  description = "Network bypass for Azure services"
  type        = list(string)
  default     = ["AzureServices"]
}

variable "allowed_ip_ranges" {
  description = "List of allowed IP ranges"
  type        = list(string)
  default     = []
}

variable "allowed_subnet_ids" {
  description = "List of allowed subnet IDs"
  type        = list(string)
  default     = []
}

# ========================================
# Private Endpoint Configuration
# ========================================

variable "enable_private_endpoint" {
  description = "Enable private endpoint for blob storage"
  type        = bool
  default     = true
}

variable "enable_file_private_endpoint" {
  description = "Enable private endpoint for file storage"
  type        = bool
  default     = false
}

variable "private_endpoint_subnet_id" {
  description = "Subnet ID for private endpoint"
  type        = string
  default     = null
}

variable "private_dns_zone_ids_blob" {
  description = "Private DNS zone IDs for blob storage"
  type        = list(string)
  default     = []
}

variable "private_dns_zone_ids_file" {
  description = "Private DNS zone IDs for file storage"
  type        = list(string)
  default     = []
}

# ========================================
# Blob Properties
# ========================================

variable "blob_versioning_enabled" {
  description = "Enable blob versioning"
  type        = bool
  default     = true
}

variable "blob_change_feed_enabled" {
  description = "Enable blob change feed"
  type        = bool
  default     = false
}

variable "blob_delete_retention_days" {
  description = "Blob soft delete retention days"
  type        = number
  default     = 7
}

variable "container_delete_retention_days" {
  description = "Container soft delete retention days"
  type        = number
  default     = 7
}

# ========================================
# Encryption Configuration
# ========================================

variable "customer_managed_key_vault_key_id" {
  description = "Key Vault key ID for customer-managed encryption"
  type        = string
  default     = null
}

variable "encryption_identity_id" {
  description = "User-assigned identity ID for encryption"
  type        = string
  default     = null
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
