# AKS Cluster Module Variables

# ========================================
# Required Variables
# ========================================

variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
}

variable "location" {
  description = "Azure region for the AKS cluster"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name for the AKS cluster"
  type        = string
}

variable "dns_prefix" {
  description = "DNS prefix for the AKS cluster"
  type        = string
}

variable "vnet_id" {
  description = "Virtual Network ID for Network Contributor role"
  type        = string
}

variable "aks_node_pool_subnet_id" {
  description = "Subnet ID for shared AKS node pool (used by both system and user node pools)"
  type        = string
  default     = null
}

# Legacy variable for backward compatibility
variable "system_node_pool_subnet_id" {
  description = "[DEPRECATED] Use aks_node_pool_subnet_id instead. Subnet ID for system node pool"
  type        = string
  default     = null
}

# ========================================
# Cluster Configuration
# ========================================

variable "kubernetes_version" {
  description = "Kubernetes version for the cluster"
  type        = string
  default     = "1.28"
}

variable "node_resource_group_name" {
  description = "Name of the resource group for AKS-managed resources"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"
}

# ========================================
# Private Cluster Configuration
# ========================================

variable "private_cluster_enabled" {
  description = "Enable private cluster"
  type        = bool
  default     = true
}

variable "private_cluster_public_fqdn_enabled" {
  description = "When private cluster is enabled, control whether the private cluster has a public FQDN"
  type        = bool
  default     = false
}

variable "private_dns_zone_id" {
  description = "Private DNS Zone ID for private cluster (use 'System' for Azure-managed)"
  type        = string
  default     = "System"
}

# ========================================
# Network Configuration
# ========================================

variable "outbound_type" {
  description = "Outbound type (loadBalancer or userDefinedRouting)"
  type        = string
  default     = "loadBalancer"

  validation {
    condition     = contains(["loadBalancer", "userDefinedRouting"], var.outbound_type)
    error_message = "outbound_type must be loadBalancer or userDefinedRouting"
  }
}

variable "service_cidr" {
  description = "Service CIDR for Kubernetes services"
  type        = string
  default     = "10.100.0.0/16"
}

variable "dns_service_ip" {
  description = "DNS service IP (must be within service_cidr)"
  type        = string
  default     = "10.100.0.10"
}

variable "pod_cidr" {
  description = "Pod CIDR for Azure CNI Overlay mode"
  type        = string
  default     = "10.244.0.0/16"
}

# ========================================
# System Node Pool Configuration
# ========================================

variable "system_node_pool_name" {
  description = "Name of the system node pool"
  type        = string
  default     = "system"
}

variable "system_node_pool_vm_size" {
  description = "VM size for system node pool"
  type        = string
  default     = "Standard_D4s_v5"
}

variable "system_node_pool_enable_autoscaling" {
  description = "Enable autoscaling for system node pool"
  type        = bool
  default     = true
}

variable "system_node_pool_min_count" {
  description = "Minimum node count for system node pool"
  type        = number
  default     = 1
}

variable "system_node_pool_max_count" {
  description = "Maximum node count for system node pool"
  type        = number
  default     = 5
}

variable "system_node_pool_count" {
  description = "Fixed node count (used when autoscaling is disabled)"
  type        = number
  default     = 2
}

variable "system_node_pool_max_pods" {
  description = "Maximum pods per node for system node pool"
  type        = number
  default     = 30
}

variable "system_node_pool_os_disk_size_gb" {
  description = "OS disk size in GB for system node pool"
  type        = number
  default     = 128
}

variable "system_node_pool_os_disk_type" {
  description = "OS disk type for system node pool"
  type        = string
  default     = "Managed"
}

variable "system_node_pool_availability_zones" {
  description = "Availability zones for system node pool"
  type        = list(string)
  default     = ["1", "2", "3"]
}

variable "system_node_pool_max_surge" {
  description = "Max surge for system node pool upgrades"
  type        = string
  default     = "33%"
}

# ========================================
# User Node Pool Configuration
# ========================================

variable "user_node_pool_enabled" {
  description = "Enable user node pool"
  type        = bool
  default     = true
}

variable "user_node_pool_name" {
  description = "Name of the user node pool"
  type        = string
  default     = "user"
}

variable "user_node_pool_vm_size" {
  description = "VM size for user node pool"
  type        = string
  default     = "Standard_F16s_v2"
}

variable "user_node_pool_enable_autoscaling" {
  description = "Enable autoscaling for user node pool"
  type        = bool
  default     = true
}

variable "user_node_pool_min_count" {
  description = "Minimum node count for user node pool"
  type        = number
  default     = 1
}

variable "user_node_pool_max_count" {
  description = "Maximum node count for user node pool"
  type        = number
  default     = 5
}

variable "user_node_pool_count" {
  description = "Fixed node count (used when autoscaling is disabled)"
  type        = number
  default     = 2
}

variable "user_node_pool_max_pods" {
  description = "Maximum pods per node for user node pool"
  type        = number
  default     = 110
}

variable "user_node_pool_os_disk_size_gb" {
  description = "OS disk size in GB for user node pool"
  type        = number
  default     = 128
}

variable "user_node_pool_os_disk_type" {
  description = "OS disk type for user node pool"
  type        = string
  default     = "Managed"
}

variable "user_node_pool_availability_zones" {
  description = "Availability zones for user node pool"
  type        = list(string)
  default     = ["1", "2", "3"]
}

variable "user_node_pool_max_surge" {
  description = "Max surge for user node pool upgrades"
  type        = string
  default     = "33%"
}

variable "user_node_pool_labels" {
  description = "Labels for user node pool nodes"
  type        = map(string)
  default     = {}
}

variable "user_node_pool_taints" {
  description = "Taints for user node pool nodes"
  type        = list(string)
  default     = []
}

# ========================================
# Identity Configuration
# ========================================

variable "aks_identity_name" {
  description = "Name of the AKS user-assigned managed identity"
  type        = string
}

variable "acr_id" {
  description = "Azure Container Registry ID for AcrPull role assignment"
  type        = string
  default     = null
}

variable "key_vault_id" {
  description = "Key Vault ID for secrets access"
  type        = string
  default     = null
}

# ========================================
# Azure AD Integration
# ========================================

variable "azure_rbac_enabled" {
  description = "Enable Azure RBAC for Kubernetes authorization"
  type        = bool
  default     = true
}

variable "tenant_id" {
  description = "Azure AD tenant ID"
  type        = string
  default     = null
}

variable "admin_group_object_ids" {
  description = "Azure AD group object IDs for cluster admin access"
  type        = list(string)
  default     = []
}

# ========================================
# Istio Service Mesh Configuration
# ========================================

variable "istio_internal_ingress_gateway_enabled" {
  description = "Enable Istio internal ingress gateway"
  type        = bool
  default     = true
}

variable "istio_external_ingress_gateway_enabled" {
  description = "Enable Istio external ingress gateway"
  type        = bool
  default     = false
}

# ========================================
# Monitoring Configuration
# ========================================

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for monitoring"
  type        = string
}

# ========================================
# Key Vault Secrets Provider
# ========================================

variable "key_vault_secrets_rotation_enabled" {
  description = "Enable automatic rotation of Key Vault secrets"
  type        = bool
  default     = true
}

variable "key_vault_secrets_rotation_interval" {
  description = "Rotation interval for Key Vault secrets (e.g., '2m')"
  type        = string
  default     = "2m"
}

# ========================================
# Tags
# ========================================

variable "tags" {
  description = "Tags to apply to all AKS resources"
  type        = map(string)
  default     = {}
}
