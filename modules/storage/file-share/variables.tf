# File Share Module Variables

# ========================================
# Required Variables
# ========================================

variable "storage_account_name" {
  description = "Name of the storage account for file share"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.storage_account_name))
    error_message = "Storage account name must be 3-24 lowercase alphanumeric characters."
  }
}

variable "file_share_name" {
  description = "Name of the file share"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]{3,63}$", var.file_share_name))
    error_message = "File share name must be 3-63 lowercase alphanumeric with hyphens."
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
# File Share Configuration
# ========================================

variable "file_share_quota_gb" {
  description = "File share quota in GB (100-102400 for Premium)"
  type        = number
  default     = 100

  validation {
    condition     = var.file_share_quota_gb >= 100 && var.file_share_quota_gb <= 102400
    error_message = "Quota must be between 100 and 102400 GB for Premium."
  }
}

variable "enabled_protocol" {
  description = "Enabled protocol (SMB or NFS)"
  type        = string
  default     = "NFS"

  validation {
    condition     = contains(["SMB", "NFS"], var.enabled_protocol)
    error_message = "Protocol must be SMB or NFS."
  }
}

variable "access_tier" {
  description = "Access tier (TransactionOptimized, Hot, or Cool)"
  type        = string
  default     = "TransactionOptimized"

  validation {
    condition     = contains(["TransactionOptimized", "Hot", "Cool"], var.access_tier)
    error_message = "Access tier must be TransactionOptimized, Hot, or Cool."
  }
}

variable "metadata" {
  description = "Metadata for the file share"
  type        = map(string)
  default     = {}
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
  description = "Default network action"
  type        = string
  default     = "Deny"
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
