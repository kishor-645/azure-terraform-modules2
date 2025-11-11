# Hub VNet Module Variables

# ========================================
# Required Variables
# ========================================

variable "vnet_name" {
  description = "Name of the hub virtual network"
  type        = string
}

variable "location" {
  description = "Azure region for the hub VNet"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group for the hub VNet"
  type        = string
}

variable "address_space" {
  description = "Address space for the hub VNet (e.g., 10.0.0.0/16)"
  type        = string

  validation {
    condition     = can(cidrhost(var.address_space, 0))
    error_message = "The address_space must be a valid CIDR block."
  }
}

# ========================================
# Subnet CIDR Variables
# ========================================

variable "firewall_subnet_cidr" {
  description = "CIDR block for Azure Firewall subnet (must be /26 or larger)"
  type        = string

  validation {
    condition     = can(cidrhost(var.firewall_subnet_cidr, 0))
    error_message = "The firewall_subnet_cidr must be a valid CIDR block."
  }
}

variable "bastion_subnet_cidr" {
  description = "CIDR block for Azure Bastion subnet (must be /26 or larger)"
  type        = string

  validation {
    condition     = can(cidrhost(var.bastion_subnet_cidr, 0))
    error_message = "The bastion_subnet_cidr must be a valid CIDR block."
  }
}

variable "firewall_mgmt_subnet_cidr" {
  description = "CIDR block for Azure Firewall Management subnet (must be /26 or larger)"
  type        = string

  validation {
    condition     = can(cidrhost(var.firewall_mgmt_subnet_cidr, 0))
    error_message = "The firewall_mgmt_subnet_cidr must be a valid CIDR block."
  }
}

variable "shared_services_subnet_cidr" {
  description = "CIDR block for shared services subnet"
  type        = string

  validation {
    condition     = can(cidrhost(var.shared_services_subnet_cidr, 0))
    error_message = "The shared_services_subnet_cidr must be a valid CIDR block."
  }
}

variable "private_endpoints_subnet_cidr" {
  description = "CIDR block for private endpoints subnet"
  type        = string

  validation {
    condition     = can(cidrhost(var.private_endpoints_subnet_cidr, 0))
    error_message = "The private_endpoints_subnet_cidr must be a valid CIDR block."
  }
}

variable "jumpbox_subnet_cidr" {
  description = "CIDR block for jumpbox subnet"
  type        = string

  validation {
    condition     = can(cidrhost(var.jumpbox_subnet_cidr, 0))
    error_message = "The jumpbox_subnet_cidr must be a valid CIDR block."
  }
}

# ========================================
# Optional Variables
# ========================================

variable "shared_services_subnet_name" {
  description = "Name for the shared services subnet"
  type        = string
  default     = "SharedServicesSubnet"
}

variable "private_endpoints_subnet_name" {
  description = "Name for the private endpoints subnet"
  type        = string
  default     = "PrivateEndpointsSubnet"
}

variable "jumpbox_subnet_name" {
  description = "Name for the jumpbox subnet"
  type        = string
  default     = "JumpboxSubnet"
}

variable "ddos_protection_plan_id" {
  description = "ID of the DDoS Protection Plan to associate with the hub VNet (optional)"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to all resources in this module"
  type        = map(string)
  default     = {}
}
