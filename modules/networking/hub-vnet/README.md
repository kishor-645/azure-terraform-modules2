# Hub VNet Terraform Module

This module creates an Azure hub virtual network with 6 subnets designed for a hub-spoke network topology.

## Features

- ✅ Hub VNet with configurable address space
- ✅ 6 dedicated subnets with appropriate configurations
- ✅ DDoS Protection Plan integration (optional)
- ✅ CIDR validation to prevent misconfigurations
- ✅ Comprehensive outputs for downstream modules

## Subnets Created

| Subnet | Purpose | Minimum Size | Notes |
|--------|---------|--------------|-------|
| **AzureFirewallSubnet** | Azure Firewall | /26 (59 IPs) | Name must be exact |
| **AzureBastionSubnet** | Azure Bastion | /26 (59 IPs) | Name must be exact |
| **AzureFirewallManagementSubnet** | Firewall Management | /26 (59 IPs) | Name must be exact |
| **SharedServicesSubnet** | Shared resources | /24 (251 IPs) | Customizable name |
| **PrivateEndpointsSubnet** | Private endpoints | /24 (251 IPs) | Customizable name |
| **JumpboxSubnet** | Jump box VMs | /24 (251 IPs) | Customizable name |

## Usage

### Basic Example

```hcl
module "hub_vnet" {
  source = "../../modules/networking/hub-vnet"

  vnet_name           = "vnet-hub-canadacentral-prod"
  location            = "canadacentral"
  resource_group_name = "rg-hub-canadacentral-prod"
  address_space       = "10.0.0.0/16"

  # Subnet CIDRs
  firewall_subnet_cidr          = "10.0.0.0/26"
  bastion_subnet_cidr           = "10.0.0.64/26"
  firewall_mgmt_subnet_cidr     = "10.0.0.128/26"
  shared_services_subnet_cidr   = "10.0.1.0/24"
  private_endpoints_subnet_cidr = "10.0.2.0/24"
  jumpbox_subnet_cidr           = "10.0.4.0/24"

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}
```

### With DDoS Protection

```hcl
module "hub_vnet" {
  source = "../../modules/networking/hub-vnet"

  vnet_name           = "vnet-hub-canadacentral-prod"
  location            = "canadacentral"
  resource_group_name = "rg-hub-canadacentral-prod"
  address_space       = "10.0.0.0/16"

  # Subnet CIDRs
  firewall_subnet_cidr          = "10.0.0.0/26"
  bastion_subnet_cidr           = "10.0.0.64/26"
  firewall_mgmt_subnet_cidr     = "10.0.0.128/26"
  shared_services_subnet_cidr   = "10.0.1.0/24"
  private_endpoints_subnet_cidr = "10.0.2.0/24"
  jumpbox_subnet_cidr           = "10.0.4.0/24"

  # DDoS Protection
  ddos_protection_plan_id = azurerm_network_ddos_protection_plan.global.id

  tags = {
    Environment = "Production"
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
| vnet_name | Name of the hub virtual network | string | Yes | - |
| location | Azure region | string | Yes | - |
| resource_group_name | Resource group name | string | Yes | - |
| address_space | VNet address space (CIDR) | string | Yes | - |
| firewall_subnet_cidr | Firewall subnet CIDR | string | Yes | - |
| bastion_subnet_cidr | Bastion subnet CIDR | string | Yes | - |
| firewall_mgmt_subnet_cidr | Firewall management subnet CIDR | string | Yes | - |
| shared_services_subnet_cidr | Shared services subnet CIDR | string | Yes | - |
| private_endpoints_subnet_cidr | Private endpoints subnet CIDR | string | Yes | - |
| jumpbox_subnet_cidr | Jumpbox subnet CIDR | string | Yes | - |
| shared_services_subnet_name | Custom name for shared services subnet | string | No | SharedServicesSubnet |
| private_endpoints_subnet_name | Custom name for private endpoints subnet | string | No | PrivateEndpointsSubnet |
| jumpbox_subnet_name | Custom name for jumpbox subnet | string | No | JumpboxSubnet |
| ddos_protection_plan_id | DDoS Protection Plan ID | string | No | null |
| tags | Resource tags | map(string) | No | {} |

## Outputs

| Name | Description |
|------|-------------|
| vnet_id | Hub VNet resource ID |
| vnet_name | Hub VNet name |
| vnet_address_space | Hub VNet address space |
| firewall_subnet_id | Firewall subnet ID |
| bastion_subnet_id | Bastion subnet ID |
| firewall_management_subnet_id | Firewall management subnet ID |
| shared_services_subnet_id | Shared services subnet ID |
| private_endpoints_subnet_id | Private endpoints subnet ID |
| jumpbox_subnet_id | Jumpbox subnet ID |
| subnet_names | Map of all subnet names |
| subnet_address_prefixes | Map of all subnet CIDRs |
| hub_vnet_details | Consolidated hub VNet and subnet details |

## CIDR Planning

### Canada Central Example
```
Hub VNet: 10.0.0.0/16
├── AzureFirewallSubnet:          10.0.0.0/26   (59 IPs)
├── AzureBastionSubnet:           10.0.0.64/26  (59 IPs)
├── AzureFirewallManagementSubnet: 10.0.0.128/26 (59 IPs)
├── SharedServicesSubnet:         10.0.1.0/24   (251 IPs)
├── PrivateEndpointsSubnet:       10.0.2.0/24   (251 IPs)
└── JumpboxSubnet:                10.0.4.0/24   (251 IPs)
```

## Notes

- **Firewall Subnet**: Must be named exactly `AzureFirewallSubnet` (Azure requirement)
- **Bastion Subnet**: Must be named exactly `AzureBastionSubnet` (Azure requirement)
- **Management Subnet**: Must be named exactly `AzureFirewallManagementSubnet` (Azure requirement)
- **Private Endpoints**: Network policies are disabled for private endpoint support

## Related Modules

- [spoke-vnet](../spoke-vnet/) - Creates spoke VNet for AKS workloads
- [vnet-peering](../vnet-peering/) - Establishes hub-spoke peering
- [private-dns-zone](../private-dns-zone/) - Creates private DNS zones

## Version History

- **v1.0.0** (November 2025)
  - Initial release
  - Support for Terraform 1.10.3
  - Support for AzureRM provider 4.51.0
