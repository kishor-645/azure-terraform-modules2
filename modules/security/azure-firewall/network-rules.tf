# Network Rules
# Manages outbound Layer 3/4 network connectivity
# Based on Azure Firewall Policy requirements for AKS and Azure services

# ========================================
# Network Rule Collection Group
# ========================================

resource "azurerm_firewall_policy_rule_collection_group" "network" {
  name               = "network-rules"
  firewall_policy_id = azurerm_firewall_policy.this.id
  priority           = 200

  # ========================================
  # Azure Services - Priority 100
  # ========================================
  network_rule_collection {
    name     = "Azure-Services"
    priority = 100
    action   = "Allow"

    # Azure Services from AKS
    rule {
      name      = "Azure-Services"
      protocols = ["TCP"]

      source_addresses = ["10.1.16.0/22"]

      destination_addresses = ["AzureCloud.CanadaCentral"]
      destination_ports     = ["443"]
    }
  }

  # ========================================
  # DNS - Priority 110
  # ========================================
  network_rule_collection {
    name     = "DNS"
    priority = 110
    action   = "Allow"

    # DNS/NTP from Hub and Spoke
    rule {
      name      = "DNS-NTP"
      protocols = ["TCP", "UDP"]

      source_addresses = [
        "10.0.0.0/16", # Hub VNet
        "10.1.0.0/16"  # Spoke VNet
      ]

      destination_addresses = ["*"]
      destination_ports     = ["53", "123"]
    }
  }

  # ========================================
  # NTP - Priority 120
  # ========================================
  network_rule_collection {
    name     = "NTP"
    priority = 120
    action   = "Allow"

    # NTP from AKS
    rule {
      name      = "NTP"
      protocols = ["UDP"]

      source_addresses = ["10.1.16.0/22"]

      destination_addresses = ["*"]
      destination_ports     = ["123"]
    }
  }

  # ========================================
  # Database - Priority 130
  # ========================================
  network_rule_collection {
    name     = "Database"
    priority = 130
    action   = "Allow"

    # PostgreSQL from AKS
    rule {
      name      = "Postgresql"
      protocols = ["TCP"]

      source_addresses = ["10.1.16.0/22"]

      destination_addresses = ["10.1.29.0/24"] # Private endpoints subnet
      destination_ports     = ["5432"]
    }
  }

  # ========================================
  # Jumpbox-Internet - Priority 200
  # ========================================
  network_rule_collection {
    name     = "Jumpbox-Internet"
    priority = 200
    action   = "Allow"

    # Jumpbox Internet Access
    rule {
      name      = "Jumpbox-Internet"
      protocols = ["TCP"]

      source_addresses = [
        "10.0.4.0/24",   # Hub shared services subnet
        "10.1.30.128/27" # Spoke jumpbox subnet
      ]

      destination_addresses = ["*"]
      destination_ports     = ["80", "443"]
    }
  }

  depends_on = [
    azurerm_firewall_policy.this
  ]
}
