# Application Rules
# Manages outbound Layer 7 HTTP/HTTPS FQDN filtering
# Based on Azure Firewall Policy requirements for AKS and Azure services

# ========================================
# Application Rule Collection Group
# ========================================

resource "azurerm_firewall_policy_rule_collection_group" "application" {
  name               = "application-rules"
  firewall_policy_id = azurerm_firewall_policy.this.id
  priority           = 300

  # ========================================
  # AKS Control Plane - Priority 100
  # ========================================
  application_rule_collection {
    name     = "AKS-Control-Plane"
    priority = 100
    action   = "Allow"

    # AKS API Server Access
    rule {
      name = "AKS-API"

      source_addresses = ["10.1.16.0/22"] # AKS node subnet

      destination_fqdns = [
        "*.hcp.canadacentral.azmk8s.io",
        "mcr.microsoft.com",
        "*.data.mcr.microsoft.com",
        "management.azure.com",
        "login.microsoftonline.com",
        "packages.microsoft.com",
        "acs-mirror.azureedge.net"
      ]

      protocols {
        type = "Https"
        port = 443
      }
    }

    # AKS Tunnel
    rule {
      name = "AKS-Tunnel"

      source_addresses = ["10.1.16.0/22"]

      destination_fqdns = [
        "*.tun.canadacentral.azmk8s.io"
      ]

      protocols {
        type = "Https"
        port = 443
      }

      protocols {
        type = "Https"
        port = 9000
      }
    }
  }

  # ========================================
  # Azure Services - Priority 110
  # ========================================
  application_rule_collection {
    name     = "Azure-Services"
    priority = 110
    action   = "Allow"

    # Azure Services
    rule {
      name = "Azure-Services"

      source_addresses = ["10.1.16.0/22"]

      destination_fqdns = [
        "*.canadacentral.azmk8s.io",
        "mcr.microsoft.com",
        "*.data.mcr.microsoft.com",
        "management.azure.com",
        "login.microsoftonline.com",
        "*.login.microsoft.com",
        "*.login.microsoftonline.com",
        "packages.microsoft.com",
        "acs-mirror.azureedge.net"
      ]

      protocols {
        type = "Https"
        port = 443
      }
    }

    # Azure Login
    rule {
      name = "Azure-Login"

      source_addresses = ["10.1.16.0/22"]

      destination_fqdns = [
        "login.microsoftonline.com",
        "*.login.microsoftonline.com",
        "login.microsoft.com",
        "*.login.microsoft.com"
      ]

      protocols {
        type = "Https"
        port = 443
      }
    }

    # Azure Monitor
    rule {
      name = "Azure-Monitor"

      source_addresses = ["10.1.16.0/22"]

      destination_fqdns = [
        "*.ods.opinsights.azure.com",
        "*.oms.opinsights.azure.com",
        "*.monitoring.azure.com",
        "*.services.visualstudio.com",
        "dc.services.visualstudio.com"
      ]

      protocols {
        type = "Https"
        port = 443
      }
    }
  }

  # ========================================
  # Container Registries - Priority 120
  # ========================================
  application_rule_collection {
    name     = "Container_Registries"
    priority = 120
    action   = "Allow"

    # Microsoft Container Registry
    rule {
      name = "MCR"

      source_addresses = ["10.1.16.0/22"]

      destination_fqdns = [
        "mcr.microsoft.com",
        "*.data.mcr.microsoft.com"
      ]

      protocols {
        type = "Https"
        port = 443
      }
    }

    # Custom ACR
    rule {
      name = "Custom-ACR"

      source_addresses = ["10.1.16.0/22"]

      destination_fqdns = [
        "*.azurecr.io",
        "*.blob.core.windows.net"
      ]

      protocols {
        type = "Https"
        port = 443
      }
    }
  }

  # ========================================
  # Allow HTTPS Test - Priority 130
  # ========================================
  application_rule_collection {
    name     = "Allow-HTTPS-Test"
    priority = 130
    action   = "Allow"

    # Allow Dockerhub
    rule {
      name = "Allow-Dockerhub"

      source_addresses = ["10.1.16.0/22"]

      destination_fqdns = [
        "*.docker.io",
        "*.docker.com",
        "auth.docker.io",
        "registry-1.docker.io",
        "index.docker.io",
        "dseasb33srnrn.cloudfront.net",
        "production.cloudflare.docker.com"
      ]

      protocols {
        type = "Https"
        port = 443
      }
    }

    # Allow Azure File and Blob
    rule {
      name = "Allow-Azure-Storage"

      source_addresses = ["10.1.16.0/22"]

      destination_fqdns = [
        "*.blob.core.windows.net",
        "*.file.core.windows.net"
      ]

      protocols {
        type = "Https"
        port = 443
      }
    }
  }

  # ========================================
  # OS Updates - Priority 140
  # ========================================
  application_rule_collection {
    name     = "OS-Updates"
    priority = 140
    action   = "Allow"

    # Ubuntu Updates
    rule {
      name = "Ubuntu-Updates"

      source_addresses = ["10.1.16.0/22"]

      destination_fqdns = [
        "security.ubuntu.com",
        "azure.archive.ubuntu.com",
        "archive.ubuntu.com",
        "changelogs.ubuntu.com"
      ]

      protocols {
        type = "Http"
        port = 80
      }

      protocols {
        type = "Https"
        port = 443
      }
    }
  }

  depends_on = [
    azurerm_firewall_policy.this
  ]
}
