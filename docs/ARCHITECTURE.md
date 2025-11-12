# Architecture Documentation

Enterprise-grade hub-spoke network topology for ERP infrastructure on Azure.

## Overview

This infrastructure implements a secure, scalable hub-spoke network architecture with centralized security and monitoring.

### Design Principles

- **Security First**: All resources use private endpoints, no public access
- **Centralized Control**: All traffic flows through Azure Firewall
- **High Availability**: Multi-zone deployment for critical services
- **Observability**: Comprehensive logging and monitoring
- **Scalability**: Auto-scaling for AKS workloads

---

## Network Architecture

### Hub-Spoke Topology

```
┌─────────────────────────────────────────────────────────┐
│                    Hub VNet                             │
│                  (10.0.0.0/16)                          │
│                                                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │
│  │   Firewall   │  │   Bastion    │  │   Private    │ │
│  │   Subnet     │  │   Subnet     │  │  Endpoints   │ │
│  │ 10.0.0.0/24  │  │ 10.0.1.0/26  │  │ 10.0.2.0/24  │ │
│  └──────────────┘  └──────────────┘  └──────────────┘ │
│                                                         │
└────────────────────────┬────────────────────────────────┘
                         │ VNet Peering
                         │
┌────────────────────────┴────────────────────────────────┐
│                   Spoke VNet                            │
│                  (10.1.0.0/16)                          │
│                                                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │
│  │     AKS      │  │   Private    │  │   Compute    │ │
│  │   Subnet     │  │  Endpoints   │  │   Subnet     │ │
│  │ 10.1.16.0/22 │  │ 10.1.29.0/24 │  │ 10.1.30.0/24 │ │
│  └──────────────┘  └──────────────┘  └──────────────┘ │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### Hub VNet (10.0.0.0/16)

**Purpose**: Centralized security and management services

| Subnet | CIDR | Purpose |
|--------|------|---------|
| AzureFirewallSubnet | 10.0.0.0/24 | Azure Firewall Premium |
| AzureBastionSubnet | 10.0.1.0/26 | Azure Bastion for VM access |
| PrivateEndpointSubnet | 10.0.2.0/24 | Private endpoints for hub services |
| ManagementSubnet | 10.0.3.0/24 | Management and monitoring tools |

### Spoke VNet (10.1.0.0/16)

**Purpose**: Application workloads and data services

| Subnet | CIDR | Purpose |
|--------|------|---------|
| AKSSubnet | 10.1.16.0/22 | AKS nodes (system + user pools) |
| PrivateEndpointSubnet | 10.1.29.0/24 | Private endpoints for spoke services |
| ComputeSubnet | 10.1.30.0/24 | Jumpbox and Agent VMs |

### VNet Peering

- **Hub → Spoke**: Allow forwarded traffic, allow gateway transit
- **Spoke → Hub**: Use remote gateways, allow forwarded traffic
- **Traffic flow**: All spoke traffic routes through hub firewall

---

## Security Architecture

### Network Security

**Azure Firewall Premium**
- IDPS (Intrusion Detection and Prevention)
- TLS inspection
- Application rules for FQDN filtering
- Network rules for IP-based filtering
- Centralized logging to Log Analytics

**Network Security Groups (NSGs)**
- Applied to all subnets
- Deny-by-default approach
- Explicit allow rules for required traffic
- Logged to Log Analytics

**Route Tables**
- User-defined routes (UDR) on AKS subnet
- Default route (0.0.0.0/0) to Firewall
- Ensures all egress traffic is inspected

### Identity and Access

**Azure AD Integration**
- AKS uses Azure AD for authentication
- Azure RBAC for Kubernetes authorization
- Managed identities for Azure resource access
- No service principal credentials stored

**Private Endpoints**
- All PaaS services use private endpoints
- No public access enabled
- DNS resolution via Private DNS Zones

### Data Protection

**Encryption**
- All data encrypted at rest (Azure Storage Encryption)
- TLS 1.2+ for data in transit
- Key Vault for secrets management
- Customer-managed keys option available

---

## Compute Architecture

### AKS Cluster

**Configuration**
- Private cluster (no public API endpoint)
- Istio service mesh (built-in)
- Azure CNI networking
- Azure AD integration
- Azure RBAC enabled

**Node Pools**

| Pool | Purpose | VM Size | Count | Auto-scale |
|------|---------|---------|-------|------------|
| System | Kubernetes system pods | Standard_D2s_v3 | 2-3 | Yes |
| User | Application workloads | Standard_D4s_v3 | 2-5 | Yes |

**Istio Service Mesh**
- Traffic management
- Security (mTLS)
- Observability
- Internal load balancer for ingress

### Virtual Machines

**Jumpbox VM**
- Purpose: Secure access to private resources
- Access: Via Azure Bastion only
- OS: Ubuntu 22.04 LTS
- Tools: kubectl, az CLI, psql

**Agent VM**
- Purpose: Azure DevOps self-hosted agent
- Access: Via Azure Bastion only
- OS: Ubuntu 22.04 LTS
- Tools: Docker, Terraform, kubectl

---

## Data Architecture

### PostgreSQL Flexible Server

**Configuration**
- Private endpoint (no public access)
- Zone-redundant high availability
- Automated backups (7-day retention)
- Point-in-time restore
- Private DNS zone integration

**Security**
- Azure AD authentication
- SSL/TLS enforced
- Firewall rules (deny all public)
- Audit logging enabled

---

## Storage Architecture

### Storage Account

**Services**
- Blob storage (Terraform state, backups)
- File storage (shared file system)
- Private endpoints for blob and file

**Security**
- No public access
- Geo-redundant storage (GRS)
- Soft delete enabled
- Versioning enabled

### Container Registry

**Configuration**
- Premium SKU
- Private endpoint
- Geo-replication (optional)
- Content trust enabled

**Security**
- Azure AD authentication
- RBAC for access control
- Vulnerability scanning
- Image quarantine

### Key Vault

**Purpose**
- Secrets management
- Certificate storage
- Encryption keys

**Security**
- Private endpoint
- Soft delete enabled
- Purge protection enabled
- RBAC access control

---

## Monitoring Architecture

### Log Analytics Workspace

**Purpose**: Centralized logging and analytics

**Data Sources**
- AKS cluster logs
- Azure Firewall logs
- NSG flow logs
- Application logs
- Resource diagnostics

### Application Insights

**Purpose**: Application performance monitoring

**Features**
- Distributed tracing
- Performance metrics
- Dependency mapping
- Custom metrics

### Alerting

**Action Groups**
- Email notifications
- SMS alerts (optional)
- Webhook integrations

**Alert Rules**
- AKS node health
- Firewall threat detection
- Database performance
- Storage capacity

---

## Traffic Flow

### Inbound Traffic

```
Internet → Azure Firewall → Istio Ingress Gateway → AKS Pods
```

### Outbound Traffic

```
AKS Pods → Route Table → Azure Firewall → Internet
```

### Internal Traffic

```
AKS Pods → Private Endpoint → Azure Service (Storage, DB, etc.)
```

---

## High Availability

### Zone Redundancy

- **AKS**: Nodes distributed across availability zones
- **PostgreSQL**: Zone-redundant HA enabled
- **Storage**: Geo-redundant storage (GRS)

### Backup and Recovery

- **PostgreSQL**: Automated backups, 7-day retention
- **Storage**: Soft delete, versioning
- **Terraform State**: Backed up to separate storage account

---

## Scalability

### Auto-scaling

- **AKS Node Pools**: Cluster autoscaler enabled
- **AKS Pods**: Horizontal Pod Autoscaler (HPA)
- **PostgreSQL**: Vertical scaling (manual)

### Performance

- **AKS**: Premium SSD for OS disks
- **PostgreSQL**: Burstable to General Purpose tiers
- **Storage**: Premium tier for Container Registry

---

**Version**: 2.1.0
**Last Updated**: November 2025
