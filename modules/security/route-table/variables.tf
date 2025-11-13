# Route Table Module Variables

# ========================================
# Required Variables
# ========================================

variable "route_table_name" {
  description = "Name of the route table"
  type        = string
}

variable "location" {
  description = "Azure region for the route table"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name for the route table"
  type        = string
}

# ========================================
# Route Configuration
# ========================================

variable "routes" {
  description = "List of routes to create in the route table"
  type = list(object({
    name                   = string
    address_prefix         = string
    next_hop_type          = string
    next_hop_in_ip_address = optional(string)
  }))
  default = []

  validation {
    condition = alltrue([
      for route in var.routes :
      contains(["VirtualNetworkGateway", "VnetLocal", "Internet", "VirtualAppliance", "None"], route.next_hop_type)
    ])
    error_message = "next_hop_type must be one of: VirtualNetworkGateway, VnetLocal, Internet, VirtualAppliance, None"
  }

  validation {
    condition = alltrue([
      for route in var.routes :
      route.next_hop_type != "VirtualAppliance" || route.next_hop_in_ip_address != null
    ])
    error_message = "next_hop_in_ip_address is required when next_hop_type is VirtualAppliance"
  }

  validation {
    condition = alltrue([
      for route in var.routes :
      can(cidrhost(route.address_prefix, 0))
    ])
    error_message = "address_prefix must be a valid CIDR block"
  }
}

## Subnet Associations

variable "subnet_ids" {
  description = "List of subnet IDs to associate with this route table"
  type        = list(string)
  default     = []
}

# ========================================
# Tags
# ========================================

variable "tags" {
  description = "Tags to apply to the route table"
  type        = map(string)
  default     = {}
}
