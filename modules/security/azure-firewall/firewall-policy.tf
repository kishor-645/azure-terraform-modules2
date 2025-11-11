# Firewall Policy Configuration
# Defines the Azure Firewall policy with IDPS and threat intelligence

# ========================================
# Firewall Policy
# ========================================

resource "azurerm_firewall_policy" "this" {
  name                     = var.firewall_policy_name
  location                 = var.location
  resource_group_name      = var.resource_group_name
  sku                      = "Premium"
  threat_intelligence_mode = var.threat_intelligence_mode

  # DNS Settings
  dns {
    proxy_enabled = true
    servers       = var.custom_dns_servers
  }

  # Intrusion Detection and Prevention System (IDPS)
  intrusion_detection {
    mode = var.idps_mode

    # Signature overrides (optional - customize per deployment)
    dynamic "signature_overrides" {
      for_each = var.idps_signature_overrides
      content {
        id    = signature_overrides.value.id
        state = signature_overrides.value.state
      }
    }

    # Traffic bypass rules (optional)
    dynamic "traffic_bypass" {
      for_each = var.idps_traffic_bypass
      content {
        name                  = traffic_bypass.value.name
        protocol              = traffic_bypass.value.protocol
        description           = traffic_bypass.value.description
        destination_addresses = traffic_bypass.value.destination_addresses
        destination_ports     = traffic_bypass.value.destination_ports
        source_addresses      = traffic_bypass.value.source_addresses
        source_ip_groups      = traffic_bypass.value.source_ip_groups
      }
    }
  }

  # Threat Intelligence Allowlist (optional)
  dynamic "threat_intelligence_allowlist" {
    for_each = length(var.threat_intel_allowlist_ips) > 0 || length(var.threat_intel_allowlist_fqdns) > 0 ? [1] : []
    content {
      ip_addresses = var.threat_intel_allowlist_ips
      fqdns        = var.threat_intel_allowlist_fqdns
    }
  }

  # TLS Inspection (Premium feature - requires certificate)
  dynamic "tls_certificate" {
    for_each = var.enable_tls_inspection ? [1] : []
    content {
      key_vault_secret_id = var.tls_certificate_key_vault_secret_id
      name                = var.tls_certificate_name
    }
  }

  tags = merge(
    var.tags,
    {
      PolicyType = "Premium"
    }
  )
}
