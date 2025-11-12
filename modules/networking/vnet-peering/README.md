# VNet Peering Terraform Module

This module creates bidirectional VNet peering between hub and spoke virtual networks in Azure.

## Features

- ✅ Bidirectional hub-spoke VNet peering
- ✅ Forwarded traffic allowed (for Azure Firewall routing)
- ✅ Automatic peering name generation
- ✅ Proper dependency management (hub-to-spoke created first)
- ✅ Peering state validation

## Peering Configuration

The module creates two peering connections:

1. **Hub → Spoke**: Allows hub to access spoke resources
2. **Spoke → Hub**: Allows spoke to access hub resources (Firewall, Bastion, shared services)

Both connections allow:
- Virtual network access (VNet-to-VNet communication)
- Forwarded traffic (for routing through Azure Firewall)

## Usage

### Basic Example

```hcl
module "vnet_peering" {
  source = "../../modules/networking/vnet-peering"

  # Hub VNet details
  hub_vnet_id              = module.hub_vnet.vnet_id
  hub_vnet_name            = module.hub_vnet.vnet_name
  hub_resource_group_name  = "rg-hub-canadacentral-prod"

  # Spoke VNet details
  spoke_vnet_id              = module.spoke_vnet.vnet_id
  spoke_vnet_name            = module.spoke_vnet.vnet_name
  spoke_resource_group_name  = "rg-spoke-canadacentral-prod"
}
```


```

### With Custom Peering Names

```hcl
module "vnet_peering" {
  source = "../../modules/networking/vnet-peering"

  # Hub VNet details
  hub_vnet_id              = module.hub_vnet.vnet_id
  hub_vnet_name            = module.hub_vnet.vnet_name
  hub_resource_group_name  = "rg-hub-canadacentral-prod"

  # Spoke VNet details
  spoke_vnet_id              = module.spoke_vnet.vnet_id
  spoke_vnet_name            = module.spoke_vnet.vnet_name
  spoke_resource_group_name  = "rg-spoke-canadacentral-prod"

  # Custom peering names
  hub_to_spoke_peering_name = "peer-hub-canadacentral-to-spoke-canadacentral"
  spoke_to_hub_peering_name = "peer-spoke-canadacentral-to-hub-canadacentral"
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
| hub_vnet_id | Hub VNet resource ID | string | Yes | - |
| hub_vnet_name | Hub VNet name | string | Yes | - |
| hub_resource_group_name | Hub VNet resource group | string | Yes | - |
| spoke_vnet_id | Spoke VNet resource ID | string | Yes | - |
| spoke_vnet_name | Spoke VNet name | string | Yes | - |
| spoke_resource_group_name | Spoke VNet resource group | string | Yes | - |
| hub_to_spoke_peering_name | Custom hub-to-spoke peering name | string | No | Auto-generated |
| spoke_to_hub_peering_name | Custom spoke-to-hub peering name | string | No | Auto-generated |

## Outputs

| Name | Description |
|------|-------------|
| hub_to_spoke_peering_id | Hub-to-spoke peering resource ID |
| hub_to_spoke_peering_name | Hub-to-spoke peering name |
| hub_to_spoke_peering_state | Hub-to-spoke peering state |
| spoke_to_hub_peering_id | Spoke-to-hub peering resource ID |
| spoke_to_hub_peering_name | Spoke-to-hub peering name |
| spoke_to_hub_peering_state | Spoke-to-hub peering state |
| peering_details | Consolidated peering details |
| peering_status | Peering status message |

## Peering States

Possible peering states:
- **Connected**: Peering is active and working
- **Initiated**: Peering creation in progress
- **Disconnected**: Peering failed or disconnected

Both peerings should show **Connected** state for successful communication.



## Traffic Flow

With this peering configuration:

```
┌─────────────────┐              ┌─────────────────┐
│   Hub VNet      │◄────────────►│   Spoke VNet    │
│                 │   Peering    │                 │
│ - Firewall      │              │ - AKS Cluster   │
│ - Bastion       │              │ - Workloads     │
│ - Shared Svcs   │              │                 │
└─────────────────┘              └─────────────────┘
        ↓                                ↓
  Allow Gateway Transit          Use Remote Gateways
  Allow Forwarded Traffic        Allow Forwarded Traffic
```

**Spoke → Hub:** Access Firewall, Bastion, shared services  
**Hub → Spoke:** Management access to AKS nodes  
**Spoke → Internet:** Routed through Hub Firewall (via UDR)

## Troubleshooting

### Issue: Peering state shows "Initiated" or "Disconnected"

**Possible causes:**
- Overlapping CIDR blocks between VNets
- Network security rules blocking traffic
- Azure subscription/region limitations

**Solution:**
```bash
# Check peering state
az network vnet peering show   --resource-group <hub-rg>   --vnet-name <hub-vnet>   --name <peering-name>

# Verify no CIDR overlap
az network vnet show --ids <vnet-id> --query addressSpace.addressPrefixes
```

### Issue: Cannot enable use_remote_gateways

**Error:** `Remote gateway cannot be used without gateway transit enabled`

**Solution:**
- Ensure `enable_gateway_transit = true` on hub
- Ensure VPN/ExpressRoute Gateway exists in hub VNet
- Create gateway before enabling this feature

## Notes

- **Peering is not transitive**: Spoke-to-spoke communication requires additional peering or NVA routing
- **Forwarded traffic allowed**: Required for Azure Firewall to route traffic between spokes
- **No bandwidth charges**: Traffic between peered VNets in same region is free
- **Cross-region peering**: Supported but incurs bandwidth charges

## Related Modules

- [hub-vnet](../hub-vnet/) - Creates hub VNet
- [spoke-vnet](../spoke-vnet/) - Creates spoke VNet
- [private-dns-zone](../private-dns-zone/) - Private DNS for peered VNets

## Version History

- **v1.0.0** (November 2025)
  - Initial release
  - Support for Terraform 1.10.3
  - Support for AzureRM provider 4.51.0
  - Bidirectional peering with gateway transit support
