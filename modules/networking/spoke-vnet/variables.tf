# Spoke VNet Module Variables

# ========================================
# Required Variables
# ========================================

variable "vnet_name" {
  description = "Name of the spoke virtual network"
  type        = string
}

variable "location" {
  description = "Azure region for the spoke VNet"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group for the spoke VNet"
  type        = string
}

variable "address_space" {
  description = "Address space for the spoke VNet (e.g., 10.1.0.0/16)"
  type        = string

  validation {
    condition     = can(cidrhost(var.address_space, 0))
    error_message = "The address_space must be a valid CIDR block."
  }
}

# Optional: multiple address spaces (preferred). If set, overrides address_space.
variable "address_spaces" {
  description = "List of address spaces for the spoke VNet. If provided, overrides address_space."
  type        = list(string)
  default     = null
}

# ========================================
# Subnet CIDR Variables
# ========================================

variable "aks_node_pool_subnet_cidr" {
  description = "CIDR block for shared AKS node pool subnet (used by both system and user node pools, recommend /20 for 4,091 IPs)"
  type        = string

  validation {
    condition     = can(cidrhost(var.aks_node_pool_subnet_cidr, 0))
    error_message = "The aks_node_pool_subnet_cidr must be a valid CIDR block."
  }
}

variable "private_endpoints_subnet_cidr" {
  description = "CIDR block for private endpoints subnet (recommend /24 for 251 IPs)"
  type        = string

  validation {
    condition     = can(cidrhost(var.private_endpoints_subnet_cidr, 0))
    error_message = "The private_endpoints_subnet_cidr must be a valid CIDR block."
  }
}


# ========================================
# Optional Variables
# ========================================

variable "aks_node_pool_subnet_name" {
  description = "Name for the shared AKS node pool subnet (used by both system and user node pools)"
  type        = string
  default     = "AKSNodeSubnet"
}

variable "private_endpoints_subnet_name" {
  description = "Name for the private endpoints subnet"
  type        = string
  default     = "PrivateEndpointsSubnet"
}

# New: fully dynamic subnets map (preferred)
# Keys are logical subnet identifiers; values define Azure subnet arguments.
variable "subnets" {
  description = "Map of subnets to create. If provided, the legacy fixed subnet variables are ignored."
  type = map(object({
    name                                  = optional(string) # defaults to key if omitted
    address_prefixes                      = list(string)
    service_endpoints                     = optional(list(string), [])
    private_endpoint_network_policies     = optional(string) # 'Enabled' or 'Disabled'
    private_link_service_network_policies = optional(string) # 'Enabled' or 'Disabled'
    delegations = optional(list(object({
      name = string
      service_delegation = object({
        name    = string
        actions = list(string)
      })
    })), [])
  }))
  default = null
}

variable "tags" {
  description = "Tags to apply to all resources in this module"
  type        = map(string)
  default     = {}
}
