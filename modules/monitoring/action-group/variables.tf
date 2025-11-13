# Action Group Module Variables

variable "action_group_name" {
  description = "Action group name"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "short_name" {
  description = "Short name (max 12 characters)"
  type        = string

  validation {
    condition     = length(var.short_name) <= 12
    error_message = "Short name must be 12 characters or less"
  }
}

variable "enabled" {
  description = "Enable action group"
  type        = bool
  default     = true
}

variable "email_receivers" {
  description = "Email receivers"
  type = list(object({
    name                    = string
    email_address           = string
    use_common_alert_schema = bool
  }))
  default = []
}

variable "sms_receivers" {
  description = "SMS receivers"
  type = list(object({
    name         = string
    country_code = string
    phone_number = string
  }))
  default = []
}

variable "webhook_receivers" {
  description = "Webhook receivers"
  type = list(object({
    name                    = string
    service_uri             = string
    use_common_alert_schema = bool
  }))
  default = []
}

variable "azure_function_receivers" {
  description = "Azure Function receivers"
  type = list(object({
    name                     = string
    function_app_resource_id = string
    function_name            = string
    http_trigger_url         = string
    use_common_alert_schema  = bool
  }))
  default = []
}

variable "tags" {
  description = "Tags"
  type        = map(string)
  default     = {}
}
