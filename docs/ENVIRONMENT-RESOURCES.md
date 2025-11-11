# Environment Resources Guide

This document provides a complete list of all Azure resources that will be created when you run `terraform apply` in the production environment.

## Quick Reference

**Environment Path**: `environments/canada-central/prod/`  
**Region**: Canada Central  
**Resource Group**: `rg-erp-cc-prod`  
**Total Resources**: ~45-50 resources

---

## Resource Summary by Category

| Category | Resource Count | Monthly Cost (Est.) |
|----------|---------------|---------------------|
| **Networking** | 15-18 | $1,350 (Firewall) |
| **Compute** | 8-12 | $1,000-$3,500 (AKS) |
| **Storage** | 5-7 | $50-$100 |
| **Database** | 2-3 | $200-$400 |
| **Security** | 3-5 | $295 (Bastion) |
| **Monitoring** | 3-4 | $50-$100 |
| **Total** | **45-50** | **$3,445-$5,945** |

---

## Detailed Resource List

### 1. Resource Group (1 resource)

```
Resource Group
├── Name: rg-erp-cc-prod
├── Location: canadacentral
└── Tags: Environment=prod, Region=canadacentral, ManagedBy=terraform
```

---

### 2. Monitoring & Logging (3 resources)

```
Log Analytics Workspace
├── Name: log-erp-cc-prod
├── Location: canadacentral
├── Retention: 30 days
└── SKU: PerGB2018

Application Insights
├── Name: appi-erp-cc-prod
├── Location: canadacentral
├── Application Type: web
└── Workspace: log-erp-cc-prod

Action Group
├── Name: ag-erp-cc-prod
├── Short Name: erp-alerts
└── Email Receivers: (configured in tfvars)
```

**Cost**: ~$50-$100/month (based on data ingestion)

---

### 3. Networking - Hub VNet (8 resources)

```
Hub Virtual Network
├── Name: vnet-hub-canadacentral-prod
├── Address Space: 10.0.0.0/16
└── Subnets:
    ├── AzureFirewallSubnet: 10.0.1.0/26 (64 IPs)
    ├── AzureFirewallManagementSubnet: 10.0.2.0/26 (64 IPs)
    ├── AzureBastionSubnet: 10.0.3.0/27 (32 IPs)
    └── SharedServicesSubnet: 10.0.4.0/24 (256 IPs)

Network Security Groups (3)
├── nsg-firewall-cc-prod (AzureFirewallSubnet)
├── nsg-bastion-cc-prod (AzureBastionSubnet)
└── nsg-shared-cc-prod (SharedServicesSubnet)

Route Tables (1)
└── rt-shared-cc-prod (for SharedServicesSubnet)
```

---

### 4. Networking - Spoke VNet (7 resources)

```
Spoke Virtual Network
├── Name: vnet-spoke-canadacentral-prod
├── Address Space: 10.1.0.0/16
└── Subnets:
    ├── AksSubnet: 10.1.0.0/20 (4,096 IPs - shared by system & user pools)
    ├── PrivateEndpointSubnet: 10.1.16.0/24 (256 IPs)
    └── AppGatewaySubnet: 10.1.17.0/24 (256 IPs)

Network Security Groups (3)
├── nsg-aks-cc-prod (AksSubnet)
├── nsg-pe-cc-prod (PrivateEndpointSubnet)
└── nsg-appgw-cc-prod (AppGatewaySubnet)

Route Tables (1)
└── rt-aks-cc-prod (for AksSubnet - Stage 2 only)
```

---

### 5. VNet Peering (2 resources)

```
Hub-to-Spoke Peering
├── Name: peer-hub-to-spoke-canadacentral-prod
├── Allow Gateway Transit: true
└── Allow Forwarded Traffic: true

Spoke-to-Hub Peering
├── Name: peer-spoke-to-hub-canadacentral-prod
├── Use Remote Gateways: false
└── Allow Forwarded Traffic: true
```

---

### 6. Private DNS Zones (5-7 resources)

