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

variable "default_network_action" {
  description = "Default network action (Allow or Deny)"
  type        = string
  default     = "Deny"
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

variable "retention_policy_enabled" {
  description = "Enable retention policy (Premium only)"
  type        = bool
  default     = false
}

variable "retention_policy_days" {
  description = "Retention policy days"
  type        = number
  default     = 7
}

variable "trust_policy_enabled" {
  description = "Enable trust policy (Premium only)"
  type        = bool
  default     = false
}

# ========================================
# Encryption Configuration
# ========================================

variable "encryption_key_vault_key_id" {
  description = "Key Vault key ID for customer-managed encryption"
  type        = string
  default     = null
}

variable "encryption_identity_id" {
  description = "User-assigned identity ID for encryption"
  type        = string
  default     = null
}

variable "encryption_identity_client_id" {
  description = "Client ID of encryption identity"
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
