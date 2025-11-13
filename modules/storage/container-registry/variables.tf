# Container Registry Module Variables

# ========================================
# Required Variables
# ========================================

variable "registry_name" {
  description = "Name of the container registry (5-50 alphanumeric)"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9]{5,50}$", var.registry_name))
    error_message = "Registry name must be 5-50 alphanumeric characters."
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
# Registry Configuration
# ========================================

variable "sku" {
  description = "SKU (Basic, Standard, or Premium)"
  type        = string
  default     = "Premium"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku)
    error_message = "SKU must be Basic, Standard, or Premium."
  }
}

variable "admin_enabled" {
  description = "Enable admin account (not recommended for production)"
  type        = bool
  default     = false
}

variable "public_network_access_enabled" {
  description = "Enable public network access"
  type        = bool
  default     = false
}

# ========================================
# Geo-replication Configuration
# ========================================

variable "georeplications" {
  description = "Geo-replication locations (Premium only)"
  type = list(object({
    location                  = string
    zone_redundancy_enabled   = bool
    regional_endpoint_enabled = bool
    tags                      = map(string)
  }))
  default = []
}

# ========================================
# Policies
# ========================================

# ========================================
# Encryption Configuration
# ========================================

variable "encryption_identity_id" {
  description = "User-assigned identity ID for encryption"
  type        = string
  default     = null
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
