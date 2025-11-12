# Infrastructure Overview - What Will Be Created

**Quick Reference**: This document shows all Azure resources that will be created when you run `terraform apply`.

---

## 📊 Summary

| Category | Resources | Purpose |
|----------|-----------|---------|
| **Resource Groups** | 2 | Organization and management |
| **Networking** | 2 VNets, 11 Subnets, 2 Peerings | Hub-spoke network topology |
| **Security** | 1 Firewall, 5 NSGs, 1 Bastion | Network security and access control |
| **Compute** | 1 AKS Cluster (2 node pools) | Container orchestration |
| **Database** | 1 PostgreSQL Flexible Server | Application database |
| **Storage** | 1 Storage Account, 1 Container Registry | Data and container images |
| **Monitoring** | 1 Log Analytics Workspace | Centralized logging |
| **Identity** | 3 Managed Identities | Secure authentication |

**Total Resources**: ~35-40 Azure resources

---

## 🏗️ Resource Groups

### 1. Main Resource Group
- **Name**: `rg-erp-canadacentral-prod`
- **Location**: Canada Central
- **Purpose**: Contains all infrastructure resources

### 2. AKS Node Resource Group
- **Name**: `rg-aks-erp-cc-prod-nodes`
- **Location**: Canada Central
- **Purpose**: Auto-managed by AKS for node VMs, disks, NICs

---

## 🌐 Networking Infrastructure

### Hub VNet (Centralized Security)
- **Name**: `vnet-hub-canadacentral-prod`
- **Address Space**: `10.0.0.0/16`
- **Purpose**: Centralized security services and shared resources

**Subnets**:
1. **AzureFirewallSubnet** - `10.0.0.0/26` - Azure Firewall
2. **AzureBastionSubnet** - `10.0.0.64/26` - Azure Bastion
3. **AzureFirewallManagementSubnet** - `10.0.0.128/26` - Firewall management
4. **SharedServicesSubnet** - `10.0.1.0/24` - Shared services
5. **PrivateEndpointsSubnet** - `10.0.2.0/24` - Private endpoints (ACR, Storage, etc.)
6. **JumpboxSubnet** - `10.0.4.0/24` - Management VMs

### Spoke VNet (Application Workloads)
- **Name**: `vnet-spoke-canadacentral-prod`
- **Address Space**: `10.1.0.0/16`
- **Purpose**: Application workloads (AKS cluster)

**Subnets**:
1. **AKSNodesSubnet** - `10.1.0.0/22` - AKS node pools (system + user)
2. **PrivateEndpointsSubnet** - `10.1.4.0/24` - Private endpoints
3. **JumpboxSubnet** - `10.1.5.0/24` - Management VMs

### VNet Peering
- **Hub → Spoke**: Bidirectional peering with gateway transit
- **Spoke → Hub**: Uses hub's gateway for external connectivity
- **Purpose**: Secure communication between hub and spoke

---

## 🔒 Security Resources

### 1. Azure Firewall Premium
- **Name**: `afw-hub-canadacentral-prod`
- **SKU**: Premium (with IDPS)
- **Public IP**: `pip-afw-canadacentral-prod`
- **Purpose**: Centralized egress filtering and threat protection
- **Features**:
  - IDPS (Intrusion Detection/Prevention)
  - TLS inspection
  - URL filtering
  - Application/Network rules

### 2. Azure Bastion
- **Name**: `bastion-hub-canadacentral-prod`
- **SKU**: Standard
- **Public IP**: `pip-bastion-canadacentral-prod`
- **Purpose**: Secure RDP/SSH access to VMs without public IPs

### 3. Network Security Groups (NSGs)

| NSG Name | Applied To | Purpose |
|----------|------------|---------|
| `nsg-aks-canadacentral-prod` | AKS Nodes Subnet | Control AKS traffic |
| `nsg-pe-canadacentral-prod` | Private Endpoints Subnet (Spoke) | Secure private endpoints |
| `nsg-jumpbox-canadacentral-prod` | Jumpbox Subnet (Spoke) | Management VM access |
| `nsg-hub-pe-canadacentral-prod` | Private Endpoints Subnet (Hub) | Hub private endpoints |
| `nsg-hub-jumpbox-canadacentral-prod` | Jumpbox Subnet (Hub) | Hub management access |