```
Private DNS Zones
├── privatelink.postgres.database.azure.com
├── privatelink.blob.core.windows.net
├── privatelink.file.core.windows.net
├── privatelink.vaultcore.azure.net
└── privatelink.azurecr.io

VNet Links (per zone)
├── Link to Hub VNet
└── Link to Spoke VNet
```

**Total**: 5 DNS zones + 10 VNet links = 15 resources

---

### 7. Azure Firewall (4 resources)

```
Azure Firewall Premium
├── Name: afw-erp-cc-prod
├── SKU: Premium
├── Tier: Premium
├── Public IP: pip-afw-erp-cc-prod
├── Management Public IP: pip-afw-mgmt-erp-cc-prod
└── Subnet: AzureFirewallSubnet (10.0.1.0/26)

Firewall Policy
├── Name: afwp-erp-cc-prod
├── SKU: Premium
├── Threat Intelligence: Alert and Deny
├── IDPS: Alert and Deny
└── Rule Collections:
    ├── Network Rules (AKS egress, DNS, NTP)
    ├── Application Rules (Azure services, OS updates)
    └── DNAT Rules (if configured)

Public IP Addresses (2)
├── pip-afw-erp-cc-prod (Standard, Static)
└── pip-afw-mgmt-erp-cc-prod (Standard, Static)
```

**Cost**: ~$1,350/month (Premium tier)

---

### 8. Azure Bastion (2 resources)

```
Azure Bastion
├── Name: bas-erp-cc-prod
├── SKU: Standard
├── Public IP: pip-bastion-erp-cc-prod
└── Subnet: AzureBastionSubnet (10.0.3.0/27)

Public IP Address
└── pip-bastion-erp-cc-prod (Standard, Static)
```

**Cost**: ~$295/month

---

### 9. Storage Services (5 resources)

```
Storage Account
├── Name: sterp<unique>ccprod (globally unique)
├── SKU: Standard_GRS
├── Kind: StorageV2
├── HTTPS Only: true
├── Min TLS Version: TLS1_2
├── Public Access: Disabled
└── Private Endpoint: pe-st-erp-cc-prod

File Share
├── Name: erp-shared-files
├── Quota: 100 GB
└── Access Tier: TransactionOptimized

Container Registry
├── Name: acrerp<unique>ccprod (globally unique)
├── SKU: Premium
├── Admin Enabled: false
├── Public Access: Disabled
└── Private Endpoint: pe-acr-erp-cc-prod

Key Vault
├── Name: kv-erp-<unique>-cc-prod
├── SKU: Standard
├── Soft Delete: Enabled (90 days)
├── Purge Protection: Enabled
├── RBAC Authorization: true
└── Private Endpoint: pe-kv-erp-cc-prod

Private Endpoints (4)
├── pe-st-erp-cc-prod (Storage blob)
├── pe-st-file-erp-cc-prod (Storage file)
├── pe-acr-erp-cc-prod (Container Registry)
└── pe-kv-erp-cc-prod (Key Vault)
```

**Cost**: ~$50-$100/month

---

### 10. Database Services (2 resources)

```
PostgreSQL Flexible Server
├── Name: psql-erp-cc-prod
├── Version: 15
├── SKU: GP_Standard_D4s_v3 (4 vCores, 16 GB RAM)
├── Storage: 128 GB (auto-grow enabled)
├── Backup Retention: 7 days
├── Geo-Redundant Backup: Enabled
├── High Availability: Disabled (enable for production)
├── Public Access: Disabled
└── Private Endpoint: pe-psql-erp-cc-prod

Private Endpoint
└── pe-psql-erp-cc-prod
```

**Cost**: ~$200-$400/month (depends on SKU and storage)

---

### 11. AKS Cluster (1 resource + node pools)

