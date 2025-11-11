# Application Insights Module Variables

variable "app_insights_name" {
  description = "Application Insights name"
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

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID"
  type        = string
}

variable "application_type" {
  description = "Application type (web, java, Node.js, other)"
  type        = string
  default     = "web"
}

variable "retention_in_days" {
  description = "Retention in days (30-730)"
  type        = number
  default     = 90
}

variable "daily_data_cap_in_gb" {
  description = "Daily data cap in GB"
  type        = number
  default     = 10
}

variable "daily_data_cap_notifications_disabled" {
  description = "Disable daily data cap notifications"
  type        = bool
  default     = false
}

variable "internet_ingestion_enabled" {
  description = "Enable internet ingestion"
  type        = bool
  default     = true
}

variable "internet_query_enabled" {
  description = "Enable internet query"
  type        = bool
  default     = true
}

variable "local_authentication_disabled" {
  description = "Disable local authentication"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags"
  type        = map(string)
  default     = {}
}
