# VNet Peering Module Variables

# ========================================
# Required Variables
# ========================================

variable "hub_vnet_id" {
  description = "Resource ID of the hub virtual network"
  type        = string
}

variable "hub_vnet_name" {
  description = "Name of the hub virtual network"
  type        = string
}

variable "hub_resource_group_name" {
  description = "Resource group name of the hub virtual network"
  type        = string
}

variable "spoke_vnet_id" {
  description = "Resource ID of the spoke virtual network"
  type        = string
}

variable "spoke_vnet_name" {
  description = "Name of the spoke virtual network"
  type        = string
}

variable "spoke_resource_group_name" {
  description = "Resource group name of the spoke virtual network"
  type        = string
}

# ========================================
# Optional Variables
# ========================================

variable "hub_to_spoke_peering_name" {
  description = "Name for the hub-to-spoke peering connection"
  type        = string
  default     = null

  validation {
    condition     = var.hub_to_spoke_peering_name == null || can(regex("^[a-zA-Z0-9-_]+$", var.hub_to_spoke_peering_name))
    error_message = "Peering name must contain only alphanumeric characters, hyphens, and underscores."
  }
}

variable "spoke_to_hub_peering_name" {
  description = "Name for the spoke-to-hub peering connection"
  type        = string
  default     = null

  validation {
    condition     = var.spoke_to_hub_peering_name == null || can(regex("^[a-zA-Z0-9-_]+$", var.spoke_to_hub_peering_name))
    error_message = "Peering name must contain only alphanumeric characters, hyphens, and underscores."
  }
}
