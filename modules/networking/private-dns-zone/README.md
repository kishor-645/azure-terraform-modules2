# Private DNS Zone Terraform Module

This module creates Azure Private DNS zones and links them to virtual networks for private endpoint name resolution.

## Features

- ✅ Private DNS zone creation
- ✅ Multiple VNet link support
- ✅ Auto-registration option (for VMs)
- ✅ Support for all Azure service private link DNS zones
- ✅ Comprehensive outputs for DNS configuration

## Supported Private Link DNS Zones

This module supports creating DNS zones for Azure services:

| Azure Service | DNS Zone Name |
|---------------|---------------|
| **Container Registry** | `privatelink.azurecr.io` |
| **Key Vault** | `privatelink.vaultcore.azure.net` |
| **Storage (Blob)** | `privatelink.blob.core.windows.net` |
| **Storage (File)** | `privatelink.file.core.windows.net` |
| **PostgreSQL** | `privatelink.postgres.database.azure.com` |
| **SQL Database** | `privatelink.database.windows.net` |
| **Cosmos DB** | `privatelink.documents.azure.com` |
| **AKS** | `privatelink.{region}.azmk8s.io` |

## Usage

### Basic Example (Single VNet)

```hcl
module "private_dns_acr" {
  source = "../../modules/networking/private-dns-zone"

  dns_zone_name       = "privatelink.azurecr.io"
  resource_group_name = "rg-spoke-canadacentral-prod"

  # Link to spoke VNet
  linked_vnet_ids = [
    module.spoke_vnet.vnet_id
  ]

  tags = {
    Environment = "Production"
    Service     = "Container Registry"
  }
}
```

### Multiple VNet Links

```hcl
module "private_dns_keyvault" {
  source = "../../modules/networking/private-dns-zone"

  dns_zone_name       = "privatelink.vaultcore.azure.net"
  resource_group_name = "rg-hub-canadacentral-prod"

  # Link to both hub and spoke VNets
  linked_vnet_ids = [
    module.hub_vnet.vnet_id,
    module.spoke_vnet.vnet_id
  ]

  tags = {
    Environment = "Production"
    Service     = "Key Vault"
  }
}
```

### Multiple DNS Zones (All Services)

```hcl
# Local variables for DNS zones
locals {
  private_dns_zones = [
    "privatelink.azurecr.io",
    "privatelink.vaultcore.azure.net",
    "privatelink.blob.core.windows.net",
    "privatelink.file.core.windows.net",
    "privatelink.postgres.database.azure.com"
  ]
}

# Create all DNS zones
module "private_dns_zones" {
  source = "../../modules/networking/private-dns-zone"

  for_each = toset(local.private_dns_zones)

  dns_zone_name       = each.value
  resource_group_name = "rg-spoke-canadacentral-prod"

  # Link to spoke VNet
  linked_vnet_ids = [
    module.spoke_vnet.vnet_id
  ]

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}
```

### With Auto-Registration (for VMs)

```hcl
module "private_dns_custom" {
  source = "../../modules/networking/private-dns-zone"

  dns_zone_name       = "internal.company.local"
  resource_group_name = "rg-hub-canadacentral-prod"

  linked_vnet_ids = [
    module.hub_vnet.vnet_id
  ]

  # Enable auto-registration of VM hostnames
  enable_auto_registration = true

  tags = {
    Environment = "Production"
    Purpose     = "VM Hostname Resolution"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.10.3 |
| azurerm | ~> 4.51.0 |

## Inputs

| Name | Description | Type | Required | Default |
|------|-------------|------|----------|---------|
| dns_zone_name | Private DNS zone name | string | Yes | - |
| resource_group_name | Resource group name | string | Yes | - |
| linked_vnet_ids | List of VNet IDs to link | list(string) | No | [] |
| enable_auto_registration | Enable VM auto-registration | bool | No | false |
| tags | Resource tags | map(string) | No | {} |

## Outputs

| Name | Description |
|------|-------------|
| dns_zone_id | DNS zone resource ID |
| dns_zone_name | DNS zone name |
| dns_zone_max_number_of_record_sets | Max record sets allowed |
| dns_zone_number_of_record_sets | Current record set count |
| vnet_link_ids | Map of VNet link IDs |
| vnet_link_names | List of VNet link names |
| linked_vnet_count | Number of linked VNets |
| dns_zone_details | Consolidated DNS zone details |

## How Private Endpoint DNS Works

### Without Private DNS Zone:
```
App → privateendpoint123.azurecr.io
    → Public IP (blocked by firewall)
    → ❌ Connection fails
```

### With Private DNS Zone:
```
App → myacr.azurecr.io
    → Private DNS: privatelink.azurecr.io
    → 10.1.29.5 (private endpoint IP)
    → ✅ Connection successful
```

## Architecture Pattern

### Regional Isolation (Recommended for this project):
Each region has its own private DNS zones linked only to that region's spoke VNet.

```
┌─────────────────────────────────────────┐
│ Canada Central                          │
│                                         │
│  ┌─────────────────┐  ┌──────────────┐ │
│  │ Spoke VNet      │  │ Private DNS  │ │
│  │                 │──│ Zones        │ │
│  │ - AKS           │  │ - ACR        │ │
│  │ - Endpoints     │  │ - Key Vault  │ │
│  └─────────────────┘  └──────────────┘ │
└─────────────────────────────────────────┘
```

### Centralized (Alternative - Not used):
All spokes link to shared DNS zones in hub region.

## DNS Resolution Flow

1. **Private Endpoint Created** → Automatic A record added to DNS zone
2. **App queries DNS** → `myacr.azurecr.io`
3. **DNS zone resolves** → Returns private IP `10.1.29.5`
4. **App connects** → Traffic stays within VNet (private, secure, fast)

## Notes

- **Auto-Registration**: Only for VMs, not for private endpoints (use A records)
- **VNet Links**: Required for DNS resolution within VNet
- **Multiple Regions**: Create separate DNS zones per region for isolation
- **Private Endpoints**: Automatically create A records in linked DNS zones

## Troubleshooting

### Issue: DNS not resolving private endpoint

**Test DNS resolution:**
```bash
# From VM in linked VNet
nslookup myacr.azurecr.io

# Expected output:
# Server: 168.63.129.16 (Azure DNS)
# Address: 10.1.29.5 (private IP)
```

**If resolving to public IP:**
- Check VNet link is created and active
- Verify DNS zone name matches service (`privatelink.azurecr.io`)
- Ensure private endpoint created A record in DNS zone

### Issue: Multiple A records for same hostname

**Solution:** 
- Delete old private endpoint
- Ensure only one private endpoint per service per region

## Related Modules

- [hub-vnet](../hub-vnet/) - Hub VNet for shared services
- [spoke-vnet](../spoke-vnet/) - Spoke VNet for AKS
- [vnet-peering](../vnet-peering/) - VNet connectivity

## Version History

- **v1.0.0** (November 2025)
  - Initial release
  - Support for Terraform 1.10.3
  - Support for AzureRM provider 4.51.0
  - Multiple VNet link support
