# Azure Firewall Module Variables

# ========================================
# Required Variables
# ========================================

variable "firewall_name" {
  description = "Name of the Azure Firewall"
  type        = string
}

variable "location" {
  description = "Azure region for the firewall"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name for the firewall"
  type        = string
}

variable "firewall_subnet_id" {
  description = "ID of the AzureFirewallSubnet"
  type        = string
}

variable "firewall_management_subnet_id" {
  description = "ID of the AzureFirewallManagementSubnet (required for forced tunneling)"
  type        = string
}

variable "firewall_policy_name" {
  description = "Name of the Firewall Policy"
  type        = string
}

# ========================================
# Public IP Variables
# ========================================

variable "firewall_public_ip_name" {
  description = "Name of the Firewall public IP"
  type        = string
}

variable "firewall_management_ip_name" {
  description = "Name of the Firewall management public IP"
  type        = string
}

# ========================================
# Availability Zones
# ========================================

variable "availability_zones" {
  description = "List of availability zones for the firewall (e.g., ['1', '2', '3'])"
  type        = list(string)
  default     = ["1", "2", "3"]
}

# ========================================
# DNAT Configuration
# ========================================

variable "internal_lb_ip" {
  description = "Private IP address of the internal load balancer (Istio ingress gateway)"
  type        = string
  default     = ""

  validation {
    condition     = var.internal_lb_ip == "" || can(regex("^(?:[0-9]{1,3}\\.){3}[0-9]{1,3}$", var.internal_lb_ip))
    error_message = "The internal_lb_ip must be a valid IPv4 address or empty string."
  }
}

variable "fetch_cloudflare_ips_dynamically" {
  description = "Fetch Cloudflare IP ranges dynamically from Cloudflare API"
  type        = bool
  default     = true
}

variable "cloudflare_ip_ranges" {
  description = "Static list of Cloudflare IP ranges (used if fetch_cloudflare_ips_dynamically is false)"
  type        = list(string)
  default = [
    "173.245.48.0/20",
    "103.21.244.0/22",
    "103.22.200.0/22",
    "103.31.4.0/22",
    "141.101.64.0/18",
    "108.162.192.0/18",
    "190.93.240.0/20",
    "188.114.96.0/20",
    "197.234.240.0/22",
    "198.41.128.0/17",
    "162.158.0.0/15",
    "104.16.0.0/13",
    "104.24.0.0/14",
    "172.64.0.0/13",
    "131.0.72.0/22"
  ]
}

variable "enable_ipv6" {
  description = "Enable IPv6 support for Cloudflare DNAT rules"
  type        = bool
  default     = false
}

# ========================================
# Firewall Policy Configuration
# ========================================

variable "threat_intelligence_mode" {
  description = "Threat intelligence mode (Alert, Deny, Off)"
  type        = string
  default     = "Alert"

  validation {
    condition     = contains(["Alert", "Deny", "Off"], var.threat_intelligence_mode)
    error_message = "Threat intelligence mode must be Alert, Deny, or Off."
  }
}

variable "idps_mode" {
  description = "IDPS mode (Alert, Deny, Off)"
  type        = string
  default     = "Alert"

  validation {
    condition     = contains(["Alert", "Deny", "Off"], var.idps_mode)
    error_message = "IDPS mode must be Alert, Deny, or Off."
  }
}

variable "idps_signature_overrides" {
  description = "List of IDPS signature overrides"
  type = list(object({
    id    = string
    state = string
  }))
  default = []
}

variable "idps_traffic_bypass" {
  description = "List of IDPS traffic bypass rules"
  type = list(object({
    name                  = string
    protocol              = string
    description           = string
    destination_addresses = list(string)
    destination_ports     = list(string)
    source_addresses      = list(string)
    source_ip_groups      = list(string)
  }))
  default = []
}

variable "threat_intel_allowlist_ips" {
  description = "List of IP addresses to allowlist in threat intelligence"
  type        = list(string)
  default     = []
}

variable "threat_intel_allowlist_fqdns" {
  description = "List of FQDNs to allowlist in threat intelligence"
  type        = list(string)
  default     = []
}

variable "custom_dns_servers" {
  description = "Custom DNS servers for the firewall (empty list uses Azure DNS)"
  type        = list(string)
  default     = []
}

# ========================================
# TLS Inspection (Premium)
# ========================================

variable "enable_tls_inspection" {
  description = "Enable TLS inspection (requires Premium SKU and certificate in Key Vault)"
  type        = bool
  default     = false
}

variable "tls_certificate_key_vault_secret_id" {
  description = "Key Vault secret ID containing TLS inspection certificate"
  type        = string
  default     = null
}

variable "tls_certificate_name" {
  description = "Name for the TLS inspection certificate"
  type        = string
  default     = "tls-inspection-cert"
}

# ========================================
# Network Rule Variables
# ========================================

variable "hub_vnet_cidr" {
  description = "CIDR block of the hub VNet"
  type        = string
  default     = "10.0.0.0/16"
}

variable "spoke_vnet_cidr" {
  description = "CIDR block of the spoke VNet"
  type        = string
  default     = "10.1.0.0/16"
}

variable "custom_source_addresses" {
  description = "Custom source addresses for firewall rules"
  type        = list(string)
  default     = ["*"]
}

variable "custom_destination_addresses" {
  description = "Custom destination addresses for network rules"
  type        = list(string)
  default     = []
}

variable "custom_destination_ports" {
  description = "Custom destination ports for network rules"
  type        = list(string)
  default     = ["443"]
}

# ========================================
# Application Rule Variables
# ========================================

variable "custom_allowed_fqdns" {
  description = "Custom list of allowed FQDNs"
  type        = list(string)
  default     = []
}

# ========================================
# Monitoring
# ========================================

variable "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace for diagnostics"
  type        = string
  default     = null
}

# ========================================
# Tags
# ========================================

variable "tags" {
  description = "Tags to apply to all firewall resources"
  type        = map(string)
  default     = {}
}
