# Infrastructure Deployment Guide - Production Environment
## Canada Central Production Environment - Step-by-Step Deployment

This document provides a detailed, step-by-step explanation of what infrastructure will be created, in what order, and how resources connect to each other.

---

## Table of Contents
1. [Overview](#overview)
2. [Resource Group Creation](#step-1-resource-group-creation)
3. [Monitoring Foundation](#step-2-monitoring-foundation)
4. [Networking - Hub VNet](#step-3-networking---hub-vnet)
5. [Networking - Spoke VNet](#step-4-networking---spoke-vnet)
6. [VNet Peering](#step-5-vnet-peering)
7. [Private DNS Zones](#step-6-private-dns-zones)
8. [Azure Firewall](#step-7-azure-firewall)
9. [Azure Bastion](#step-8-azure-bastion)
10. [Storage Services](#step-9-storage-services)
11. [Database Services](#step-10-database-services)
12. [Compute - AKS Cluster](#step-11-compute---aks-cluster)
13. [Compute - Virtual Machines](#step-12-compute---virtual-machines)
14. [Route Table Configuration](#step-13-route-table-configuration)
15. [Network Flow Summary](#network-flow-summary)

---

## Overview

### Architecture Pattern
- **Hub-Spoke Network Topology**: Centralized security and shared services in Hub, workloads in Spoke
- **Single Resource Group**: All resources deployed to `rg-erp-cc-prod`
- **Region**: Canada Central
- **Environment**: Production

### Key CIDR Ranges
- **Hub VNet**: `10.0.0.0/16`
- **Spoke VNet**: `10.1.0.0/16`
- **AKS Service CIDR**: `10.100.0.0/16`
- **AKS Pod CIDR**: `10.244.0.0/16`
- **AKS DNS Service IP**: `10.100.0.10`

---

## Step 1: Resource Group Creation

### What is Created
- **Resource Group**: `rg-erp-cc-prod`
- **Location**: `canadacentral`
- **Tags**: Environment, Region, ManagedBy, Project, CostCenter

### Details
- This is the container for all subsequent resources
- All resources will be created within this resource group
- Tags are applied for organization and cost tracking

---

## Step 2: Monitoring Foundation

### What is Created
- **Log Analytics Workspace**: `log-erp-cc-prod`
- **Location**: `canadacentral`
- **Retention**: 30 days (configurable)

### Details
- Centralized logging destination for all Azure resources
- Used by:
  - Azure Firewall (application, network, DNS logs)
  - Azure Bastion (audit logs)
  - Key Vault (audit events)
  - PostgreSQL (database logs)
  - AKS Cluster (container insights)
  - Storage Account (transaction metrics)

### Connection
- Connected to all resources via Diagnostic Settings
- No network connectivity required (uses Azure Monitor service)

---

## Step 3: Networking - Hub VNet

### What is Created
- **Virtual Network**: `vnet-hub-canadacentral-prod`
- **Address Space**: `10.0.0.0/16`
- **Location**: `canadacentral`

### Subnets Created (in order)

#### 1. Azure Firewall Subnet
- **Name**: `AzureFirewallSubnet` (required name)
- **CIDR**: `10.0.1.0/26` (64 IPs)
- **Purpose**: Hosts Azure Firewall primary interface
- **Notes**: 
  - Must be exactly `/26` size
  - Cannot have NSG or Route Table attached
  - Reserved for Azure Firewall only

#### 2. Azure Firewall Management Subnet
- **Name**: `AzureFirewallManagementSubnet` (required name)
- **CIDR**: `10.0.2.0/26` (64 IPs)
- **Purpose**: Hosts Azure Firewall management interface (for forced tunneling)
- **Notes**:
  - Required for Premium SKU with forced tunneling
  - Must be exactly `/26` size
  - Cannot have NSG or Route Table attached

#### 3. Azure Bastion Subnet
- **Name**: `AzureBastionSubnet` (required name)
- **CIDR**: `10.0.3.0/27` (32 IPs)
- **Purpose**: Hosts Azure Bastion service
- **Notes**:
  - Must be at least `/27` size
  - Cannot have NSG or Route Table attached
  - Only Azure Bastion can be deployed here

#### 4. Shared Services Subnet
- **Name**: `snet-shared-services` (default)
- **CIDR**: `10.0.4.0/24` (256 IPs)
- **Purpose**: Future shared services (e.g., domain controllers, shared VMs)
- **Notes**: Can host VMs, but currently unused in this deployment

#### 5. Private Endpoints Subnet (Hub)
- **Name**: `snet-private-endpoints` (default)
- **CIDR**: `10.0.5.0/24` (256 IPs)
- **Purpose**: Private endpoints for hub services (currently unused)
- **Network Policies**: Disabled (required for private endpoints)

#### 6. Jumpbox Subnet (Hub)
- **Name**: `snet-jumpbox` (default)
- **CIDR**: `10.0.6.0/27` (32 IPs)
- **Purpose**: Reserved for future hub jumpbox (currently unused)

### Network Security
- **NSGs**: Not explicitly created for Hub subnets (Azure-managed subnets don't use NSGs)
- **Route Tables**: Not attached to Hub subnets (Azure-managed)

---

## Step 4: Networking - Spoke VNet

### What is Created
- **Virtual Network**: `vnet-spoke-canadacentral-prod`
- **Address Space**: `10.1.0.0/16`
- **Location**: `canadacentral`

### Subnets Created (in order)

#### 1. AKS Node Pool Subnet
- **Name**: `snet-aks-nodes` (default)
- **CIDR**: `10.1.0.0/20` (4096 IPs)
- **Purpose**: Hosts both AKS system and user node pools
- **Notes**:
  - Large subnet to accommodate AKS node scaling
  - Shared by both system and user node pools
  - Access to Azure services handled through private endpoints and firewall rules

#### 2. Private Endpoints Subnet
- **Name**: `snet-private-endpoints` (default)
- **CIDR**: `10.1.16.0/24` (256 IPs)
- **Purpose**: Private endpoints for all PaaS services
- **Network Policies**: Disabled (required for private endpoints)
- **Private Endpoints Created Here**:
  - Key Vault private endpoint
  - Storage Account blob private endpoint
  - Storage Account file private endpoint
  - Container Registry private endpoint
  - PostgreSQL uses delegated subnet (different mechanism)

#### 3. Jumpbox/Agent VM Subnet
- **Name**: `snet-jumpbox` (default)
- **CIDR**: `10.1.17.0/27` (32 IPs)
- **Purpose**: Hosts jumpbox and agent VMs
- **VMs Deployed Here**:
  - Jumpbox VM: `vm-jumpbox-erp-cc-prod`
  - Agent VM: `vm-agent-erp-cc-prod`

### Network Security
- **NSGs**: Not explicitly created in this deployment
- **Route Tables**: AKS subnet will get route table in Stage 2 (see Step 13)

---

## Step 5: VNet Peering

### What is Created
- **Hub to Spoke Peering**: `peer-vnet-hub-canadacentral-prod-to-vnet-spoke-canadacentral-prod`
- **Spoke to Hub Peering**: `peer-vnet-spoke-canadacentral-prod-to-vnet-hub-canadacentral-prod`

### Configuration
- **Allow Virtual Network Access**: `true` (enables communication)
- **Allow Forwarded Traffic**: `true` (allows traffic forwarded by gateway/firewall)
- **Gateway Transit**: `false` (no VPN/ExpressRoute gateway in this setup)
- **Use Remote Gateways**: `false`

### Network Flow
- **Hub → Spoke**: Direct communication enabled
- **Spoke → Hub**: Direct communication enabled
- **Traffic Path**: 
  - Hub resources can reach Spoke resources directly
  - Spoke resources can reach Hub resources directly
  - Traffic does NOT automatically route through firewall (requires route table)

### Dependencies
- Requires both Hub and Spoke VNets to exist first
- Bidirectional peering ensures connectivity in both directions

---

## Step 6: Private DNS Zones

### What is Created
Six Private DNS Zones for private endpoint resolution:

#### 1. Azure Container Registry DNS Zone
- **Zone Name**: `privatelink.azurecr.io`
- **Purpose**: Resolves ACR private endpoints
- **Linked VNet**: Spoke VNet (`vnet-spoke-canadacentral-prod`)
- **Auto-registration**: Disabled

#### 2. Azure Key Vault DNS Zone
- **Zone Name**: `privatelink.vaultcore.azure.net`
- **Purpose**: Resolves Key Vault private endpoints
- **Linked VNet**: Spoke VNet
- **Auto-registration**: Disabled

#### 3. Azure Storage Blob DNS Zone
- **Zone Name**: `privatelink.blob.core.windows.net`
- **Purpose**: Resolves Storage Account blob private endpoints
- **Linked VNet**: Spoke VNet
- **Auto-registration**: Disabled

#### 4. Azure Storage File DNS Zone
- **Zone Name**: `privatelink.file.core.windows.net`
- **Purpose**: Resolves Storage Account file share private endpoints
- **Linked VNet**: Spoke VNet
- **Auto-registration**: Disabled

#### 5. PostgreSQL DNS Zone
- **Zone Name**: `privatelink.postgres.database.azure.com`
- **Purpose**: Resolves PostgreSQL Flexible Server private endpoints
- **Linked VNet**: Spoke VNet
- **Auto-registration**: Disabled

#### 6. AKS DNS Zone
- **Zone Name**: `privatelink.canadacentral.azmk8s.io`
- **Purpose**: Resolves AKS API server private endpoint
- **Linked VNet**: Spoke VNet
- **Auto-registration**: Disabled

### How It Works
1. When a private endpoint is created, Azure automatically creates an A record in the linked DNS zone
2. Resources in the Spoke VNet resolve private endpoint FQDNs to private IPs
3. Example: `kv-erp-cc-prod.vaultcore.azure.net` resolves to private IP in `10.1.16.0/24` subnet

### Dependencies
- Created before private endpoints (DNS zones must exist first)
- Linked to Spoke VNet (where private endpoints will be created)

---

## Step 7: Azure Firewall

### What is Created
- **Azure Firewall**: `azfw-canadacentral-prod`
- **SKU**: Premium (`AZFW_VNet`, `Premium` tier)
- **Location**: `canadacentral`
- **Availability Zones**: Zones 1, 2, 3 (high availability)

### Public IP Addresses
1. **Firewall Public IP**: `pip-azfw-canadacentral-prod`
   - **Allocation**: Static
   - **SKU**: Standard
   - **Zones**: 1, 2, 3
   - **Purpose**: Main firewall public IP for inbound/outbound traffic

2. **Firewall Management Public IP**: `pip-azfw-mgmt-canadacentral-prod`
   - **Allocation**: Static
   - **SKU**: Standard
   - **Zones**: 1, 2, 3
   - **Purpose**: Management interface for forced tunneling

### Firewall Policy
- **Policy Name**: `azfwpol-canadacentral-prod`
- **SKU**: Premium
- **Threat Intelligence Mode**: `Deny` (blocks known malicious IPs)
- **IDPS Mode**: `Deny` (Intrusion Detection and Prevention System)
- **DNS Proxy**: Enabled (firewall acts as DNS proxy)

### Network Configuration
- **Primary Subnet**: `AzureFirewallSubnet` (`10.0.1.0/26`)
- **Management Subnet**: `AzureFirewallManagementSubnet` (`10.0.2.0/26`)
- **Private IP**: Assigned automatically from firewall subnet
- **Management Private IP**: Assigned automatically from management subnet

### Firewall Rules

#### DNAT Rules (Priority 100) - Inbound Traffic
**Rule Collection**: `cloudflare-to-istio-ilb`

1. **HTTP Rule**: `allow-http-from-cloudflare`
   - **Source**: Cloudflare IPv4 ranges (dynamically fetched)
   - **Destination**: Firewall Public IP, Port 80
   - **Translated To**: Internal LB IP (from `istio_internal_lb_ip` variable), Port 80
   - **Protocol**: TCP
   - **Purpose**: Routes HTTP traffic from Cloudflare to Istio internal load balancer

2. **HTTPS Rule**: `allow-https-from-cloudflare`
   - **Source**: Cloudflare IPv4 ranges (dynamically fetched)
   - **Destination**: Firewall Public IP, Port 443
   - **Translated To**: Internal LB IP, Port 443
   - **Protocol**: TCP
   - **Purpose**: Routes HTTPS traffic from Cloudflare to Istio internal load balancer

**Note**: In Stage 1, `istio_internal_lb_ip` is empty, so DNAT rules are created but non-functional. In Stage 2, after AKS deployment, this IP is populated.

#### Network Rules (Priority 200) - Layer 3/4 Traffic

**Rule Collection 1**: `allow-azure-services` (Priority 100)
- **Azure Monitor**: Port 443, Service Tag `AzureMonitor`
- **Azure Storage**: Ports 443, 445, Service Tag `Storage`
- **Azure Container Registry**: Port 443, Service Tag `AzureContainerRegistry`
- **Azure Key Vault**: Port 443, Service Tag `AzureKeyVault`
- **Azure SQL/PostgreSQL**: Ports 1433, 5432, Service Tag `Sql`

**Rule Collection 2**: `allow-aks-required` (Priority 110)
- **AKS API Server**: Ports 443, 9000, Service Tag `AzureCloud`
- **NTP Servers**: Port 123 (UDP)
  - `91.189.89.198` (ntp.ubuntu.com)
  - `91.189.94.4` (ntp.ubuntu.com)
  - `91.189.91.157` (ntp.ubuntu.com)
  - `time.windows.com`
- **External DNS**: Port 53 (UDP/TCP)
  - `8.8.8.8`, `8.8.4.4` (Google DNS)
  - `1.1.1.1`, `1.0.0.1` (Cloudflare DNS)

**Rule Collection 3**: `allow-custom-outbound` (Priority 120)
- **Custom Rules**: Configurable via variables (currently empty)

**Rule Collection 4**: `allow-vnet-to-vnet` (Priority 130)
- **Hub to Spoke**: 
  - Source: `10.0.0.0/16` (Hub VNet)
  - Destination: `10.1.0.0/16` (Spoke VNet)
  - Protocol: Any
  - Ports: All
- **Spoke to Hub**:
  - Source: `10.1.0.0/16` (Spoke VNet)
  - Destination: `10.0.0.0/16` (Hub VNet)
  - Protocol: Any
  - Ports: All

#### Application Rules (Priority 300) - Layer 7 FQDN Filtering

**Rule Collection 1**: `allow-azure-fqdns` (Priority 100)
- **Azure Management**: 
  - `management.azure.com`, `*.management.azure.com`
  - `login.microsoftonline.com`, `*.login.microsoftonline.com`
  - `graph.windows.net`
  - Protocol: HTTPS, Port 443
- **Azure Container Registry**:
  - `*.azurecr.io`
  - `*.blob.core.windows.net`
  - `mcr.microsoft.com`, `*.data.mcr.microsoft.com`
  - Protocol: HTTPS, Port 443
- **Azure Key Vault**:
  - `*.vault.azure.net`
  - `*.vaultcore.azure.net`
  - Protocol: HTTPS, Port 443
- **Azure Monitor**:
  - `*.ods.opinsights.azure.com`
  - `*.oms.opinsights.azure.com`
  - `*.monitoring.azure.com`
  - `dc.services.visualstudio.com`
  - Protocol: HTTPS, Port 443

**Rule Collection 2**: `allow-aks-fqdns` (Priority 110)
- **AKS Core**: Service Tag `AzureKubernetesService`, HTTPS Port 443
- **Ubuntu Updates**:
  - `security.ubuntu.com`
  - `azure.archive.ubuntu.com`
  - `changelogs.ubuntu.com`
  - Protocols: HTTP (80), HTTPS (443)
- **Kubernetes Packages**:
  - `packages.cloud.google.com`
  - `apt.kubernetes.io`
  - Protocol: HTTPS, Port 443
- **Microsoft Packages**:
  - `packages.microsoft.com`
  - Protocol: HTTPS, Port 443

**Rule Collection 3**: `allow-container-registries` (Priority 120)
- **Docker Hub**:
  - `hub.docker.com`
  - `registry-1.docker.io`
  - `*.docker.io`
  - `production.cloudflare.docker.com`
  - Protocol: HTTPS, Port 443
- **GitHub Container Registry**:
  - `ghcr.io`, `*.ghcr.io`
  - Protocol: HTTPS, Port 443
- **Quay.io**:
  - `quay.io`, `*.quay.io`
  - Protocol: HTTPS, Port 443

**Rule Collection 4**: `allow-custom-fqdns` (Priority 130)
- **Custom FQDNs**: Configurable via variables (currently empty)

### Diagnostic Settings
- **Log Analytics Workspace**: Connected to `log-erp-cc-prod`
- **Logs Collected**:
  - AzureFirewallApplicationRule
  - AzureFirewallNetworkRule
  - AzureFirewallDnsProxy
  - AZFWApplicationRule
  - AZFWNetworkRule
  - AZFWNatRule
  - AZFWThreatIntel
  - AZFWIdpsSignature
  - AZFWDnsQuery
  - AZFWFqdnResolveFailure
- **Metrics**: AllMetrics

### Dependencies
- Requires Hub VNet and firewall subnets
- Requires Log Analytics Workspace
- Created before AKS (AKS depends on firewall)

---

## Step 8: Azure Bastion

### What is Created
- **Azure Bastion**: `bastion-canadacentral-prod`
- **SKU**: Standard
- **Location**: `canadacentral`
- **Scale Units**: 2 (for high availability)

### Public IP
- **Public IP**: `pip-bastion-canadacentral-prod`
- **Allocation**: Static
- **SKU**: Standard
- **Zones**: 1, 2, 3

### Network Configuration
- **Subnet**: `AzureBastionSubnet` (`10.0.3.0/27`)
- **Private IP**: Assigned automatically from Bastion subnet

### Features Enabled
- **Copy/Paste**: Enabled
- **File Copy**: Enabled
- **IP Connect**: Enabled (SSH/RDP over IP)
- **Tunneling**: Enabled (native client support)
- **Shareable Link**: Disabled
- **Kerberos**: Disabled
- **Session Recording**: Disabled

### Access
- Provides secure RDP/SSH access to VMs without public IPs
- Accessible via Azure Portal or native clients
- No need to expose VM ports to internet

### Diagnostic Settings
- **Log Analytics Workspace**: Connected to `log-erp-cc-prod`
- **Logs**: BastionAuditLogs
- **Metrics**: AllMetrics

### Dependencies
- Requires Hub VNet and Bastion subnet
- Requires Log Analytics Workspace

---

## Step 9: Storage Services

### 9.1 Azure Key Vault

#### What is Created
- **Key Vault**: `kv-erp-cc-prod`
- **SKU**: Premium
- **Location**: `canadacentral`

#### Configuration
- **RBAC Authorization**: Enabled (uses Azure RBAC instead of access policies)
- **Public Network Access**: Disabled (private endpoint only)
- **Purge Protection**: Disabled (configurable)
- **Soft Delete Retention**: 7 days (default)

#### Network Access
- **Network ACLs**:
  - **Default Action**: Deny
  - **Bypass**: AzureServices (allows Azure services to access)
  - **Allowed IPs**: None (private endpoint only)
  - **Allowed Subnets**: None (private endpoint only)

#### Private Endpoint
- **Private Endpoint**: `kv-erp-cc-prod-pe`
- **Subnet**: `snet-private-endpoints` (`10.1.16.0/24`)
- **Private DNS Zone**: `privatelink.vaultcore.azure.net`
- **Private IP**: Assigned automatically from private endpoints subnet
- **Connection**: Automatic approval

#### Diagnostic Settings
- **Log Analytics Workspace**: Connected to `log-erp-cc-prod`
- **Logs**: AuditEvent, AzurePolicyEvaluationDetails
- **Metrics**: AllMetrics

#### Dependencies
- Requires Private DNS Zone for Key Vault
- Requires Spoke VNet private endpoints subnet

---

### 9.2 Azure Storage Account

#### What is Created
- **Storage Account**: `sterpccprod` (name must be globally unique, lowercase, no hyphens)
- **Location**: `canadacentral`
- **Tier**: Standard
- **Replication**: ZRS (Zone Redundant Storage)
- **Kind**: StorageV2
- **Hierarchical Namespace**: Disabled (ADLS Gen2 not enabled)

#### Configuration
- **Minimum TLS Version**: TLS 1.2
- **Public Access**: Disabled (no public blob access)
- **Public Network Access**: Disabled (private endpoint only)

#### Network Access
- **Network Rules**:
  - **Default Action**: Deny
  - **Bypass**: AzureServices (allows Azure services to access)
  - **Allowed IPs**: None (private endpoint only)
  - **Allowed Subnets**: None (private endpoint only)

#### Blob Properties
- **Versioning**: Disabled (configurable)
- **Change Feed**: Disabled (configurable)
- **Delete Retention**: Disabled (configurable)
- **Container Delete Retention**: Disabled (configurable)

#### Private Endpoints
1. **Blob Private Endpoint**: `sterpccprod-blob-pe`
   - **Subnet**: `snet-private-endpoints` (`10.1.16.0/24`)
   - **Private DNS Zone**: `privatelink.blob.core.windows.net`
   - **Subresource**: `blob`
   - **Private IP**: Assigned automatically

2. **File Private Endpoint**: `sterpccprod-file-pe`
   - **Subnet**: `snet-private-endpoints` (`10.1.16.0/24`)
   - **Private DNS Zone**: `privatelink.file.core.windows.net`
   - **Subresource**: `file`
   - **Private IP**: Assigned automatically

#### Diagnostic Settings
- **Log Analytics Workspace**: Connected to `log-erp-cc-prod`
- **Metrics**: Transaction, Capacity

#### Dependencies
- Requires Private DNS Zones for blob and file
- Requires Spoke VNet private endpoints subnet

---

### 9.3 Azure Container Registry

#### What is Created
- **Container Registry**: `acrerpccprod` (name must be globally unique, lowercase, no hyphens)
- **SKU**: Premium
- **Location**: `canadacentral`

#### Configuration
- **Admin User**: Disabled (uses managed identity)
- **Public Network Access**: Disabled (private endpoint only)

#### Private Endpoint
- **Private Endpoint**: `acrerpccprod-pe`
- **Subnet**: `snet-private-endpoints` (`10.1.16.0/24`)
- **Private DNS Zone**: `privatelink.azurecr.io`
- **Subresource**: `registry`
- **Private IP**: Assigned automatically from private endpoints subnet

#### Diagnostic Settings
- **Log Analytics Workspace**: Connected to `log-erp-cc-prod`
- **Logs**: ContainerRegistryRepositoryEvents, ContainerRegistryLoginEvents
- **Metrics**: AllMetrics

#### Dependencies
- Requires Private DNS Zone for ACR
- Requires Spoke VNet private endpoints subnet
- Created before AKS (AKS needs ACR access)

---

## Step 10: Database Services

### PostgreSQL Flexible Server

#### What is Created
- **PostgreSQL Server**: `psql-erp-cc-prod`
- **Version**: 17
- **Location**: `canadacentral`
- **SKU**: `GP_Standard_D4s_v3` (General Purpose, 4 vCores)
- **Storage**: 128 GB (131072 MB)

#### Configuration
- **Administrator Login**: `master` (from variables)
- **Administrator Password**: From variables (sensitive)
- **Backup Retention**: 7 days
- **Geo-Redundant Backup**: Disabled (configurable)
- **High Availability**: Disabled (configurable)
- **Public Network Access**: Disabled (private endpoint only)

#### Network Configuration
- **Delegated Subnet**: `snet-private-endpoints` (`10.1.16.0/24`)
  - PostgreSQL uses subnet delegation (different from private endpoints)
  - The subnet is delegated to `Microsoft.DBforPostgreSQL/flexibleServers`
- **Private DNS Zone**: `privatelink.postgres.database.azure.com`
- **Private IP**: Assigned automatically from delegated subnet

#### Server Configurations
- **max_connections**: Default (configurable)
- **shared_buffers**: Default (configurable)
- **work_mem**: Default (configurable)
- **maintenance_work_mem**: Default (configurable)

#### Databases
- **Default Databases**: None created by default (configurable via variables)

#### Diagnostic Settings
- **Log Analytics Workspace**: Connected to `log-erp-cc-prod`
- **Logs**: PostgreSQLLogs
- **Metrics**: AllMetrics

#### Dependencies
- Requires Private DNS Zone for PostgreSQL
- Requires Spoke VNet private endpoints subnet (delegated)
- Created before AKS (if AKS needs database access)

---

## Step 11: Compute - AKS Cluster

### What is Created
- **AKS Cluster**: `aks-canadacentral-prod`
- **Kubernetes Version**: 1.33
- **Location**: `canadacentral`
- **DNS Prefix**: `aks-canadacentral-prod-dns`
- **Node Resource Group**: `rg-aks-canadacentral-prod-nodes` (auto-created)

### Network Configuration
- **VNet**: `vnet-spoke-canadacentral-prod`
- **Subnet**: `snet-aks-nodes` (`10.1.0.0/20`)
- **Network Plugin**: `azure`
- **Network Plugin Mode**: `overlay`
- **Network Policy**: `calico`
- **Network Data Plane**: `azure`
- **Load Balancer SKU**: `standard`

### IP Address Ranges
- **Service CIDR**: `10.100.0.0/16` (for Kubernetes services)
- **DNS Service IP**: `10.100.0.10` (within service CIDR)
- **Pod CIDR**: `10.244.0.0/16` (for Kubernetes pods)
- **Outbound Type**: 
  - **Stage 1**: `loadBalancer` (uses Azure Load Balancer for outbound)
  - **Stage 2**: `userDefinedRouting` (routes through firewall via route table)

### Cluster Configuration
- **Private Cluster**: Enabled
- **Private Cluster Public FQDN**: Disabled
- **Private DNS Zone**: System-managed
- **RBAC**: Enabled
- **Azure RBAC**: Enabled (uses Azure AD for authentication)
- **Admin Group Object IDs**: `8711b4ad-7b9c-4f4f-9972-841191901995`
- **Tenant ID**: `8c440439-38da-4b76-9de0-002f47f4e860`

### Identity
- **Identity Type**: User Assigned
- **Identity Name**: `id-aks-canadacentral-prod`
- **Identity Created**: Yes (separate resource)

### Node Pools

#### System Node Pool
- **Name**: `system`
- **Mode**: System
- **VM Size**: `Standard_D4s_v5` (4 vCPUs, 16 GB RAM)
- **Min Count**: 1
- **Max Count**: 5
- **OS Disk Size**: 128 GB
- **OS Disk Type**: Managed
- **Zones**: 1, 2, 3 (spread across availability zones)
- **Max Pods**: 30
- **Scale Down Mode**: Delete
- **Upgrade Settings**: Max surge 33%

#### User Node Pool
- **Name**: `user`
- **Mode**: User
- **VM Size**: `Standard_F16s_v2` (16 vCPUs, 32 GB RAM)
- **Min Count**: 1
- **Max Count**: 5
- **OS Disk Size**: 128 GB
- **OS Disk Type**: Managed
- **Zones**: 1, 2, 3
- **Max Pods**: 110
- **Node Labels**:
  - `environment=prod`
  - `nodepool-type=user`
  - `subnet-shared=true`
  - `workload=application`
- **Node Taints**: None
- **Scale Down Mode**: Delete
- **Upgrade Settings**: Max surge 33%

### Service Mesh
- **Istio**: Enabled (inbuilt AKS feature)
- **Internal Ingress Gateway**: Enabled
- **External Ingress Gateway**: Disabled
- **Revision**: `default`
- **Internal LB IP**: Assigned automatically (used for firewall DNAT rules in Stage 2)

### Integrations

#### Key Vault Secrets Provider
- **Enabled**: Yes
- **Secret Rotation**: Enabled
- **Rotation Interval**: 2 minutes
- **Identity**: Auto-created secret identity

#### Container Insights (Monitoring)
- **Log Analytics Workspace**: `log-erp-cc-prod`
- **OMS Agent**: Enabled
- **Metrics**: Enabled

### Role Assignments
1. **ACR Pull**: AKS identity gets `AcrPull` role on Container Registry
2. **Key Vault Secrets User**: AKS secret identity gets `Key Vault Secrets User` role on Key Vault
3. **Monitoring Metrics Publisher**: AKS identity gets `Monitoring Metrics Publisher` role on Log Analytics
4. **Network Contributor**: AKS identity gets `Network Contributor` role on VNet/subnets

### Auto Scaler Profile
- **Balance Similar Node Groups**: Enabled
- **DaemonSet Eviction for Empty Nodes**: Disabled
- **DaemonSet Eviction for Occupied Nodes**: Enabled
- **Expander**: Random
- **Max Graceful Termination**: 600 seconds
- **Max Node Provisioning Time**: 15 minutes
- **Max Unready Nodes**: 3
- **Max Unready Percentage**: 45%
- **Scale Down Delay After Add**: 10 minutes
- **Scale Down Delay After Delete**: 10 seconds
- **Scale Down Delay After Failure**: 3 minutes
- **Scale Down Unneeded**: 10 minutes
- **Scale Down Unready**: 20 minutes
- **Scale Down Utilization Threshold**: 0.5 (50%)
- **Skip Nodes with System Pods**: Enabled

### Dependencies
- Requires VNet Peering (to access hub resources)
- Requires Azure Firewall (for outbound traffic in Stage 2)
- Requires Container Registry (for pulling images)
- Requires Key Vault (for secrets)
- Requires Log Analytics Workspace (for monitoring)

---

## Step 12: Compute - Virtual Machines

### 12.1 Jumpbox VM

#### What is Created
- **VM Name**: `vm-jumpbox-erp-cc-prod`
- **Location**: `canadacentral`
- **VM Size**: `Standard_B2s` (2 vCPUs, 4 GB RAM)
- **OS**: Ubuntu 24.04 LTS

#### Network Configuration
- **Subnet**: `snet-jumpbox` (`10.1.17.0/27`) in Spoke VNet
- **NIC Name**: `nic-jumpbox-erp-cc-prod`
- **Private IP**: Assigned dynamically from jumpbox subnet
- **Public IP**: None (access via Azure Bastion)

#### Storage
- **OS Disk**: `disk-jumpbox-erp-cc-prod`
- **Disk Type**: Premium LRS
- **Disk Size**: 30 GB
- **Caching**: ReadWrite

#### Authentication
- **Admin Username**: `azureuser` (from variables)
- **Admin Password**: From variables (sensitive)
- **SSH Key**: Not configured (password authentication)

#### Extensions
1. **AAD SSH Login**: `AADSSHLoginForLinux`
   - Enables Azure AD authentication for SSH
2. **Dependency Agent**: `DependencyAgentLinux`
   - For Application Insights dependency mapping
3. **Azure Monitor Agent**: `AzureMonitorLinuxAgent`
   - For Log Analytics integration

#### Identity
- **Type**: System Assigned
- **Purpose**: For Azure resource access

#### Access
- **Via Azure Bastion**: Yes (from Hub VNet)
- **Via Public IP**: No
- **Via SSH**: Yes (through Bastion or direct if NSG allows)

---

### 12.2 Agent VM

#### What is Created
- **VM Name**: `vm-agent-erp-cc-prod`
- **Location**: `canadacentral`
- **VM Size**: `Standard_B2s` (2 vCPUs, 4 GB RAM)
- **OS**: Ubuntu 24.04 LTS

#### Network Configuration
- **Subnet**: `snet-jumpbox` (`10.1.17.0/27`) in Spoke VNet (shared with jumpbox)
- **NIC Name**: `nic-agent-erp-cc-prod`
- **Private IP**: Assigned dynamically from jumpbox subnet
- **Public IP**: None (access via Azure Bastion)

#### Storage
- **OS Disk**: `disk-agent-erp-cc-prod`
- **Disk Type**: Premium LRS
- **Disk Size**: 30 GB
- **Caching**: ReadWrite

#### Authentication
- **Admin Username**: `azureuser` (from variables)
- **Admin Password**: From variables (sensitive)
- **SSH Key**: Not configured

#### Extensions
1. **AAD SSH Login**: `AADSSHLoginForLinux`
2. **Dependency Agent**: `DependencyAgentLinux`
3. **Azure Monitor Agent**: `AzureMonitorLinuxAgent`

#### Identity
- **Type**: System Assigned

#### Access
- **Via Azure Bastion**: Yes
- **Via Public IP**: No

---

## Step 13: Route Table Configuration

### What is Created (Stage 2 Only)
- **Route Table**: `rt-aks-canadacentral-prod`
- **Location**: `canadacentral`
- **BGP Route Propagation**: Disabled

### Routes
1. **Default Route**: `default-via-firewall`
   - **Address Prefix**: `0.0.0.0/0` (all traffic)
   - **Next Hop Type**: VirtualAppliance
   - **Next Hop IP**: Azure Firewall private IP (from `10.0.1.0/26` subnet)
   - **Purpose**: Routes all outbound traffic from AKS nodes through firewall

### Subnet Association
- **Associated Subnet**: `snet-aks-nodes` (`10.1.0.0/20`)
- **Effect**: All traffic from AKS nodes (except intra-VNet) goes through firewall

### When Created
- **Stage 1**: Not created (AKS uses load balancer for outbound)
- **Stage 2**: Created after AKS deployment and firewall configuration
- **Trigger**: `deployment_stage = "stage2"` in terraform.tfvars

### Dependencies
- Requires Azure Firewall (to get private IP)
- Requires AKS subnet
- Created after AKS cluster is deployed

---

## Network Flow Summary

### Inbound Traffic Flow (Stage 2)

1. **Internet → Cloudflare** (User requests)
2. **Cloudflare → Azure Firewall Public IP** (Port 80/443)
3. **Azure Firewall DNAT Rule** (Translates to internal LB IP)
4. **Azure Firewall → Istio Internal Load Balancer** (Port 80/443)
5. **Istio → AKS Pods** (Application traffic)

### Outbound Traffic Flow (Stage 2)

1. **AKS Pods → AKS Node Subnet** (`10.1.0.0/20`)
2. **Route Table** (Routes `0.0.0.0/0` to firewall)
3. **Azure Firewall** (Applies network/application rules)
4. **Azure Firewall → Internet** (Allowed destinations only)

### Inter-VNet Communication

1. **Hub → Spoke**: Direct via VNet peering
2. **Spoke → Hub**: Direct via VNet peering
3. **Spoke → Internet**: Via Azure Firewall (if route table configured)

### Private Endpoint Communication

1. **Resource in Spoke VNet** (e.g., AKS pod)
2. **DNS Query** (e.g., `kv-erp-cc-prod.vaultcore.azure.net`)
3. **Private DNS Zone** (Resolves to private IP in `10.1.16.0/24`)
4. **Private Endpoint** (Direct connection within VNet)
5. **Target Service** (Key Vault, Storage, ACR, PostgreSQL)

---

## CIDR Range Summary

### Hub VNet: `10.0.0.0/16`
- Firewall Subnet: `10.0.1.0/26` (64 IPs)
- Firewall Management Subnet: `10.0.2.0/26` (64 IPs)
- Bastion Subnet: `10.0.3.0/27` (32 IPs)
- Shared Services Subnet: `10.0.4.0/24` (256 IPs)
- Private Endpoints Subnet (Hub): `10.0.5.0/24` (256 IPs)
- Jumpbox Subnet (Hub): `10.0.6.0/27` (32 IPs)

### Spoke VNet: `10.1.0.0/16`
- AKS Node Pool Subnet: `10.1.0.0/20` (4096 IPs)
- Private Endpoints Subnet: `10.1.16.0/24` (256 IPs)
- Jumpbox/Agent Subnet: `10.1.17.0/27` (32 IPs)

### AKS Internal Ranges
- Service CIDR: `10.100.0.0/16` (Kubernetes services)
- DNS Service IP: `10.100.0.10` (within service CIDR)
- Pod CIDR: `10.244.0.0/16` (Kubernetes pods)

---

## Security Whitelist Summary

### Firewall Network Rules - Allowed Destinations
- **Azure Monitor**: Service Tag `AzureMonitor`, Port 443
- **Azure Storage**: Service Tag `Storage`, Ports 443, 445
- **Azure Container Registry**: Service Tag `AzureContainerRegistry`, Port 443
- **Azure Key Vault**: Service Tag `AzureKeyVault`, Port 443
- **Azure SQL/PostgreSQL**: Service Tag `Sql`, Ports 1433, 5432
- **Azure Cloud**: Service Tag `AzureCloud`, Ports 443, 9000
- **NTP Servers**: Specific IPs, Port 123 (UDP)
- **External DNS**: Google/Cloudflare DNS, Port 53
- **Hub VNet**: `10.0.0.0/16`, All protocols/ports
- **Spoke VNet**: `10.1.0.0/16`, All protocols/ports

### Firewall Application Rules - Allowed FQDNs
- **Azure Management**: `management.azure.com`, `login.microsoftonline.com`, etc.
- **Azure Container Registry**: `*.azurecr.io`, `mcr.microsoft.com`
- **Azure Key Vault**: `*.vault.azure.net`, `*.vaultcore.azure.net`
- **Azure Monitor**: `*.ods.opinsights.azure.com`, `*.oms.opinsights.azure.com`
- **AKS Core**: Service Tag `AzureKubernetesService`
- **Ubuntu Updates**: `security.ubuntu.com`, `azure.archive.ubuntu.com`
- **Kubernetes Packages**: `packages.cloud.google.com`, `apt.kubernetes.io`
- **Microsoft Packages**: `packages.microsoft.com`
- **Docker Hub**: `hub.docker.com`, `registry-1.docker.io`
- **GitHub Container Registry**: `ghcr.io`
- **Quay.io**: `quay.io`

### DNAT Rules - Allowed Sources
- **Cloudflare IP Ranges**: Dynamically fetched from `https://www.cloudflare.com/ips-v4`
- **Destination**: Firewall Public IP, Ports 80, 443
- **Translated To**: Istio Internal LB IP (Stage 2 only)

---

## Deployment Stages

### Stage 1: Initial Deployment
1. Resource Group
2. Log Analytics Workspace
3. Hub VNet and Subnets
4. Spoke VNet and Subnets
5. VNet Peering
6. Private DNS Zones
7. Azure Firewall (with DNAT rules, but empty internal LB IP)
8. Azure Bastion
9. Key Vault (with private endpoint)
10. Storage Account (with private endpoints)
11. Container Registry (with private endpoint)
12. PostgreSQL (with delegated subnet)
13. AKS Cluster (with outbound type `loadBalancer`)
14. Jumpbox VM
15. Agent VM

**Note**: In Stage 1, AKS outbound traffic uses Azure Load Balancer, not firewall.

### Stage 2: Firewall Integration
1. Get Istio Internal LB IP from AKS
2. Update `istio_internal_lb_ip` in terraform.tfvars
3. Set `deployment_stage = "stage2"`
4. Apply Terraform (updates firewall DNAT rules and creates route table)
5. Route Table created and associated with AKS subnet
6. AKS outbound traffic now routes through firewall

**Note**: Stage 2 requires manual step to get Istio LB IP before applying.

---

## Dependencies Graph

```
Resource Group
    ├── Log Analytics Workspace
    │
    ├── Hub VNet
    │   ├── Firewall Subnet
    │   ├── Firewall Management Subnet
    │   ├── Bastion Subnet
    │   ├── Shared Services Subnet
    │   ├── Private Endpoints Subnet (Hub)
    │   └── Jumpbox Subnet (Hub)
    │
    ├── Spoke VNet
    │   ├── AKS Node Pool Subnet
    │   ├── Private Endpoints Subnet
    │   └── Jumpbox/Agent Subnet
    │
    ├── VNet Peering (requires both VNets)
    │
    ├── Private DNS Zones (6 zones)
    │
    ├── Azure Firewall (requires Hub VNet, Log Analytics)
    │   ├── Firewall Policy
    │   ├── DNAT Rules
    │   ├── Network Rules
    │   └── Application Rules
    │
    ├── Azure Bastion (requires Hub VNet, Log Analytics)
    │
    ├── Key Vault (requires Private DNS Zone, Spoke VNet)
    │   └── Private Endpoint
    │
    ├── Storage Account (requires Private DNS Zones, Spoke VNet)
    │   ├── Blob Private Endpoint
    │   └── File Private Endpoint
    │
    ├── Container Registry (requires Private DNS Zone, Spoke VNet)
    │   └── Private Endpoint
    │
    ├── PostgreSQL (requires Private DNS Zone, Spoke VNet)
    │   └── Delegated Subnet
    │
    ├── AKS Cluster (requires VNet Peering, Firewall, ACR, Key Vault, Log Analytics)
    │   ├── User Assigned Identity
    │   ├── System Node Pool
    │   ├── User Node Pool
    │   └── Role Assignments
    │
    ├── Jumpbox VM (requires Spoke VNet)
    │
    ├── Agent VM (requires Spoke VNet)
    │
    └── Route Table (Stage 2 only, requires Firewall, AKS Subnet)
```

---

## Key Takeaways

1. **All resources are private**: No public endpoints except firewall and bastion
2. **Private endpoints**: All PaaS services use private endpoints in `10.1.16.0/24`
3. **DNS resolution**: Private DNS zones resolve FQDNs to private IPs
4. **Firewall is central**: All outbound traffic (Stage 2) and inbound traffic routes through firewall
5. **VNet peering**: Enables direct communication between Hub and Spoke
6. **Private connectivity**: Access to Azure services enforced via private endpoints and firewall policies
7. **Two-stage deployment**: Stage 1 for initial setup, Stage 2 for firewall integration
8. **High availability**: Firewall, Bastion, and AKS use availability zones
9. **Monitoring**: All resources send logs to centralized Log Analytics workspace
10. **Security**: RBAC, private endpoints, firewall rules, and network isolation

---

## Next Steps After Deployment

1. **Get AKS Credentials**:
   ```bash
   az aks get-credentials --resource-group rg-erp-cc-prod --name aks-canadacentral-prod
   ```

2. **Get Istio Internal LB IP** (for Stage 2):
   ```bash
   kubectl get svc istio-ingressgateway -n istio-system -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
   ```

3. **Update terraform.tfvars** with Istio LB IP

4. **Apply Stage 2**:
   ```bash
   terraform apply -var="deployment_stage=stage2"
   ```

5. **Configure Applications**: Deploy applications to AKS

6. **Configure Key Vault**: Add secrets, keys, certificates

7. **Configure Storage**: Create containers, file shares

8. **Configure PostgreSQL**: Create databases, users

---

## End of Document

This completes the detailed infrastructure deployment guide. All resources, connections, CIDR ranges, and security configurations are documented above.

