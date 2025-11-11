# Terraform Modules Guide

Complete reference guide for all Terraform modules used in this infrastructure.

## Table of Contents

1. [Module Structure](#module-structure)
2. [Networking Modules](#networking-modules)
3. [Security Modules](#security-modules)
4. [Compute Modules](#compute-modules)
5. [Storage Modules](#storage-modules)
6. [Data Modules](#data-modules)
7. [Monitoring Modules](#monitoring-modules)

## Module Structure

All modules follow a consistent structure:

```
modules/
├── <category>/
│   └── <module-name>/
│       ├── main.tf          # Main resources
│       ├── variables.tf     # Input variables
│       ├── outputs.tf       # Output values
│       └── README.md        # Module documentation
```

## Networking Modules

### hub-vnet

Creates the hub virtual network with required subnets.

**Location:** `modules/networking/hub-vnet/`

**Subnets Created:**
- AzureFirewallSubnet (10.0.1.0/26)
- AzureFirewallManagementSubnet (10.0.2.0/26)
- AzureBastionSubnet (10.0.3.0/27)
- SharedServicesSubnet (10.0.4.0/24)
- PrivateEndpointsSubnet (10.0.5.0/24)

**Key Variables:**
- `vnet_name` - Name of the hub VNet
- `address_space` - VNet address space (list)
- `resource_group_name` - Resource group name

**Outputs:**
- `vnet_id` - VNet resource ID
- `firewall_subnet_id` - Firewall subnet ID
- `bastion_subnet_id` - Bastion subnet ID

### spoke-vnet

Creates the spoke virtual network with shared AKS subnet.

**Location:** `modules/networking/spoke-vnet/`

**Subnets Created:**
- **AKSNodeSubnet** (10.1.0.0/20) - **Shared by both system and user node pools**
- PrivateEndpointsSubnet (10.1.16.0/24)
- JumpboxSubnet (10.1.17.0/27)

**Key Variables:**
- `aks_node_pool_subnet_cidr` - CIDR for shared AKS subnet
- `private_endpoints_subnet_cidr` - CIDR for private endpoints
- `jumpbox_subnet_cidr` - CIDR for jumpbox/agent VMs

**Outputs:**
- `aks_node_pool_subnet_id` - **Shared subnet ID for AKS node pools**
- `private_endpoints_subnet_id` - Private endpoints subnet ID
- `jumpbox_subnet_id` - Jumpbox subnet ID

**Important:** The AKS subnet is shared between system and user node pools. This simplifies the architecture while maintaining security through Kubernetes network policies.

### vnet-peering

Creates VNet peering between hub and spoke.

**Location:** `modules/networking/vnet-peering/`

**Key Variables:**
- `hub_vnet_id` - Hub VNet ID
- `spoke_vnet_id` - Spoke VNet ID
- `allow_forwarded_traffic` - Allow forwarded traffic (default: true)

### private-dns-zone

Creates Azure Private DNS zones for private endpoint resolution.

**Location:** `modules/networking/private-dns-zone/`

**Supported DNS Zones:**
- `privatelink.azurecr.io` - Container Registry
- `privatelink.vaultcore.azure.net` - Key Vault
- `privatelink.blob.core.windows.net` - Storage Blob
- `privatelink.file.core.windows.net` - Storage File
- `privatelink.postgres.database.azure.com` - PostgreSQL
- `privatelink.{region}.azmk8s.io` - AKS

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

### azure-firewall

Creates Azure Firewall Premium with policies and rules.

**Location:** `modules/security/azure-firewall/`

**Features:**
- Premium SKU with IDPS
- Threat Intelligence
- Application rules for Cloudflare
- Network rules for VNet traffic
- DNAT rules for inbound traffic

**Key Variables:**
- `firewall_name` - Firewall name
- `firewall_subnet_id` - Firewall subnet ID
- `internal_lb_ip` - Istio internal LB IP (for DNAT rule)
- `threat_intelligence_mode` - Threat intel mode (Alert/Deny/Off)
- `idps_mode` - IDPS mode (Alert/Deny/Off)

**Outputs:**
- `firewall_private_ip` - Firewall private IP
- `firewall_public_ip` - Firewall public IP

### bastion

Creates Azure Bastion for secure VM access.

**Location:** `modules/security/bastion/`

**Key Variables:**
- `bastion_name` - Bastion name
- `bastion_subnet_id` - Bastion subnet ID
- `scale_units` - Scale units (1-50)

### route-table

Creates route table for routing traffic through Azure Firewall.

**Location:** `modules/security/route-table/`

**Key Variables:**
- `route_table_name` - Route table name
- `routes` - List of routes
- `subnet_ids` - List of subnet IDs to associate

**Usage:**
```hcl
module "route_table_aks" {
  source = "../../../modules/security/route-table"
  
  route_table_name = "rt-aks-prod"
  routes = [{
    name                   = "default-via-firewall"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = module.azure_firewall.firewall_private_ip
  }]
  subnet_ids = [module.spoke_vnet.aks_node_pool_subnet_id]
}
```

## Compute Modules

### aks-cluster

Creates private AKS cluster with Istio service mesh.

**Location:** `modules/compute/aks-cluster/`

**Key Features:**
- **Istio Service Mesh (Inbuilt)**: Enabled via `service_mesh_profile`
- **Shared Subnet**: Both node pools use `aks_node_pool_subnet_id`
- **Private Cluster**: No public API endpoint
- **Azure RBAC**: Integrated with Azure AD
- **Key Vault Integration**: Secrets provider enabled

**Key Variables:**
- `cluster_name` - AKS cluster name
- `aks_node_pool_subnet_id` - **Shared subnet for both node pools**
- `kubernetes_version` - Kubernetes version
- `istio_internal_ingress_gateway_enabled` - Enable Istio internal gateway
- `istio_external_ingress_gateway_enabled` - Enable Istio external gateway

**Istio Configuration:**
```hcl
service_mesh_profile {
  mode                             = "Istio"
  internal_ingress_gateway_enabled = true
  external_ingress_gateway_enabled = false
}
```

**Node Pool Configuration:**
- System node pool uses `aks_node_pool_subnet_id`
- User node pool also uses `aks_node_pool_subnet_id` (shared subnet)
- Both pools can coexist in the same subnet with network policy isolation

**Outputs:**
- `cluster_name` - Cluster name
- `cluster_private_fqdn` - Private FQDN
- `cluster_id` - Cluster resource ID

### linux-vm

Creates Linux virtual machine (for jumpbox and agent VM).

**Location:** `modules/compute/linux-vm/`

**Key Variables:**
- `vm_name` - VM name
- `subnet_id` - Subnet ID
- `admin_username` - Admin username
- `ssh_public_key` - SSH public key
- `vm_size` - VM size

## Storage Modules

### key-vault

Creates Azure Key Vault with private endpoint.

**Location:** `modules/storage/key-vault/`

**Key Variables:**
- `key_vault_name` - Key Vault name
- `sku_name` - SKU (standard/premium)
- `enable_private_endpoint` - Enable private endpoint
- `private_dns_zone_ids` - Private DNS zone IDs

### storage-account

Creates Azure Storage Account with private endpoints.

**Location:** `modules/storage/storage-account/`

**Key Variables:**
- `storage_account_name` - Storage account name
- `account_tier` - Account tier (Standard/Premium)
- `account_replication_type` - Replication type (LRS/ZRS/GRS)
- `enable_private_endpoint` - Enable blob private endpoint
- `enable_file_private_endpoint` - Enable file private endpoint

### container-registry

Creates Azure Container Registry with private endpoint.

**Location:** `modules/storage/container-registry/`

**Key Variables:**
- `registry_name` - ACR name
- `sku` - SKU (Basic/Standard/Premium)
- `enable_private_endpoint` - Enable private endpoint
- `private_dns_zone_ids` - Private DNS zone IDs

## Data Modules

### postgresql-flexible

Creates PostgreSQL Flexible Server with private endpoint.

**Location:** `modules/data/postgresql-flexible/`

**Key Variables:**
- `server_name` - Server name
- `postgresql_version` - PostgreSQL version (14/15/16)
- `administrator_login` - Admin username
- `administrator_password` - Admin password (sensitive)
- `sku_name` - SKU name (e.g., GP_Standard_D4s_v3)
- `storage_mb` - Storage in MB
- `delegated_subnet_id` - Delegated subnet for private endpoint
- `private_dns_zone_id` - Private DNS zone ID

## Monitoring Modules

### log-analytics

Creates Log Analytics workspace.

**Location:** `modules/monitoring/log-analytics/`

**Key Variables:**
- `workspace_name` - Workspace name
- `retention_in_days` - Retention period (30-730)

**Outputs:**
- `workspace_id` - Workspace resource ID

## Module Dependencies

### Dependency Graph

```
hub-vnet
  └── azure-firewall
  └── bastion

spoke-vnet
  └── aks-cluster
  └── linux-vm (jumpbox, agent)
  └── private-endpoints (for all storage/data services)

vnet-peering
  └── (connects hub and spoke)

private-dns-zone
  └── (required by all private endpoints)

log-analytics
  └── (used by all resources for diagnostics)
```

## Best Practices

1. **Use Module Versions**: Pin module versions in production
2. **Variable Validation**: Always validate input variables
3. **Outputs**: Expose necessary outputs for other modules
4. **Tags**: Apply consistent tags across all resources
5. **Dependencies**: Explicitly define dependencies with `depends_on`

## Customization

### Adding New Modules

1. Create module directory: `modules/<category>/<module-name>/`
2. Create `main.tf`, `variables.tf`, `outputs.tf`
3. Add README.md with usage examples
4. Reference in environment `main.tf`

### Modifying Existing Modules

1. Update module code
2. Update module README if interface changes
3. Test in dev environment first
4. Update environment configurations if needed

---

**Version:** 2.0.0  
**Last Updated:** November 2025

