# Canada Central Production Environment Variables

variable "location" {
  description = "Azure region/location for all resources (e.g., canadacentral, eastus, westus2)"
  type        = string
  default     = "canadacentral"

  validation {
    condition     = can(regex("^[a-z0-9]+$", var.location))
    error_message = "Location must be a valid Azure region name (lowercase, no spaces)."
  }
}

variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "tenant_id" {
  description = "Azure AD tenant ID"
  type        = string
  default     = null
}

# ========================================
# Resource Group Configuration
# ========================================

variable "resource_group_name" {
  description = "Name of the main resource group (will be imported, not created)"
  type        = string
  default     = "rg-erp-cc-prod"
}

variable "aks_node_resource_group_name" {
  description = "Name of the AKS node resource group (will be imported, not created)"
  type        = string
  default     = "rg-aks-canadacentral-prod-nodes"
}

# ========================================
# Storage and Registry Configuration
# ========================================

variable "container_registry_name" {
  description = "Name of the Azure Container Registry (exact name, no dynamic suffixes)"
  type        = string
  default     = "acrerpccprod"
}

variable "storage_account_name" {
  description = "Name of the storage account (exact name, no dynamic suffixes)"
  type        = string
  default     = "sterpccprod"
}

variable "deployment_stage" {
  description = "Deployment stage (stage1 or stage2)"
  type        = string
  default     = "stage1"

  validation {
    condition     = contains(["stage1", "stage2"], var.deployment_stage)
    error_message = "Deployment stage must be stage1 or stage2"
  }
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28"
}

variable "aks_admin_group_object_ids" {
  description = "Azure AD group object IDs for AKS cluster admin access"
  type        = list(string)
  default     = []
}

variable "system_node_pool_vm_size" {
  description = "VM size for AKS system node pool"
  type        = string
  default     = "Standard_D4s_v5"
}

variable "user_node_pool_vm_size" {
  description = "VM size for AKS user node pool"
  type        = string
  default     = "Standard_F16s_v2"
}

variable "system_node_pool_min_count" {
  description = "Minimum nodes in system pool"
  type        = number
  default     = 1
}

variable "system_node_pool_max_count" {
  description = "Maximum nodes in system pool"
  type        = number
  default     = 5
}

variable "user_node_pool_min_count" {
  description = "Minimum nodes in user pool"
  type        = number
  default     = 1
}

variable "user_node_pool_max_count" {
  description = "Maximum nodes in user pool"
  type        = number
  default     = 5
}

variable "firewall_threat_intel_mode" {
  description = "Firewall threat intelligence mode"
  type        = string
  default     = "Alert"
}

variable "firewall_idps_mode" {
  description = "Firewall IDPS mode"
  type        = string
  default     = "Alert"
}

variable "istio_internal_lb_ip" {
  description = "Istio internal load balancer IP"
  type        = string
  default     = ""
}

variable "jumpbox_vm_size" {
  description = "Jumpbox VM size"
  type        = string
  default     = "Standard_B2s"
}

variable "jumpbox_admin_username" {
  description = "Jumpbox admin username"
  type        = string
  default     = "azureuser"
}

variable "jumpbox_admin_password" {
  description = "Admin password for jumpbox access"
  type        = string
  sensitive   = true
}

variable "log_analytics_retention_days" {
  description = "Log Analytics retention days"
  type        = number
  default     = 30
}

variable "additional_tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "spoke_vnets" {
  description = "Optional map of spoke VNet configurations to deploy multiple spokes. If null, a single spoke from locals is deployed."
  type = map(object({
    vnet_name      = string
    address_spaces = list(string)
    subnets = map(object({
      name                                  = optional(string)
      address_prefixes                      = list(string)
      service_endpoints                     = optional(list(string), [])
      private_endpoint_network_policies     = optional(string)
      private_link_service_network_policies = optional(string)
      delegations = optional(list(object({
        name = string
        service_delegation = object({
          name    = string
          actions = list(string)
        })
      })), [])
    }))
    tags = optional(map(string), {})
  }))
  default = null
}



variable "hub_network" {
  description = "Override defaults for the hub virtual network."
  type = object({
    vnet_name               = optional(string)
    address_spaces          = optional(list(string))
    ddos_protection_plan_id = optional(string)
    subnets = optional(map(object({
      name                                  = optional(string)
      address_prefixes                      = list(string)
      service_endpoints                     = optional(list(string), [])
      private_endpoint_network_policies     = optional(string)
      private_link_service_network_policies = optional(string)
      delegations = optional(list(object({
        name = string
        service_delegation = object({
          name    = string
          actions = list(string)
        })
      })), [])
    })))
  })
  default = {}
}

variable "default_spoke_network" {
  description = "Configuration overrides for the default spoke VNet used when spoke_vnets is null."
  type = object({
    vnet_name      = optional(string)
    address_spaces = optional(list(string))
    subnets = optional(map(object({
      name                                  = optional(string)
      address_prefixes                      = list(string)
      service_endpoints                     = optional(list(string), [])
      private_endpoint_network_policies     = optional(string)
      private_link_service_network_policies = optional(string)
      delegations = optional(list(object({
        name = string
        service_delegation = object({
          name    = string
          actions = list(string)
        })
      })), [])
    })))
    tags = optional(map(string), {})
  })
  default = {}
}

# AKS exposure toggle (private vs public control plane)
variable "aks_private_cluster_enabled" {
  description = "Enable AKS private cluster. Set false for public API endpoint."
  type        = bool
  default     = true
}
# PostgreSQL Variables
variable "postgresql_version" {
  description = "PostgreSQL version"
  type        = string
  default     = "16"
}

variable "postgresql_admin_login" {
  description = "PostgreSQL administrator login"
  type        = string
  sensitive   = true
}

variable "postgresql_admin_password" {
  description = "PostgreSQL administrator password"
  type        = string
  sensitive   = true
}

variable "postgresql_sku_name" {
  description = "PostgreSQL SKU name"
  type        = string
  default     = "GP_Standard_D4s_v3"
}

variable "postgresql_storage_mb" {
  description = "PostgreSQL storage in MB"
  type        = number
  default     = 131072
}

variable "postgresql_backup_retention_days" {
  description = "PostgreSQL backup retention days"
  type        = number
  default     = 7
}

# Agent VM Variables
variable "agent_vm_size" {
  description = "Agent VM size"
  type        = string
  default     = "Standard_B2s"
}

variable "agent_vm_admin_username" {
  description = "Agent VM admin username"
  type        = string
  default     = "azureuser"
}

variable "agent_vm_admin_password" {
  description = "Admin password for agent VM access"
  type        = string
  sensitive   = true
}
