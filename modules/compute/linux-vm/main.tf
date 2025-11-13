# Linux VM Module (Jumpbox/Agent VM)
# Creates Ubuntu 24.04 LTS VM with Azure AD login and JIT access support

terraform {
  required_version = ">= 1.10.3"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.51.0"
    }
  }
}

# ========================================
# Network Interface
# ========================================

resource "azurerm_network_interface" "this" {
  name                = var.nic_name
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = var.private_ip_address_allocation
    private_ip_address            = var.private_ip_address
  }

  tags = var.tags
}

# ========================================
# Linux Virtual Machine
# ========================================

resource "azurerm_linux_virtual_machine" "this" {
  name                = var.vm_name
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = var.vm_size
  admin_username      = var.admin_username

  network_interface_ids = [
    azurerm_network_interface.this.id
  ]

  # Password Authentication
  admin_password = var.admin_password

  # Enable password authentication
  disable_password_authentication = false

  # OS Disk
  os_disk {
    name                 = var.os_disk_name
    caching              = "ReadWrite"
    storage_account_type = var.os_disk_storage_account_type
    disk_size_gb         = var.os_disk_size_gb
  }

  # Source Image - Ubuntu 24.04 LTS
  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  # Identity for Azure AD login
  identity {
    type = "SystemAssigned"
  }

  # Boot Diagnostics
  boot_diagnostics {
    storage_account_uri = var.boot_diagnostics_storage_account_uri
  }

  tags = merge(
    var.tags,
    {
      OS      = "Ubuntu 24.04 LTS"
      Purpose = var.vm_purpose
    }
  )
}

# ========================================
# Azure AD Login Extension
# ========================================

resource "azurerm_virtual_machine_extension" "aad_login" {
  count = var.enable_azure_ad_login ? 1 : 0

  name                 = "AADSSHLoginForLinux"
  virtual_machine_id   = azurerm_linux_virtual_machine.this.id
  publisher            = "Microsoft.Azure.ActiveDirectory"
  type                 = "AADSSHLoginForLinux"
  type_handler_version = "1.0"

  tags = var.tags
}

# ========================================
# Monitoring Extension
# ========================================

resource "azurerm_virtual_machine_extension" "monitor" {
  count = var.enable_monitoring ? 1 : 0

  name                       = "AzureMonitorLinuxAgent"
  virtual_machine_id         = azurerm_linux_virtual_machine.this.id
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorLinuxAgent"
  type_handler_version       = "1.29"
  auto_upgrade_minor_version = true

  tags = var.tags
}

# ========================================
# Dependency Agent Extension
# ========================================

resource "azurerm_virtual_machine_extension" "dependency_agent" {
  count = var.enable_monitoring ? 1 : 0

  name                       = "DependencyAgentLinux"
  virtual_machine_id         = azurerm_linux_virtual_machine.this.id
  publisher                  = "Microsoft.Azure.Monitoring.DependencyAgent"
  type                       = "DependencyAgentLinux"
  type_handler_version       = "9.10"
  auto_upgrade_minor_version = true

  tags = var.tags

  depends_on = [
    azurerm_virtual_machine_extension.monitor
  ]
}

# ========================================
# Local Values for Connection Instructions
# ========================================

locals {
  connection_instructions_with_ad = <<-EOT
    ===================================
    VM Connection Instructions
    ===================================
    
    1. Connect via Azure Bastion (Recommended):
       - Navigate to VM in Azure Portal
       - Click Connect → Bastion
       - Use Azure AD credentials
    
    2. Connect via Native SSH with Azure AD:
       az ssh vm --resource-group ${var.resource_group_name} \
                 --name ${var.vm_name}
    
    3. Connect via traditional SSH (from jumpbox):
       ssh ${var.admin_username}@${azurerm_network_interface.this.private_ip_address}
    
    VM Name: ${var.vm_name}
    Private IP: ${azurerm_network_interface.this.private_ip_address}
    Username: ${var.admin_username}
    Azure AD Login: Enabled
    ===================================
  EOT

  connection_instructions_without_ad = <<-EOT
    ===================================
    VM Connection Instructions
    ===================================
    
    Connect via SSH:
    ssh ${var.admin_username}@${azurerm_network_interface.this.private_ip_address}
    
    VM Name: ${var.vm_name}
    Private IP: ${azurerm_network_interface.this.private_ip_address}
    Username: ${var.admin_username}
    ===================================
  EOT
}
