# Application Rules
# Manages outbound Layer 7 HTTP/HTTPS FQDN filtering

# ========================================
# Application Rule Collection Group
# ========================================

resource "azurerm_firewall_policy_rule_collection_group" "application" {
  name               = "application-rules"
  firewall_policy_id = azurerm_firewall_policy.this.id
  priority           = 300

  # ========================================
  # Azure Services FQDN Access
  # ========================================
  application_rule_collection {
    name     = "allow-azure-fqdns"
    priority = 100
    action   = "Allow"

    # Azure Management & ARM API
    rule {
      name = "allow-azure-management"

      source_addresses = ["*"]

      destination_fqdns = [
        "management.azure.com",
        "*.management.azure.com",
        "login.microsoftonline.com",
        "*.login.microsoftonline.com",
        "graph.windows.net"
      ]

      protocols {
        type = "Https"
        port = 443
      }
    }

    # Azure Container Registry
    rule {
      name = "allow-acr-fqdns"

      source_addresses = ["*"]

      destination_fqdns = [
        "*.azurecr.io",
        "*.blob.core.windows.net",  # ACR storage
        "mcr.microsoft.com",         # Microsoft Container Registry
        "*.data.mcr.microsoft.com"
      ]

      protocols {
        type = "Https"
        port = 443
      }
    }

    # Azure Key Vault
    rule {
      name = "allow-keyvault-fqdns"

      source_addresses = ["*"]

      destination_fqdns = [
        "*.vault.azure.net",
        "*.vaultcore.azure.net"
      ]

      protocols {
        type = "Https"
        port = 443
      }
    }

    # Azure Monitor / Log Analytics
    rule {
      name = "allow-monitoring-fqdns"

      source_addresses = ["*"]

      destination_fqdns = [
        "*.ods.opinsights.azure.com",
        "*.oms.opinsights.azure.com",
        "*.monitoring.azure.com",
        "dc.services.visualstudio.com"
      ]

      protocols {
        type = "Https"
        port = 443
      }
    }
  }

  # ========================================
  # AKS Required FQDNs
  # ========================================
  application_rule_collection {
    name     = "allow-aks-fqdns"
    priority = 110
    action   = "Allow"

    # AKS Core Dependencies
    rule {
      name = "allow-aks-core"

      source_addresses = ["*"]

      destination_fqdn_tags = [
        "AzureKubernetesService"
      ]

      protocols {
        type = "Https"
        port = 443
      }
    }

    # Ubuntu Package Updates
    rule {
      name = "allow-ubuntu-updates"

      source_addresses = ["*"]

      destination_fqdns = [
        "security.ubuntu.com",
        "azure.archive.ubuntu.com",
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

    # Kubernetes Package Repository
    rule {
      name = "allow-k8s-packages"

      source_addresses = ["*"]

      destination_fqdns = [
        "packages.cloud.google.com",
        "apt.kubernetes.io"
      ]

      protocols {
        type = "Https"
        port = 443
      }
    }

    # Microsoft Package Repository
    rule {
      name = "allow-microsoft-packages"

      source_addresses = ["*"]

      destination_fqdns = [
        "packages.microsoft.com"
      ]

      protocols {
        type = "Https"
        port = 443
      }
    }
  }

  # ========================================
  # Container Image Registries
  # ========================================
  application_rule_collection {
    name     = "allow-container-registries"
    priority = 120
    action   = "Allow"

    # Docker Hub
    rule {
      name = "allow-dockerhub"

      source_addresses = ["*"]

      destination_fqdns = [
        "hub.docker.com",
        "registry-1.docker.io",
        "*.docker.io",
        "production.cloudflare.docker.com"
      ]

      protocols {
        type = "Https"
        port = 443
      }
    }

    # GitHub Container Registry
    rule {
      name = "allow-ghcr"

      source_addresses = ["*"]

      destination_fqdns = [
        "ghcr.io",
        "*.ghcr.io"
      ]

      protocols {
        type = "Https"
        port = 443
      }
    }

    # Quay.io
    rule {
      name = "allow-quay"

      source_addresses = ["*"]

      destination_fqdns = [
        "quay.io",
        "*.quay.io"
      ]

      protocols {
        type = "Https"
        port = 443
      }
    }
  }

  # ========================================
  # Custom Application Rules
  # ========================================
  application_rule_collection {
    name     = "allow-custom-fqdns"
    priority = 130
    action   = "Allow"

    # Custom FQDNs (from variables)
    rule {
      name = "allow-custom-domains"

      source_addresses = var.custom_source_addresses

      destination_fqdns = var.custom_allowed_fqdns

      protocols {
        type = "Https"
        port = 443
      }

      protocols {
        type = "Http"
        port = 80
      }
    }
  }

  # ========================================
  # Development Tools (Optional - Comment out for production)
  # ========================================
  # application_rule_collection {
  #   name     = "allow-dev-tools"
  #   priority = 140
  #   action   = "Allow"
  #
  #   # GitHub
  #   rule {
  #     name = "allow-github"
  #     
  #     source_addresses = ["*"]
  #     
  #     destination_fqdns = [
  #       "github.com",
  #       "*.github.com",
  #       "raw.githubusercontent.com"
  #     ]
  #
  #     protocols {
  #       type = "Https"
  #       port = 443
  #     }
  #   }
  #
  #   # NPM Registry
  #   rule {
  #     name = "allow-npm"
  #     
  #     source_addresses = ["*"]
  #     
  #     destination_fqdns = [
  #       "registry.npmjs.org",
  #       "*.npmjs.org"
  #     ]
  #
  #     protocols {
  #       type = "Https"
  #       port = 443
  #     }
  #   }
  #
  #   # PyPI (Python packages)
  #   rule {
  #     name = "allow-pypi"
  #     
  #     source_addresses = ["*"]
  #     
  #     destination_fqdns = [
  #       "pypi.org",
  #       "*.pypi.org",
  #       "files.pythonhosted.org"
  #     ]
  #
  #     protocols {
  #       type = "Https"
  #       port = 443
  #     }
  #   }
  # }

  depends_on = [
    azurerm_firewall_policy.this
  ]
}
