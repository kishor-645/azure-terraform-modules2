# NSG Module Variables

# ========================================
# Required Variables
# ========================================

variable "nsg_name" {
  description = "Name of the Network Security Group"
  type        = string
}

variable "location" {
  description = "Azure region for the NSG"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name for the NSG"
  type        = string
}

# ========================================
# Security Rules
# ========================================

variable "inbound_rules" {
  description = "List of inbound security rules"
  type = list(object({
    name                                       = string
    priority                                   = number
    access                                     = string
    protocol                                   = string
    source_port_range                          = optional(string)
    destination_port_range                     = optional(string)
    source_port_ranges                         = optional(list(string))
    destination_port_ranges                    = optional(list(string))
    source_address_prefix                      = optional(string)
    source_address_prefixes                    = optional(list(string))
    destination_address_prefix                 = optional(string)
    destination_address_prefixes               = optional(list(string))
    description                                = optional(string)
    source_application_security_group_ids      = optional(list(string))
    destination_application_security_group_ids = optional(list(string))
  }))
  default = []

  validation {
    condition = alltrue([
      for rule in var.inbound_rules : 
      contains(["Allow", "Deny"], rule.access)
    ])
    error_message = "Access must be either 'Allow' or 'Deny'."
  }

  validation {
    condition = alltrue([
      for rule in var.inbound_rules : 
      contains(["Tcp", "Udp", "Icmp", "Esp", "Ah", "*"], rule.protocol)
    ])
    error_message = "Protocol must be one of: Tcp, Udp, Icmp, Esp, Ah, *"
  }

  validation {
    condition = alltrue([
      for rule in var.inbound_rules : 
      rule.priority >= 100 && rule.priority <= 4096
    ])
    error_message = "Priority must be between 100 and 4096."
  }
}

variable "outbound_rules" {
  description = "List of outbound security rules"
  type = list(object({
    name                                       = string
    priority                                   = number
    access                                     = string
    protocol                                   = string
    source_port_range                          = optional(string)
    destination_port_range                     = optional(string)
    source_port_ranges                         = optional(list(string))
    destination_port_ranges                    = optional(list(string))
    source_address_prefix                      = optional(string)
    source_address_prefixes                    = optional(list(string))
    destination_address_prefix                 = optional(string)
    destination_address_prefixes               = optional(list(string))
    description                                = optional(string)
    source_application_security_group_ids      = optional(list(string))
    destination_application_security_group_ids = optional(list(string))
  }))
  default = []

  validation {
    condition = alltrue([
      for rule in var.outbound_rules : 
      contains(["Allow", "Deny"], rule.access)
    ])
    error_message = "Access must be either 'Allow' or 'Deny'."
  }

  validation {
    condition = alltrue([
      for rule in var.outbound_rules : 
      contains(["Tcp", "Udp", "Icmp", "Esp", "Ah", "*"], rule.protocol)
    ])
    error_message = "Protocol must be one of: Tcp, Udp, Icmp, Esp, Ah, *"
  }

  validation {
    condition = alltrue([
      for rule in var.outbound_rules : 
      rule.priority >= 100 && rule.priority <= 4096
    ])
    error_message = "Priority must be between 100 and 4096."
  }
}

# ========================================
# Subnet Associations
# ========================================

variable "subnet_ids" {
  description = "List of subnet IDs to associate with this NSG"
  type        = list(string)
  default     = []
}

# ========================================
# Monitoring
# ========================================

variable "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace for NSG diagnostics"
  type        = string
}

# ========================================
# Tags
# ========================================

variable "tags" {
  description = "Tags to apply to the NSG"
  type        = map(string)
  default     = {}
}
