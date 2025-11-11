# Spoke VNet Terraform Module

This module creates an Azure spoke virtual network with 4 subnets designed for AKS workloads in a hub-spoke topology.

## Features

- ✅ Spoke VNet with configurable address space
- ✅ 4 dedicated subnets for AKS and supporting services
- ✅ Private endpoint support
- ✅ CIDR validation to prevent misconfigurations
- ✅ Comprehensive outputs for AKS deployment

## Subnets Created

| Subnet | Purpose | Recommended Size | Notes |
|--------|---------|------------------|-------|
| **AKSSystemNodeSubnet** | AKS system node pool | /20 (4,091 IPs) | For system pods |
| **AKSUserNodeSubnet** | AKS user node pool | /22 (1,019 IPs) | For workload pods |
| **PrivateEndpointsSubnet** | Private endpoints | /24 (251 IPs) | Regional PaaS services |
| **JumpboxSubnet** | Agent VMs | /27 (32 IPs) | For AKS access |

## Usage

### Basic Example

```hcl
module "spoke_vnet" {
  source = "../../modules/networking/spoke-vnet"

  vnet_name           = "vnet-spoke-canadacentral-prod"
  location            = "canadacentral"
  resource_group_name = "rg-spoke-canadacentral-prod"
  address_space       = "10.1.0.0/16"

  # Subnet CIDRs
  aks_system_subnet_cidr        = "10.1.0.0/20"
  aks_user_subnet_cidr          = "10.1.16.0/22"
  private_endpoints_subnet_cidr = "10.1.29.0/24"
  jumpbox_subnet_cidr           = "10.1.30.128/27"

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}
```

### With Custom Subnet Names

```hcl
module "spoke_vnet" {
  source = "../../modules/networking/spoke-vnet"

  vnet_name           = "vnet-spoke-canadacentral-prod"
  location            = "canadacentral"
  resource_group_name = "rg-spoke-canadacentral-prod"
  address_space       = "10.1.0.0/16"

  # Subnet CIDRs
  aks_system_subnet_cidr        = "10.1.0.0/20"
  aks_user_subnet_cidr          = "10.1.16.0/22"
  private_endpoints_subnet_cidr = "10.1.29.0/24"
  jumpbox_subnet_cidr           = "10.1.30.128/27"

  # Custom subnet names
  aks_system_subnet_name        = "snet-aks-system"
  aks_user_subnet_name          = "snet-aks-user"
  private_endpoints_subnet_name = "snet-private-endpoints"
  jumpbox_subnet_name           = "snet-jumpbox"

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
| vnet_name | Name of the spoke virtual network | string | Yes | - |
| location | Azure region | string | Yes | - |
| resource_group_name | Resource group name | string | Yes | - |
| address_space | VNet address space (CIDR) | string | Yes | - |
| aks_system_subnet_cidr | AKS system node pool subnet CIDR | string | Yes | - |
| aks_user_subnet_cidr | AKS user node pool subnet CIDR | string | Yes | - |
| private_endpoints_subnet_cidr | Private endpoints subnet CIDR | string | Yes | - |
| jumpbox_subnet_cidr | Jumpbox subnet CIDR | string | Yes | - |
| aks_system_subnet_name | Custom name for AKS system subnet | string | No | AKSSystemNodeSubnet |
| aks_user_subnet_name | Custom name for AKS user subnet | string | No | AKSUserNodeSubnet |
| private_endpoints_subnet_name | Custom name for private endpoints subnet | string | No | PrivateEndpointsSubnet |
| jumpbox_subnet_name | Custom name for jumpbox subnet | string | No | JumpboxSubnet |
| tags | Resource tags | map(string) | No | {} |

## Outputs

| Name | Description |
|------|-------------|
| vnet_id | Spoke VNet resource ID |
| vnet_name | Spoke VNet name |
| vnet_address_space | Spoke VNet address space |
| aks_system_subnet_id | AKS system node pool subnet ID |
| aks_user_subnet_id | AKS user node pool subnet ID |
| private_endpoints_subnet_id | Private endpoints subnet ID |
| jumpbox_subnet_id | Jumpbox subnet ID |
| subnet_names | Map of all subnet names |
| subnet_address_prefixes | Map of all subnet CIDRs |
| spoke_vnet_details | Consolidated spoke VNet and subnet details |

## CIDR Planning

### Canada Central Example
```
Spoke VNet: 10.1.0.0/16
├── AKSSystemNodeSubnet:      10.1.0.0/20   (4,091 IPs)
├── AKSUserNodeSubnet:        10.1.16.0/22  (1,019 IPs)
├── PrivateEndpointsSubnet:   10.1.29.0/24  (251 IPs)
└── JumpboxSubnet:            10.1.30.128/27 (32 IPs)
```

## Notes

- **AKS Subnets**: Sized to accommodate Azure CNI Overlay mode (reduces IP consumption)
- **Private Endpoints**: Network policies disabled for private endpoint support
- **Jumpbox Subnet**: Small /27 subnet sufficient for 2-3 agent VMs

## Related Modules

- [hub-vnet](../hub-vnet/) - Creates hub VNet for shared services
- [vnet-peering](../vnet-peering/) - Establishes hub-spoke peering
- [private-dns-zone](../private-dns-zone/) - Creates private DNS zones

## Version History

- **v1.0.0** (November 2025)
  - Initial release
  - Support for Terraform 1.10.3
  - Support for AzureRM provider 4.51.0
  - Designed for Azure CNI Overlay
