# Azure Bastion Module Variables

# ========================================
# Required Variables
# ========================================

variable "bastion_name" {
  description = "Name of the Azure Bastion host"
  type        = string
}

variable "location" {
  description = "Azure region for the Bastion host"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name for the Bastion host"
  type        = string
}

variable "bastion_subnet_id" {
  description = "ID of the AzureBastionSubnet (must be exactly /26 or larger)"
  type        = string
}

variable "bastion_public_ip_name" {
  description = "Name of the Bastion public IP"
  type        = string
}

# ========================================
# Bastion SKU
# ========================================

variable "bastion_sku" {
  description = "SKU of Azure Bastion (Basic or Standard)"
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Basic", "Standard"], var.bastion_sku)
    error_message = "Bastion SKU must be either Basic or Standard."
  }
}

# ========================================
# Availability Zones
# ========================================

variable "availability_zones" {
  description = "List of availability zones for the Bastion public IP"
  type        = list(string)
  default     = ["1", "2", "3"]
}

# ========================================
# Standard SKU Features
# ========================================

variable "copy_paste_enabled" {
  description = "Enable copy/paste functionality (Standard SKU only)"
  type        = bool
  default     = true
}

variable "file_copy_enabled" {
  description = "Enable file copy functionality (Standard SKU only)"
  type        = bool
  default     = true
}

variable "ip_connect_enabled" {
  description = "Enable IP-based connections (Standard SKU only)"
  type        = bool
  default     = true
}

variable "shareable_link_enabled" {
  description = "Enable shareable links (Standard SKU only)"
  type        = bool
  default     = false
}

variable "tunneling_enabled" {
  description = "Enable native client support/tunneling (Standard SKU only)"
  type        = bool
  default     = true
}

variable "scale_units" {
  description = "Number of scale units (2-50, Standard SKU only)"
  type        = number
  default     = 2

  validation {
    condition     = var.scale_units >= 2 && var.scale_units <= 50
    error_message = "Scale units must be between 2 and 50."
  }
}

# ========================================
# Monitoring
# ========================================

variable "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace for Bastion diagnostics"
  type        = string
  default     = null
}

# ========================================
# Tags
# ========================================

variable "tags" {
  description = "Tags to apply to Bastion resources"
  type        = map(string)
  default     = {}
}