```
AKS Cluster
├── Name: aks-erp-cc-prod
├── Kubernetes Version: 1.28.x (latest stable)
├── DNS Prefix: aks-erp-cc-prod
├── Network Plugin: azure (Azure CNI Overlay)
├── Network Policy: calico
├── Service CIDR: 10.100.0.0/16
├── DNS Service IP: 10.100.0.10
├── Pod CIDR: 10.244.0.0/16
├── Outbound Type: loadBalancer (Stage 1) → userDefinedRouting (Stage 2)
├── Private Cluster: true
├── API Server Authorized IP Ranges: (configured)
├── Istio Service Mesh: Enabled (inbuilt)
└── Subnet: AksSubnet (10.1.0.0/20)

System Node Pool
├── Name: system
├── VM Size: Standard_D4s_v3
├── Node Count: 2-3
├── OS Disk Size: 128 GB
├── OS Type: Linux
├── Mode: System
└── Subnet: AksSubnet (10.1.0.0/20)

User Node Pool
├── Name: user
├── VM Size: Standard_D8s_v3
├── Node Count: 2-5 (auto-scaling)
├── OS Disk Size: 128 GB
├── OS Type: Linux
├── Mode: User
└── Subnet: AksSubnet (10.1.0.0/20)
```

**Cost**: ~$1,000-$3,500/month (depends on node count and VM sizes)

---

### 12. Virtual Machines (3 resources)

```
Jumpbox VM
├── Name: vm-jumpbox-cc-prod
├── Size: Standard_B2s
├── OS: Ubuntu 22.04 LTS
├── Subnet: SharedServicesSubnet (10.0.4.0/24)
├── Private IP: Dynamic
├── Public IP: None (access via Bastion)
└── Managed Identity: System-assigned

Agent VM (for Azure DevOps)
├── Name: vm-agent-cc-prod
├── Size: Standard_D4s_v3
├── OS: Ubuntu 22.04 LTS
├── Subnet: SharedServicesSubnet (10.0.4.0/24)
├── Private IP: Dynamic
├── Public IP: None (access via Bastion)
└── Managed Identity: System-assigned

Network Interfaces (2)
├── nic-jumpbox-cc-prod
└── nic-agent-cc-prod
```

**Cost**: ~$50-$200/month

---

## Two-Stage Deployment

### Stage 1: Initial Deployment (loadBalancer)
- **Outbound Type**: `loadBalancer`
- **AKS Egress**: Direct internet via Azure Load Balancer
- **Purpose**: Deploy AKS and enable Istio to get Load Balancer IP

**Resources Created**: All resources listed above

### Stage 2: Firewall Routing (userDefinedRouting)
- **Outbound Type**: `userDefinedRouting`
- **AKS Egress**: All traffic routed through Azure Firewall
- **Route Table**: Applied to AksSubnet with default route to Firewall
- **Purpose**: Centralized security and traffic inspection

**Changes**: Route table configuration updated, AKS outbound type changed

---

## Resource Dependencies

```
Resource Group
└── Log Analytics Workspace
    └── Hub VNet
        ├── Azure Firewall (requires AzureFirewallSubnet)
        ├── Azure Bastion (requires AzureBastionSubnet)
        └── Spoke VNet
            ├── VNet Peering (Hub ↔ Spoke)
            ├── Private DNS Zones
            │   └── VNet Links
            ├── Storage Account
            │   └── Private Endpoints
            ├── Container Registry
            │   └── Private Endpoints
            ├── Key Vault
            │   └── Private Endpoints
            ├── PostgreSQL
            │   └── Private Endpoints
            ├── AKS Cluster
            │   ├── System Node Pool
            │   └── User Node Pool
            └── Virtual Machines
```

---

## Next Steps

After deployment:
1. Verify all resources in Azure Portal
2. Get AKS credentials: `./scripts/get-aks-credentials.sh`
3. Get Istio Load Balancer IP: `./scripts/get-istio-lb-ip.sh`
4. Update `terraform.tfvars` with Istio LB IP
5. Set `deployment_stage = "stage2"`
6. Run `terraform apply` again for Stage 2

---

**Last Updated**: November 2025  
**Version**: 2.1.0

