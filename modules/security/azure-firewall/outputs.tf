# Azure Firewall Module Outputs

# ========================================
# Firewall Outputs
# ========================================

output "firewall_id" {
  description = "The ID of the Azure Firewall"
  value       = azurerm_firewall.this.id
}

output "firewall_name" {
  description = "The name of the Azure Firewall"
  value       = azurerm_firewall.this.name
}

output "firewall_private_ip" {
  description = "The private IP address of the Azure Firewall (typically .4 in subnet)"
  value       = azurerm_firewall.this.ip_configuration[0].private_ip_address
}

output "firewall_public_ip" {
  description = "The public IP address of the Azure Firewall"
  value       = azurerm_public_ip.firewall.ip_address
}

output "firewall_management_public_ip" {
  description = "The management public IP address of the Azure Firewall"
  value       = azurerm_public_ip.firewall_management.ip_address
}

# ========================================
# Firewall Policy Outputs
# ========================================

output "firewall_policy_id" {
  description = "The ID of the Firewall Policy"
  value       = azurerm_firewall_policy.this.id
}

output "firewall_policy_name" {
  description = "The name of the Firewall Policy"
  value       = azurerm_firewall_policy.this.name
}

# ========================================
# Public IP Resource IDs
# ========================================

output "firewall_public_ip_id" {
  description = "The resource ID of the Firewall public IP"
  value       = azurerm_public_ip.firewall.id
}

output "firewall_management_public_ip_id" {
  description = "The resource ID of the Firewall management public IP"
  value       = azurerm_public_ip.firewall_management.id
}

# ========================================
# Cloudflare IP Ranges (for reference)
# ========================================

output "cloudflare_ip_ranges_used" {
  description = "List of Cloudflare IP ranges used in DNAT rules"
  value       = local.cloudflare_all_ips
  sensitive   = false
}

output "cloudflare_ipv4_count" {
  description = "Number of Cloudflare IPv4 ranges configured"
  value       = length(local.cloudflare_ipv4_list)
}

# ========================================
# Firewall Configuration Details
# ========================================

output "firewall_sku" {
  description = "The SKU tier of the Azure Firewall"
  value       = azurerm_firewall.this.sku_tier
}

output "firewall_zones" {
  description = "The availability zones of the Azure Firewall"
  value       = azurerm_firewall.this.zones
}

output "threat_intelligence_mode" {
  description = "The threat intelligence mode of the Firewall Policy"
  value       = azurerm_firewall_policy.this.threat_intelligence_mode
}

output "idps_mode" {
  description = "The IDPS mode of the Firewall Policy"
  value       = azurerm_firewall_policy.this.intrusion_detection[0].mode
}

output "dns_proxy_enabled" {
  description = "Whether DNS proxy is enabled on the Firewall Policy"
  value       = azurerm_firewall_policy.this.dns[0].proxy_enabled
}

# ========================================
# Consolidated Output for UDR Configuration
# ========================================

output "firewall_routing_config" {
  description = "Consolidated firewall routing configuration for UDR module"
  value = {
    firewall_private_ip = azurerm_firewall.this.ip_configuration[0].private_ip_address
    firewall_name       = azurerm_firewall.this.name
    firewall_id         = azurerm_firewall.this.id
  }
}

# ========================================
# Consolidated Output for Reference
# ========================================

output "firewall_details" {
  description = "Consolidated details of the Azure Firewall deployment"
  value = {
    firewall = {
      id                = azurerm_firewall.this.id
      name              = azurerm_firewall.this.name
      private_ip        = azurerm_firewall.this.ip_configuration[0].private_ip_address
      public_ip         = azurerm_public_ip.firewall.ip_address
      management_ip     = azurerm_public_ip.firewall_management.ip_address
      sku_tier          = azurerm_firewall.this.sku_tier
      zones             = azurerm_firewall.this.zones
    }
    policy = {
      id                       = azurerm_firewall_policy.this.id
      name                     = azurerm_firewall_policy.this.name
      threat_intelligence_mode = azurerm_firewall_policy.this.threat_intelligence_mode
      idps_mode                = azurerm_firewall_policy.this.intrusion_detection[0].mode
      dns_proxy_enabled        = azurerm_firewall_policy.this.dns[0].proxy_enabled
    }
    dnat = {
      internal_lb_ip            = var.internal_lb_ip
      cloudflare_ips_count      = length(local.cloudflare_all_ips)
      fetch_dynamically_enabled = var.fetch_cloudflare_ips_dynamically
    }
  }
}

# ========================================
# Deployment Status Output
# ========================================

output "deployment_status" {
  description = "Status message for firewall deployment"
  value = var.internal_lb_ip == "" ? "⚠️  DNAT rules created but internal_lb_ip is empty - update after AKS deployment" : "✅ Firewall deployed successfully with DNAT rules configured"
}