**Security Rules**: Each NSG includes inbound/outbound rules for specific traffic patterns

---

## 💻 Compute Resources

### AKS Cluster
- **Name**: `aks-erp-cc-prod`
- **Kubernetes Version**: 1.30.7 (configurable)
- **Network Plugin**: Azure CNI
- **Network Policy**: Calico
- **Service Mesh**: Istio
- **Outbound Type**: Azure Firewall (Stage 2) or Load Balancer (Stage 1)

**System Node Pool**:
- **Name**: `system`
- **VM Size**: `Standard_D4s_v5` (4 vCPU, 16 GB RAM)
- **Node Count**: 2-3 nodes (autoscaling)
- **Purpose**: Kubernetes system pods

**User Node Pool**:
- **Name**: `user`
- **VM Size**: `Standard_D8s_v5` (8 vCPU, 32 GB RAM)
- **Node Count**: 2-5 nodes (autoscaling)
- **Purpose**: Application workloads

**Features**:
- Private cluster (no public API endpoint)
- Azure AD integration
- Managed identity
- Container Insights monitoring
- Azure Key Vault integration

---

## 🗄️ Database Resources

### PostgreSQL Flexible Server
- **Name**: `psql-erp-cc-prod`
- **Version**: PostgreSQL 16
- **SKU**: `Standard_D4s_v3` (4 vCPU, 16 GB RAM)
- **Storage**: 128 GB (auto-grow enabled)
- **High Availability**: Zone-redundant
- **Backup Retention**: 7 days
- **Purpose**: Application database
- **Connectivity**: Private endpoint (no public access)
- **Features**:
  - Automatic backups
  - Point-in-time restore
  - SSL/TLS encryption
  - Azure AD authentication

---

## 📦 Storage & Registry

### 1. Container Registry (ACR)
- **Name**: `acrerp<unique>ccprod`
- **SKU**: Premium
- **Purpose**: Store container images for AKS
- **Features**:
  - Private endpoint connectivity
  - Geo-replication capable
  - Content trust
  - Vulnerability scanning

### 2. Storage Account
- **Name**: `sterp<unique>ccprod`
- **SKU**: Standard_LRS
- **Purpose**: Application data storage
- **Features**:
  - Private endpoint connectivity
  - Blob storage
  - Encryption at rest
  - Soft delete enabled

---

## 📊 Monitoring & Logging

### Log Analytics Workspace
- **Name**: `log-erp-canadacentral-prod`
- **SKU**: PerGB2018
- **Retention**: 30 days
- **Purpose**: Centralized logging for all resources
- **Connected Resources**:
  - AKS cluster (Container Insights)
  - Azure Firewall logs
  - NSG flow logs
  - PostgreSQL diagnostics
  - All resource diagnostic settings

---

## 🔑 Identity & Access

### Managed Identities

1. **AKS Cluster Identity**
   - **Name**: `id-aks-canadacentral-prod`
   - **Purpose**: AKS cluster operations
   - **Permissions**: Network Contributor on VNet

2. **AKS Kubelet Identity**
   - **Name**: Auto-generated
   - **Purpose**: Pull images from ACR
   - **Permissions**: AcrPull on Container Registry

3. **PostgreSQL Identity**
   - **Name**: Auto-generated
   - **Purpose**: Azure AD authentication for database

---

## 🔗 Network Connectivity Flow

### Internet → Application (Inbound)
```
Internet
  ↓
Azure Firewall (DNAT rules)
  ↓
AKS Ingress Controller (Istio)
  ↓
Application Pods
  ↓
PostgreSQL Database
```

### Application → Internet (Outbound)
```
Application Pods
  ↓
AKS Nodes
  ↓
Azure Firewall (egress filtering)
  ↓
Internet
```

