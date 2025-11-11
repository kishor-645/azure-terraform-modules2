# Terraform Modules Guide

Complete guide for using and understanding all Terraform modules in this infrastructure.

## Table of Contents

1. [Overview](#overview)
2. [How to Use Modules](#how-to-use-modules)
3. [Networking Modules](#networking-modules)
4. [Security Modules](#security-modules)
5. [Compute Modules](#compute-modules)
6. [Storage Modules](#storage-modules)
7. [Data Modules](#data-modules)
8. [Monitoring Modules](#monitoring-modules)
9. [Module Best Practices](#module-best-practices)

---

## Overview

This infrastructure uses **reusable Terraform modules** organized by category. Each module is self-contained and can be used independently or as part of the complete infrastructure.

### Module Structure

All modules follow a consistent structure:

```
modules/
├── <category>/              # networking, security, compute, storage, data, monitoring
│   └── <module-name>/
│       ├── main.tf          # Main resource definitions
│       ├── variables.tf     # Input variables with validation
│       ├── outputs.tf       # Output values for other modules
│       └── README.md        # Module-specific documentation
```

### Module Categories

| Category | Purpose | Modules |
|----------|---------|---------|
| **networking** | Network infrastructure | hub-vnet, spoke-vnet, vnet-peering, private-dns-zone |
| **security** | Security resources | azure-firewall, bastion, nsg, route-table |
| **compute** | Compute resources | aks-cluster, linux-vm |
| **storage** | Storage services | storage-account, container-registry, key-vault, file-share |
| **data** | Database services | postgresql-flexible |
| **monitoring** | Observability | log-analytics, application-insights, action-group |

---

## How to Use Modules

### Basic Usage Pattern

```hcl
module "module_name" {
  source = "../../modules/<category>/<module-name>"

  # Required variables
  name                = "resource-name"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.region

  # Optional variables
  tags = var.tags
}
```

### Accessing Module Outputs

```hcl
# Reference outputs from other modules
module "spoke_vnet" {
  source = "../../modules/networking/spoke-vnet"
  # ... variables ...
}

# Use the output in another module
module "aks_cluster" {
  source = "../../modules/compute/aks-cluster"

  subnet_id = module.spoke_vnet.aks_subnet_id  # Using output from spoke_vnet
  # ... other variables ...
}
```

### Example: Complete Hub-Spoke Network

```hcl
# Hub VNet
module "hub_vnet" {
  source = "../../modules/networking/hub-vnet"

  vnet_name           = "vnet-hub-canadacentral-prod"
  address_space       = ["10.0.0.0/16"]
  resource_group_name = azurerm_resource_group.main.name
  location            = "canadacentral"
  tags                = var.tags
}

# Spoke VNet
module "spoke_vnet" {
  source = "../../modules/networking/spoke-vnet"

  vnet_name           = "vnet-spoke-canadacentral-prod"
  address_space       = ["10.1.0.0/16"]
  resource_group_name = azurerm_resource_group.main.name
  location            = "canadacentral"
  tags                = var.tags
}

# VNet Peering
module "vnet_peering" {
  source = "../../modules/networking/vnet-peering"

  hub_vnet_name       = module.hub_vnet.vnet_name
  hub_vnet_id         = module.hub_vnet.vnet_id
  spoke_vnet_name     = module.spoke_vnet.vnet_name
  spoke_vnet_id       = module.spoke_vnet.vnet_id
  resource_group_name = azurerm_resource_group.main.name
}
```

---

## Networking Modules

### 1. hub-vnet

Creates the hub virtual network with centralized services.

**Path**: `modules/networking/hub-vnet/`

**Purpose**: Central hub for shared services, firewall, and bastion.

**Usage Example**:
```hcl
module "hub_vnet" {
  source = "../../modules/networking/hub-vnet"

  vnet_name           = "vnet-hub-canadacentral-prod"
  address_space       = ["10.0.0.0/16"]
  resource_group_name = azurerm_resource_group.main.name
  location            = "canadacentral"

  # Subnet CIDRs
  firewall_subnet_cidr            = "10.0.1.0/26"
  firewall_management_subnet_cidr = "10.0.2.0/26"
  bastion_subnet_cidr             = "10.0.3.0/27"
  shared_services_subnet_cidr     = "10.0.4.0/24"

  tags = var.tags
}
```

**Subnets Created**:
- `AzureFirewallSubnet` - For Azure Firewall (must be /26)
- `AzureFirewallManagementSubnet` - For Firewall management (must be /26)
- `AzureBastionSubnet` - For Azure Bastion (must be /27 minimum)
- `SharedServicesSubnet` - For jumpbox and agent VMs

**Key Outputs**:
```hcl
output "vnet_id"                    # Hub VNet resource ID
output "vnet_name"                  # Hub VNet name
output "firewall_subnet_id"         # Firewall subnet ID
output "bastion_subnet_id"          # Bastion subnet ID
output "shared_services_subnet_id"  # Shared services subnet ID
```

---

### 2. spoke-vnet

Creates the spoke virtual network for workloads.

**Path**: `modules/networking/spoke-vnet/`

**Purpose**: Workload VNet for AKS, private endpoints, and application resources.

**Usage Example**:
```hcl
module "spoke_vnet" {
  source = "../../modules/networking/spoke-vnet"

  vnet_name           = "vnet-spoke-canadacentral-prod"
  address_space       = ["10.1.0.0/16"]
  resource_group_name = azurerm_resource_group.main.name
  location            = "canadacentral"

  # Subnet CIDRs
  aks_subnet_cidr              = "10.1.0.0/20"   # 4,096 IPs - shared by all node pools
  private_endpoint_subnet_cidr = "10.1.16.0/24"  # 256 IPs
  app_gateway_subnet_cidr      = "10.1.17.0/24"  # 256 IPs

  tags = var.tags
}
```

**Subnets Created**:
- `AksSubnet` - **Shared by system and user node pools** (large /20 for scalability)
- `PrivateEndpointSubnet` - For all private endpoints
- `AppGatewaySubnet` - For Application Gateway (if used)

**Key Outputs**:
```hcl
output "vnet_id"                      # Spoke VNet resource ID
output "vnet_name"                    # Spoke VNet name
output "aks_subnet_id"                # AKS subnet ID (shared)
output "private_endpoint_subnet_id"   # Private endpoint subnet ID
output "app_gateway_subnet_id"        # App Gateway subnet ID
```

**Important**: The AKS subnet is shared between system and user node pools. This simplifies routing and security while maintaining isolation through Kubernetes network policies.

---

### 3. vnet-peering

Creates bidirectional VNet peering between hub and spoke.

**Path**: `modules/networking/vnet-peering/`

**Purpose**: Connect hub and spoke VNets for traffic flow.

**Usage Example**:
```hcl
module "vnet_peering" {
  source = "../../modules/networking/vnet-peering"

  hub_vnet_name       = module.hub_vnet.vnet_name
  hub_vnet_id         = module.hub_vnet.vnet_id
  spoke_vnet_name     = module.spoke_vnet.vnet_name
  spoke_vnet_id       = module.spoke_vnet.vnet_id
  resource_group_name = azurerm_resource_group.main.name

  allow_forwarded_traffic = true
  allow_gateway_transit   = false
}
```

**Creates**:
- Hub-to-Spoke peering
- Spoke-to-Hub peering

**Key Outputs**:
```hcl
output "hub_to_spoke_peering_id"   # Hub-to-Spoke peering ID
output "spoke_to_hub_peering_id"   # Spoke-to-Hub peering ID
```

---

### 4. private-dns-zone

Creates Azure Private DNS zones for private endpoint name resolution.

**Path**: `modules/networking/private-dns-zone/`

**Purpose**: DNS resolution for private endpoints.

**Usage Example**:
```hcl
module "private_dns_postgres" {
  source = "../../modules/networking/private-dns-zone"

  zone_name           = "privatelink.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.main.name

  # Link to both hub and spoke VNets
  vnet_links = {
    hub = {
      vnet_id             = module.hub_vnet.vnet_id
      registration_enabled = false
    }
    spoke = {
      vnet_id             = module.spoke_vnet.vnet_id
      registration_enabled = false
    }
  }

  tags = var.tags
}
```

**Supported DNS Zones**:
- `privatelink.postgres.database.azure.com` - PostgreSQL
- `privatelink.blob.core.windows.net` - Storage Blob
- `privatelink.file.core.windows.net` - Storage File
- `privatelink.vaultcore.azure.net` - Key Vault
- `privatelink.azurecr.io` - Container Registry

**Key Outputs**:
```hcl
output "dns_zone_id"    # DNS zone resource ID
output "dns_zone_name"  # DNS zone name
```

---

**Key Variables:**
- `dns_zone_name` - DNS zone name
- `linked_vnet_ids` - List of VNet IDs to link

**Usage Example:**
```hcl
module "private_dns_zones" {
  source = "../../../modules/networking/private-dns-zone"
  
  for_each = {
    acr      = "privatelink.azurecr.io"
    keyvault = "privatelink.vaultcore.azure.net"
    blob     = "privatelink.blob.core.windows.net"
  }
  
  dns_zone_name       = each.value
  resource_group_name = azurerm_resource_group.main.name
  linked_vnet_ids     = [module.spoke_vnet.vnet_id]
}
```

## Security Modules

### 1. azure-firewall

**Path**: `modules/security/azure-firewall/`
**Purpose**: Centralized network security with IDPS and threat intelligence

**Usage**:
```hcl
module "firewall" {
  source = "../../modules/security/azure-firewall"

  firewall_name               = "afw-erp-cc-prod"
  resource_group_name         = azurerm_resource_group.main.name
  location                    = "canadacentral"
  firewall_subnet_id          = module.hub_vnet.firewall_subnet_id
  threat_intelligence_mode    = "Alert"
  idps_mode                   = "Alert"
  log_analytics_workspace_id  = module.log_analytics.workspace_id
  tags                        = var.tags
}
```

**Outputs**: `firewall_private_ip`, `firewall_public_ip`

---

### 2. bastion

**Path**: `modules/security/bastion/`
**Purpose**: Secure RDP/SSH access to VMs

**Usage**:
```hcl
module "bastion" {
  source = "../../modules/security/bastion"

  bastion_name        = "bas-erp-cc-prod"
  resource_group_name = azurerm_resource_group.main.name
  location            = "canadacentral"
  bastion_subnet_id   = module.hub_vnet.bastion_subnet_id
  sku                 = "Standard"
  tags                = var.tags
}
```

**Outputs**: `bastion_id`, `bastion_dns_name`

---

### 3. nsg

**Path**: `modules/security/nsg/`
**Purpose**: Network security rules for subnets

**Usage**:
```hcl
module "nsg_aks" {
  source = "../../modules/security/nsg"

  nsg_name            = "nsg-aks-cc-prod"
  resource_group_name = azurerm_resource_group.main.name
  location            = "canadacentral"
  security_rules      = [
    {
      name                       = "AllowHttps"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      destination_port_range     = "443"
      source_address_prefix      = "10.0.0.0/16"
      destination_address_prefix = "*"
    }
  ]
  tags = var.tags
}
```

**Outputs**: `nsg_id`, `nsg_name`

---

### 4. route-table

**Path**: `modules/security/route-table/`
**Purpose**: Custom routing (e.g., force tunneling through firewall)

**Usage**:
```hcl
module "route_table" {
  source = "../../modules/security/route-table"

  route_table_name              = "rt-aks-cc-prod"
  resource_group_name           = azurerm_resource_group.main.name
  location                      = "canadacentral"
  disable_bgp_route_propagation = true
  routes = [
    {
      name                   = "DefaultToFirewall"
      address_prefix         = "0.0.0.0/0"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = module.firewall.firewall_private_ip
    }
  ]
  tags = var.tags
}
```

**Outputs**: `route_table_id`, `route_table_name`

---
## Compute Modules

### 1. aks-cluster

**Path**: `modules/compute/aks-cluster/`
**Purpose**: Private AKS cluster with Istio service mesh (inbuilt)

**Usage**:
```hcl
module "aks" {
  source = "../../modules/compute/aks-cluster"

  cluster_name            = "aks-erp-cc-prod"
  resource_group_name     = azurerm_resource_group.main.name
  location                = "canadacentral"
  kubernetes_version      = "1.28"

  # Network configuration
  aks_subnet_id           = module.spoke_vnet.aks_subnet_id  # Shared subnet
  service_cidr            = "10.100.0.0/16"
  dns_service_ip          = "10.100.0.10"
  pod_cidr                = "10.244.0.0/16"
  outbound_type           = var.deployment_stage == "stage1" ? "loadBalancer" : "userDefinedRouting"

  # Istio configuration (inbuilt feature)
  istio_enabled                        = true
  istio_internal_ingress_gateway_enabled = true
  istio_external_ingress_gateway_enabled = false

  # Node pools (both use same subnet)
  system_node_count       = 2
  system_node_vm_size     = "Standard_D4s_v3"
  user_node_count         = 2
  user_node_vm_size       = "Standard_D8s_v3"

  # Monitoring
  log_analytics_workspace_id = module.log_analytics.workspace_id

  tags = var.tags
}
```

**Key Features**:
- **Shared AKS Subnet**: System and user node pools use the same subnet
- **Istio Inbuilt**: No manual installation needed
- **Private Cluster**: No public API endpoint
- **Two-Stage Deployment**: loadBalancer → userDefinedRouting

**Outputs**: `cluster_name`, `cluster_id`, `cluster_private_fqdn`

---

### 2. linux-vm

**Path**: `modules/compute/linux-vm/`
**Purpose**: Linux VMs for jumpbox and Azure DevOps agents

**Usage**:
```hcl
module "jumpbox" {
  source = "../../modules/compute/linux-vm"

  vm_name             = "vm-jumpbox-cc-prod"
  resource_group_name = azurerm_resource_group.main.name
  location            = "canadacentral"
  subnet_id           = module.hub_vnet.shared_services_subnet_id
  vm_size             = "Standard_B2s"
  admin_username      = var.jumpbox_admin_username
  admin_password      = var.jumpbox_admin_password
  ssh_public_key      = var.ssh_public_key
  tags                = var.tags
}
```

**Outputs**: `vm_id`, `private_ip_address`, `network_interface_id`

---
## Storage Modules

### 1. storage-account

**Path**: `modules/storage/storage-account/`
**Purpose**: Azure Storage with private endpoints for blob and file

**Usage**:
```hcl
module "storage" {
  source = "../../modules/storage/storage-account"

  storage_account_name    = "sterp${random_string.unique.result}ccprod"
  resource_group_name     = azurerm_resource_group.main.name
  location                = "canadacentral"
  account_tier            = "Standard"
  account_replication_type = "GRS"

  # Private endpoints
  enable_blob_private_endpoint = true
  enable_file_private_endpoint = true
  private_endpoint_subnet_id   = module.spoke_vnet.private_endpoint_subnet_id

  tags = var.tags
}
```

**Outputs**: `storage_account_id`, `primary_blob_endpoint`, `primary_file_endpoint`

---

### 2. container-registry

**Path**: `modules/storage/container-registry/`
**Purpose**: Azure Container Registry with private endpoint

**Usage**:
```hcl
module "acr" {
  source = "../../modules/storage/container-registry"

  registry_name          = "acrerp${random_string.unique.result}ccprod"
  resource_group_name    = azurerm_resource_group.main.name
  location               = "canadacentral"
  sku                    = "Premium"  # Required for private endpoints
  admin_enabled          = false

  # Private endpoint
  enable_private_endpoint      = true
  private_endpoint_subnet_id   = module.spoke_vnet.private_endpoint_subnet_id
  private_dns_zone_id          = module.private_dns_acr.dns_zone_id

  tags = var.tags
}
```

**Outputs**: `registry_id`, `login_server`, `admin_username`

---

### 3. key-vault

**Path**: `modules/storage/key-vault/`
**Purpose**: Azure Key Vault with private endpoint and RBAC

**Usage**:
```hcl
module "key_vault" {
  source = "../../modules/storage/key-vault"

  key_vault_name      = "kv-erp-${random_string.unique.result}-cc-prod"
  resource_group_name = azurerm_resource_group.main.name
  location            = "canadacentral"
  sku_name            = "standard"

  # RBAC authorization
  enable_rbac_authorization = true

  # Private endpoint
  enable_private_endpoint    = true
  private_endpoint_subnet_id = module.spoke_vnet.private_endpoint_subnet_id
  private_dns_zone_id        = module.private_dns_kv.dns_zone_id

  tags = var.tags
}
```

**Outputs**: `key_vault_id`, `key_vault_uri`, `key_vault_name`

---

### 4. file-share

**Path**: `modules/storage/file-share/`
**Purpose**: Azure File Share for shared storage

**Usage**:
```hcl
module "file_share" {
  source = "../../modules/storage/file-share"

  share_name          = "erp-shared-files"
  storage_account_name = module.storage.storage_account_name
  quota               = 100  # GB
}
```

**Outputs**: `file_share_id`, `file_share_url`

---

## Data Modules

### 1. postgresql-flexible

**Path**: `modules/data/postgresql-flexible/`
**Purpose**: PostgreSQL Flexible Server with private endpoint

**Usage**:
```hcl
module "postgresql" {
  source = "../../modules/data/postgresql-flexible"

  server_name             = "psql-erp-cc-prod"
  resource_group_name     = azurerm_resource_group.main.name
  location                = "canadacentral"
  postgresql_version      = "15"

  # Authentication
  administrator_login     = var.postgresql_admin_login
  administrator_password  = var.postgresql_admin_password

  # SKU and storage
  sku_name                = "GP_Standard_D4s_v3"  # 4 vCores, 16 GB RAM
  storage_mb              = 131072  # 128 GB

  # High availability
  high_availability_enabled = false  # Enable for production

  # Private endpoint
  delegated_subnet_id     = module.spoke_vnet.private_endpoint_subnet_id
  private_dns_zone_id     = module.private_dns_postgres.dns_zone_id

  # Monitoring
  log_analytics_workspace_id = module.log_analytics.workspace_id

  tags = var.tags
}
```

**Outputs**: `server_id`, `server_fqdn`, `server_name`

---

## Monitoring Modules

### 1. log-analytics

**Path**: `modules/monitoring/log-analytics/`
**Purpose**: Centralized logging for all resources

**Usage**:
```hcl
module "log_analytics" {
  source = "../../modules/monitoring/log-analytics"

  workspace_name      = "log-erp-cc-prod"
  resource_group_name = azurerm_resource_group.main.name
  location            = "canadacentral"
  retention_in_days   = 30
  sku                 = "PerGB2018"
  tags                = var.tags
}
```

**Outputs**: `workspace_id`, `workspace_name`, `primary_shared_key`

---

### 2. application-insights

**Path**: `modules/monitoring/application-insights/`
**Purpose**: Application performance monitoring

**Usage**:
```hcl
module "app_insights" {
  source = "../../modules/monitoring/application-insights"

  name                = "appi-erp-cc-prod"
  resource_group_name = azurerm_resource_group.main.name
  location            = "canadacentral"
  application_type    = "web"
  workspace_id        = module.log_analytics.workspace_id
  tags                = var.tags
}
```

**Outputs**: `instrumentation_key`, `app_id`, `connection_string`

---

### 3. action-group

**Path**: `modules/monitoring/action-group/`
**Purpose**: Alert notification configuration

**Usage**:
```hcl
module "action_group" {
  source = "../../modules/monitoring/action-group"

  action_group_name   = "ag-erp-cc-prod"
  resource_group_name = azurerm_resource_group.main.name
  short_name          = "erp-alerts"

  email_receivers = [
    {
      name          = "ops-team"
      email_address = "ops@example.com"
    }
  ]

  tags = var.tags
}
```

**Outputs**: `action_group_id`

---

## Module Best Practices

### 1. Module Versioning
```hcl
# Pin module versions in production
module "hub_vnet" {
  source  = "../../modules/networking/hub-vnet"
  version = "1.0.0"  # Use version tags
  # ...
}
```

### 2. Variable Validation
```hcl
# In module variables.tf
variable "environment" {
  type        = string
  description = "Environment name"

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Environment must be dev or prod."
  }
}
```

### 3. Output Dependencies
```hcl
# Use module outputs to create dependencies
module "aks" {
  source = "../../modules/compute/aks-cluster"

  subnet_id = module.spoke_vnet.aks_subnet_id  # Automatic dependency
  # ...
}
```

### 4. Consistent Tagging
```hcl
# Define tags once, use everywhere
locals {
  common_tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
    Project     = "ERP"
    CostCenter  = "IT"
  }
}

module "hub_vnet" {
  source = "../../modules/networking/hub-vnet"
  tags   = local.common_tags
  # ...
}
```

### 5. Explicit Dependencies
```hcl
# Use depends_on when implicit dependencies aren't enough
module "aks" {
  source = "../../modules/compute/aks-cluster"

  # Ensure firewall is created first
  depends_on = [module.azure_firewall]
  # ...
}
```

---

## Module Dependency Flow

```
1. Resource Group
   └── 2. Log Analytics Workspace
       └── 3. Hub VNet
           ├── 4. Azure Firewall
           ├── 5. Azure Bastion
           └── 6. Spoke VNet
               ├── 7. VNet Peering
               ├── 8. Private DNS Zones
               ├── 9. Storage Account + Private Endpoint
               ├── 10. Container Registry + Private Endpoint
               ├── 11. Key Vault + Private Endpoint
               ├── 12. PostgreSQL + Private Endpoint
               ├── 13. AKS Cluster (Stage 1: loadBalancer)
               ├── 14. Virtual Machines
               └── 15. Route Table (Stage 2: userDefinedRouting)
```

---

## Quick Reference

| Module | Category | Purpose | Private Endpoint |
|--------|----------|---------|------------------|
| hub-vnet | Networking | Central hub network | N/A |
| spoke-vnet | Networking | Workload network | N/A |
| vnet-peering | Networking | Connect hub & spoke | N/A |
| private-dns-zone | Networking | DNS for private endpoints | N/A |
| azure-firewall | Security | Network security | No |
| bastion | Security | Secure VM access | No |
| nsg | Security | Subnet security rules | N/A |
| route-table | Security | Traffic routing | N/A |
| aks-cluster | Compute | Kubernetes cluster | No (private cluster) |
| linux-vm | Compute | Virtual machines | No |
| storage-account | Storage | Blob & file storage | Yes |
| container-registry | Storage | Container images | Yes |
| key-vault | Storage | Secrets management | Yes |
| file-share | Storage | Shared file storage | Via storage account |
| postgresql-flexible | Data | PostgreSQL database | Yes |
| log-analytics | Monitoring | Centralized logging | No |
| application-insights | Monitoring | APM | No |
| action-group | Monitoring | Alert notifications | No |

---
## See Also

- **[Environment Resources](ENVIRONMENT-RESOURCES.md)** - Complete list of resources created
- **[Deployment Steps](DEPLOYMENT-STEPS.md)** - Step-by-step deployment guide
- **[Architecture](ARCHITECTURE.md)** - Architecture overview and design decisions
- **[Troubleshooting](TROUBLESHOOTING.md)** - Common issues and solutions

---

**Last Updated**: November 2025
**Version**: 2.1.0


**Version:** 2.0.0  
**Last Updated:** November 2025

