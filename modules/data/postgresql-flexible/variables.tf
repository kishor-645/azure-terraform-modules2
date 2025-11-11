# PostgreSQL Flexible Server Module Variables

variable "server_name" {
  description = "PostgreSQL server name"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "postgresql_version" {
  description = "PostgreSQL version"
  type        = string
  default     = "16"
}

variable "administrator_login" {
  description = "Administrator username"
  type        = string
}

variable "administrator_password" {
  description = "Administrator password"
  type        = string
  sensitive   = true
}

variable "sku_name" {
  description = "SKU name (e.g., GP_Standard_D4s_v3)"
  type        = string
  default     = "GP_Standard_D4s_v3"
}

variable "storage_mb" {
  description = "Storage in MB (32768-16777216)"
  type        = number
  default     = 131072
}

variable "storage_tier" {
  description = "Storage tier (P4, P6, P10, P15, P20, P30, P40, P50)"
  type        = string
  default     = "P20"
}

variable "backup_retention_days" {
  description = "Backup retention days (7-35)"
  type        = number
  default     = 7
}

variable "geo_redundant_backup_enabled" {
  description = "Enable geo-redundant backup"
  type        = bool
  default     = true
}

variable "high_availability_enabled" {
  description = "Enable high availability"
  type        = bool
  default     = true
}

variable "availability_zone" {
  description = "Primary availability zone"
  type        = string
  default     = "1"
}

variable "standby_availability_zone" {
  description = "Standby availability zone"
  type        = string
  default     = "2"
}

variable "delegated_subnet_id" {
  description = "Delegated subnet ID"
  type        = string
  default     = null
}

variable "private_dns_zone_id" {
  description = "Private DNS zone ID"
  type        = string
  default     = null
}

variable "max_connections" {
  description = "Max connections"
  type        = string
  default     = "200"
}

variable "shared_buffers" {
  description = "Shared buffers (MB)"
  type        = string
  default     = "4096"
}

variable "work_mem" {
  description = "Work memory (MB)"
  type        = string
  default     = "64"
}

variable "maintenance_work_mem" {
  description = "Maintenance work memory (MB)"
  type        = string
  default     = "512"
}

variable "databases" {
  description = "List of databases to create"
  type        = list(string)
  default     = []
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags"
  type        = map(string)
  default     = {}
}
