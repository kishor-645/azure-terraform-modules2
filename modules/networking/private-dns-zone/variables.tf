# Private DNS Zone Module Variables

# ========================================
# Required Variables
# ========================================

variable "dns_zone_name" {
  description = "Name of the private DNS zone (e.g., privatelink.azurecr.io)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9.-]+$", var.dns_zone_name))
    error_message = "DNS zone name must contain only lowercase letters, numbers, dots, and hyphens."
  }
}

variable "resource_group_name" {
  description = "Name of the resource group for the private DNS zone"
  type        = string
}

# ========================================
# Optional Variables
# ========================================

variable "linked_vnet_ids" {
  description = "List of VNet resource IDs to link to this private DNS zone"
  type        = list(string)
  default     = []
}

variable "enable_auto_registration" {
  description = "Enable auto-registration of VMs in linked VNets"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to all resources in this module"
  type        = map(string)
  default     = {}
}
