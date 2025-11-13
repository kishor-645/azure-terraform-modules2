# Linux VM Module Outputs

# ========================================
# VM Outputs
# ========================================

output "vm_id" {
  description = "The ID of the Linux VM"
  value       = azurerm_linux_virtual_machine.this.id
}

output "vm_name" {
  description = "The name of the Linux VM"
  value       = azurerm_linux_virtual_machine.this.name
}

output "vm_private_ip" {
  description = "The private IP address of the Linux VM"
  value       = azurerm_network_interface.this.private_ip_address
}

output "vm_identity_principal_id" {
  description = "The principal ID of the VM's system-assigned managed identity"
  value       = azurerm_linux_virtual_machine.this.identity[0].principal_id
}

output "vm_identity_tenant_id" {
  description = "The tenant ID of the VM's system-assigned managed identity"
  value       = azurerm_linux_virtual_machine.this.identity[0].tenant_id
}

# ========================================
# Network Interface Outputs
# ========================================

output "nic_id" {
  description = "The ID of the network interface"
  value       = azurerm_network_interface.this.id
}

output "nic_name" {
  description = "The name of the network interface"
  value       = azurerm_network_interface.this.name
}

# ========================================
# Consolidated Output
# ========================================

output "vm_details" {
  description = "Consolidated VM details"
  value = {
    id                     = azurerm_linux_virtual_machine.this.id
    name                   = azurerm_linux_virtual_machine.this.name
    private_ip             = azurerm_network_interface.this.private_ip_address
    size                   = azurerm_linux_virtual_machine.this.size
    admin_username         = azurerm_linux_virtual_machine.this.admin_username
    identity_principal_id  = azurerm_linux_virtual_machine.this.identity[0].principal_id
    azure_ad_login_enabled = var.enable_azure_ad_login
    monitoring_enabled     = var.enable_monitoring
  }
}

# ========================================
# Connection Instructions
# ========================================

output "connection_instructions" {
  description = "Instructions for connecting to the VM"
  value       = var.enable_azure_ad_login ? local.connection_instructions_with_ad : local.connection_instructions_without_ad
}
