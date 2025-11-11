# Azure Bastion Module Outputs

# ========================================
# Bastion Host Outputs
# ========================================

output "bastion_id" {
  description = "The ID of the Azure Bastion host"
  value       = azurerm_bastion_host.this.id
}

output "bastion_name" {
  description = "The name of the Azure Bastion host"
  value       = azurerm_bastion_host.this.name
}

output "bastion_dns_name" {
  description = "The DNS name of the Azure Bastion host"
  value       = azurerm_bastion_host.this.dns_name
}

output "bastion_location" {
  description = "The location of the Azure Bastion host"
  value       = azurerm_bastion_host.this.location
}

output "bastion_sku" {
  description = "The SKU of the Azure Bastion host"
  value       = azurerm_bastion_host.this.sku
}

# ========================================
# Public IP Outputs
# ========================================

output "bastion_public_ip" {
  description = "The public IP address of the Azure Bastion host"
  value       = azurerm_public_ip.bastion.ip_address
}

output "bastion_public_ip_id" {
  description = "The resource ID of the Bastion public IP"
  value       = azurerm_public_ip.bastion.id
}

output "bastion_public_ip_fqdn" {
  description = "The FQDN of the Bastion public IP (if configured)"
  value       = azurerm_public_ip.bastion.fqdn
}

# ========================================
# Feature Status Outputs
# ========================================

output "copy_paste_enabled" {
  description = "Whether copy/paste is enabled"
  value       = azurerm_bastion_host.this.copy_paste_enabled
}

output "file_copy_enabled" {
  description = "Whether file copy is enabled"
  value       = azurerm_bastion_host.this.file_copy_enabled
}

output "ip_connect_enabled" {
  description = "Whether IP-based connections are enabled"
  value       = azurerm_bastion_host.this.ip_connect_enabled
}

output "shareable_link_enabled" {
  description = "Whether shareable links are enabled"
  value       = azurerm_bastion_host.this.shareable_link_enabled
}

output "tunneling_enabled" {
  description = "Whether native client tunneling is enabled"
  value       = azurerm_bastion_host.this.tunneling_enabled
}

output "scale_units" {
  description = "Number of scale units configured"
  value       = azurerm_bastion_host.this.scale_units
}

# ========================================
# Consolidated Output
# ========================================

output "bastion_details" {
  description = "Consolidated Azure Bastion details"
  value = {
    id                     = azurerm_bastion_host.this.id
    name                   = azurerm_bastion_host.this.name
    dns_name               = azurerm_bastion_host.this.dns_name
    public_ip              = azurerm_public_ip.bastion.ip_address
    sku                    = azurerm_bastion_host.this.sku
    scale_units            = azurerm_bastion_host.this.scale_units
    copy_paste_enabled     = azurerm_bastion_host.this.copy_paste_enabled
    file_copy_enabled      = azurerm_bastion_host.this.file_copy_enabled
    ip_connect_enabled     = azurerm_bastion_host.this.ip_connect_enabled
    shareable_link_enabled = azurerm_bastion_host.this.shareable_link_enabled
    tunneling_enabled      = azurerm_bastion_host.this.tunneling_enabled
  }
}
