# Linux VM Module Variables

# ========================================
# Required Variables
# ========================================

variable "vm_name" {
  description = "Name of the Linux VM"
  type        = string
}

variable "location" {
  description = "Azure region for the VM"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name for the VM"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for the VM network interface"
  type        = string
}

variable "admin_username" {
  description = "Admin username for the VM"
  type        = string
  default     = "azureuser"
}

variable "admin_password" {
  description = "Admin password for the VM"
  type        = string
  sensitive   = true
}

# ========================================
# Network Interface Configuration
# ========================================

variable "nic_name" {
  description = "Name of the network interface"
  type        = string
}

variable "private_ip_address_allocation" {
  description = "Private IP allocation method (Dynamic or Static)"
  type        = string
  default     = "Dynamic"

  validation {
    condition     = contains(["Dynamic", "Static"], var.private_ip_address_allocation)
    error_message = "private_ip_address_allocation must be Dynamic or Static"
  }
}

variable "private_ip_address" {
  description = "Static private IP address (required if allocation is Static)"
  type        = string
  default     = null
}

# ========================================
# VM Configuration
# ========================================

variable "vm_size" {
  description = "VM size"
  type        = string
  default     = "Standard_B2s"
}

variable "vm_purpose" {
  description = "Purpose of the VM (Jumpbox, Agent, etc.)"
  type        = string
  default     = "Jumpbox"
}

# ========================================
# OS Disk Configuration
# ========================================

variable "os_disk_name" {
  description = "Name of the OS disk"
  type        = string
}

variable "os_disk_storage_account_type" {
  description = "Storage account type for OS disk"
  type        = string
  default     = "Premium_LRS"

  validation {
    condition     = contains(["Standard_LRS", "StandardSSD_LRS", "Premium_LRS"], var.os_disk_storage_account_type)
    error_message = "os_disk_storage_account_type must be Standard_LRS, StandardSSD_LRS, or Premium_LRS"
  }
}

variable "os_disk_size_gb" {
  description = "OS disk size in GB"
  type        = number
  default     = 30
}

# ========================================
# Extensions Configuration
# ========================================

variable "enable_azure_ad_login" {
  description = "Enable Azure AD login extension"
  type        = bool
  default     = true
}

variable "enable_monitoring" {
  description = "Enable monitoring and dependency agent extensions"
  type        = bool
  default     = true
}

# ========================================
# Boot Diagnostics
# ========================================

variable "boot_diagnostics_storage_account_uri" {
  description = "Storage account URI for boot diagnostics (optional - leave null for managed storage)"
  type        = string
  default     = null
}

# ========================================
# Tags
# ========================================

variable "tags" {
  description = "Tags to apply to the VM resources"
  type        = map(string)
  default     = {}
}
