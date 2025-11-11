# Network Rules
# Manages outbound Layer 3/4 network connectivity

# ========================================
# Network Rule Collection Group
# ========================================

resource "azurerm_firewall_policy_rule_collection_group" "network" {
  name               = "network-rules"
  firewall_policy_id = azurerm_firewall_policy.this.id
  priority           = 200

  # ========================================
  # Azure Services Access
  # ========================================
  network_rule_collection {
    name     = "allow-azure-services"
    priority = 100
    action   = "Allow"

    # Azure Monitor / Log Analytics
    rule {
      name = "allow-azure-monitor"
      protocols = ["TCP"]

      source_addresses = ["*"]

      destination_addresses = ["AzureMonitor"]
      destination_ports     = ["443"]
    }

    # Azure Storage (for diagnostics, backups)
    rule {
      name = "allow-azure-storage"
      protocols = ["TCP", "UDP"]

      source_addresses = ["*"]

      destination_addresses = ["Storage"]
      destination_ports     = ["443", "445"]  # HTTPS, SMB
    }

    # Azure Container Registry
    rule {
      name = "allow-azure-acr"
      protocols = ["TCP"]

      source_addresses = ["*"]

      destination_addresses = ["AzureContainerRegistry"]
      destination_ports     = ["443"]
    }

    # Azure Key Vault
    rule {
      name = "allow-azure-keyvault"
      protocols = ["TCP"]

      source_addresses = ["*"]

      destination_addresses = ["AzureKeyVault"]
      destination_ports     = ["443"]
    }

    # Azure SQL / PostgreSQL
    rule {
      name = "allow-azure-database"
      protocols = ["TCP"]

      source_addresses = ["*"]

      destination_addresses = ["Sql"]
      destination_ports     = ["1433", "5432"]
    }
  }

  # ========================================
  # AKS Required Outbound
  # ========================================
  network_rule_collection {
    name     = "allow-aks-required"
    priority = 110
    action   = "Allow"

    # AKS API Server (managed by Azure)
    rule {
      name = "allow-aks-apiserver"
      protocols = ["TCP"]

      source_addresses = ["*"]

      destination_addresses = ["AzureCloud"]
      destination_ports     = ["443", "9000"]
    }

    # NTP (Network Time Protocol) - Critical for AKS
    rule {
      name = "allow-ntp"
      protocols = ["UDP"]

      source_addresses = ["*"]

      destination_addresses = [
        "91.189.89.198",    # ntp.ubuntu.com
        "91.189.94.4",      # ntp.ubuntu.com
        "91.189.91.157",    # ntp.ubuntu.com
        "time.windows.com"
      ]
      destination_ports = ["123"]
    }

    # DNS (if not using Azure DNS)
    rule {
      name = "allow-external-dns"
      protocols = ["UDP", "TCP"]

      source_addresses = ["*"]

      destination_addresses = [
        "8.8.8.8",      # Google DNS
        "8.8.4.4",      # Google DNS
        "1.1.1.1",      # Cloudflare DNS
        "1.0.0.1"       # Cloudflare DNS
      ]
      destination_ports = ["53"]
    }
  }

  # ========================================
  # Custom Outbound Rules
  # ========================================
  network_rule_collection {
    name     = "allow-custom-outbound"
    priority = 120
    action   = "Allow"

    # Allow specific external IPs (customize as needed)
    rule {
      name = "allow-external-apis"
      protocols = ["TCP"]

      source_addresses = var.custom_source_addresses

      destination_addresses = var.custom_destination_addresses
      destination_ports     = var.custom_destination_ports
    }
  }

  # ========================================
  # Inter-VNet Communication
  # ========================================
  network_rule_collection {
    name     = "allow-vnet-to-vnet"
    priority = 130
    action   = "Allow"

    # Hub to Spoke
    rule {
      name = "allow-hub-to-spoke"
      protocols = ["Any"]

      source_addresses      = [var.hub_vnet_cidr]
      destination_addresses = [var.spoke_vnet_cidr]
      destination_ports     = ["*"]
    }

    # Spoke to Hub
    rule {
      name = "allow-spoke-to-hub"
      protocols = ["Any"]

      source_addresses      = [var.spoke_vnet_cidr]
      destination_addresses = [var.hub_vnet_cidr]
      destination_ports     = ["*"]
    }
  }

  # ========================================
  # Commented Examples - Additional Rules
  # ========================================

  # Example: Allow outbound to specific on-premises network
  # network_rule_collection {
  #   name     = "allow-to-onprem"
  #   priority = 140
  #   action   = "Allow"
  #
  #   rule {
  #     name = "allow-onprem-network"
  #     protocols = ["Any"]
  #     
  #     source_addresses      = ["*"]
  #     destination_addresses = ["192.168.0.0/16"]  # On-premises CIDR
  #     destination_ports     = ["*"]
  #   }
  # }

  # Example: Deny all other outbound traffic (explicit deny)
  # network_rule_collection {
  #   name     = "deny-all-other"
  #   priority = 999
  #   action   = "Deny"
  #
  #   rule {
  #     name = "deny-all"
  #     protocols = ["Any"]
  #     
  #     source_addresses      = ["*"]
  #     destination_addresses = ["*"]
  #     destination_ports     = ["*"]
  #   }
  # }

  depends_on = [
    azurerm_firewall_policy.this
  ]
}