### Management Access
```
Administrator
  ↓
Azure Bastion (RDP/SSH)
  ↓
Jumpbox VM (if deployed)
  ↓
Private Resources
```

### Private Connectivity
```
AKS Pods
  ↓
Private Endpoint (10.0.2.x or 10.1.4.x)
  ↓
Azure Services (ACR, Storage, PostgreSQL, Key Vault)
```

---

## 🛡️ Security Features

### Network Security
- ✅ **Zero Public Endpoints**: All resources private except Firewall & Bastion
- ✅ **Hub-Spoke Topology**: Centralized security controls
- ✅ **NSG Protection**: All subnets protected with security rules
- ✅ **Azure Firewall**: IDPS, TLS inspection, URL filtering
- ✅ **Private Endpoints**: Secure connectivity to Azure PaaS services

### Identity & Access
- ✅ **Managed Identities**: No passwords or keys in code
- ✅ **Azure AD Integration**: Centralized authentication
- ✅ **RBAC**: Role-based access control
- ✅ **Key Vault**: Secrets management

### Data Protection
- ✅ **Encryption at Rest**: All storage encrypted
- ✅ **Encryption in Transit**: TLS/SSL for all connections
- ✅ **Backup & DR**: Automated backups for database
- ✅ **Zone Redundancy**: High availability for critical services

### Monitoring & Compliance
- ✅ **Centralized Logging**: All logs in Log Analytics
- ✅ **Diagnostic Settings**: Enabled on all resources
- ✅ **Container Insights**: AKS monitoring
- ✅ **Network Flow Logs**: NSG traffic analysis

---

## 📋 Resource Naming Convention

| Resource Type | Pattern | Example |
|---------------|---------|---------|
| Resource Group | `rg-{app}-{region}-{env}` | `rg-erp-canadacentral-prod` |
| VNet | `vnet-{type}-{region}-{env}` | `vnet-hub-canadacentral-prod` |
| Subnet | `snet-{purpose}-{region}-{env}` | `snet-aks-canadacentral-prod` |
| NSG | `nsg-{purpose}-{region}-{env}` | `nsg-aks-canadacentral-prod` |
| AKS | `aks-{app}-{region-short}-{env}` | `aks-erp-cc-prod` |
| PostgreSQL | `psql-{app}-{region-short}-{env}` | `psql-erp-cc-prod` |
| ACR | `acr{app}{unique}{region-short}{env}` | `acrerp123ccprod` |
| Storage | `st{app}{unique}{region-short}{env}` | `sterp123ccprod` |
| Log Analytics | `log-{app}-{region}-{env}` | `log-erp-canadacentral-prod` |
| Firewall | `afw-{type}-{region}-{env}` | `afw-hub-canadacentral-prod` |
| Bastion | `bastion-{type}-{region}-{env}` | `bastion-hub-canadacentral-prod` |

---

## 🚀 Deployment Stages

### Stage 1: Initial Deployment (Load Balancer Egress)
- All resources created
- AKS uses Azure Load Balancer for outbound traffic
- **Purpose**: Establish base infrastructure quickly

### Stage 2: Production Ready (Firewall Egress)
- Switch AKS outbound to Azure Firewall
- Full egress filtering and IDPS protection
- **Purpose**: Production-grade security

---

## ✅ What Happens When You Run `terraform apply`

1. **Resource Groups Created** (2 groups)
2. **Networking Deployed** (Hub VNet, Spoke VNet, Subnets, Peerings)
3. **Security Configured** (Firewall, Bastion, NSGs)
4. **Monitoring Setup** (Log Analytics Workspace)
5. **Storage Provisioned** (Container Registry, Storage Account)
6. **Database Created** (PostgreSQL Flexible Server)
7. **AKS Cluster Deployed** (System + User node pools)
8. **Private Endpoints Created** (ACR, Storage, PostgreSQL)
9. **Diagnostic Settings Enabled** (All resources → Log Analytics)
10. **Managed Identities Configured** (AKS, PostgreSQL)

**Estimated Deployment Time**: 30-45 minutes