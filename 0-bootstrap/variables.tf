# Bootstrap Variables
# Configure these values in bootstrap.tfvars

variable "subscription_id" {
  description = "Azure subscription ID for bootstrap resources"
  type        = string
  sensitive   = true
}

variable "enable_ddos_protection" {
  description = "Enable DDoS Protection Standard plan"
  type        = bool
  default     = false
}
