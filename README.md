# ERP Infrastructure - Azure Terraform

Production-ready infrastructure for ERP system on Azure with simplified single-region architecture.

## 📚 Documentation

### Getting Started
- **[Deployment Steps](docs/DEPLOYMENT-STEPS.md)** - Complete step-by-step deployment guide from bootstrap to production
- **[Environment Resources](docs/ENVIRONMENT-RESOURCES.md)** - Detailed list of all resources that will be created

### Reference Guides
- **[Modules Guide](docs/MODULES-GUIDE.md)** - How to use each Terraform module with examples
- **[Architecture](docs/ARCHITECTURE.md)** - Architecture overview and design decisions
- **[Cost Estimation](docs/COST-ESTIMATION.md)** - Detailed cost breakdown

### Operations
- **[Azure DevOps Pipelines](DEPLOYMENT-GUIDE.md)** - CI/CD pipeline setup and usage
- **[Troubleshooting](docs/TROUBLESHOOTING.md)** - Common issues and solutions

## 🚀 Quick Start

### Option 1: Manual Deployment (Recommended for first-time)

```bash
# 1. Bootstrap (create state storage and Key Vault)
cd 0-bootstrap
terraform init
terraform apply -var-file="bootstrap.tfvars"

# 2. Deploy infrastructure
cd ../environments/canada-central/prod
terraform init
terraform apply  # Stage 1

# 3. Get Istio LB IP and deploy Stage 2
./scripts/get-istio-lb-ip.sh
# Update terraform.tfvars with Istio IP and set deployment_stage = "stage2"
terraform apply  # Stage 2
```

See **[Deployment Steps](docs/DEPLOYMENT-STEPS.md)** for detailed instructions.

### Option 2: Azure DevOps Pipelines

See **[DEPLOYMENT-GUIDE.md](DEPLOYMENT-GUIDE.md)** for CI/CD pipeline setup.

## 🏗️ Infrastructure Overview

### Architecture
- **Region**: Canada Central only (simplified from multi-region)
- **Network**: Hub-Spoke topology with Azure Firewall Premium
- **Compute**: Private AKS cluster with Istio service mesh (inbuilt)
- **Database**: PostgreSQL Flexible Server with private endpoint
- **Storage**: Storage Account, Container Registry, Key Vault (all with private endpoints)
- **Security**: Azure Bastion, NSGs, Route Tables, Private DNS Zones
- **Monitoring**: Log Analytics, Application Insights, Action Groups

### Key Features
✅ **Single Resource Group** - All resources in one RG per environment
✅ **Private Everything** - No public endpoints (except Firewall & Bastion)
✅ **Shared AKS Subnet** - System and user node pools use same subnet
✅ **Istio Inbuilt** - No manual installation, enabled as AKS feature
✅ **Two-Stage Deployment** - loadBalancer → userDefinedRouting
✅ **Centralized Security** - All traffic through Azure Firewall
✅ **Comprehensive Monitoring** - All resources log to Log Analytics

### Resources Created
- **~45-50 Azure resources** per environment
- See **[Environment Resources](docs/ENVIRONMENT-RESOURCES.md)** for complete list

### Cost Estimate
**$3,445 - $5,945 USD/month** (varies by node count and usage)
- Azure Firewall Premium: ~$1,350/month
- AKS Cluster: ~$1,000-$3,500/month
- Azure Bastion: ~$295/month
- Other services: ~$800/month

See **[Cost Estimation](docs/COST-ESTIMATION.md)** for detailed breakdown.

---

## 📁 Repository Structure

```
.
├── 0-bootstrap/                    # Bootstrap infrastructure (state storage, Key Vault)
├── environments/
│   └── canada-central/
│       ├── prod/                   # Production environment
│       └── dev/                    # Development environment
├── modules/                        # Reusable Terraform modules
│   ├── networking/                 # VNets, peering, DNS zones
│   ├── security/                   # Firewall, Bastion, NSGs, route tables
│   ├── compute/                    # AKS, VMs
│   ├── storage/                    # Storage Account, ACR, Key Vault
│   ├── data/                       # PostgreSQL
│   └── monitoring/                 # Log Analytics, App Insights
├── scripts/                        # Helper scripts
├── pipelines/                      # Azure DevOps pipelines
└── docs/                          # Documentation
```

---

## 🛠️ Prerequisites

- **Azure CLI** >= 2.50.0
- **Terraform** >= 1.10.3
- **kubectl** >= 1.28.0
- **Azure Subscription** with Owner/Contributor role
- **SSH Key Pair** for VM access

---

## 📖 Detailed Guides

### For First-Time Deployment
1. Read **[Deployment Steps](docs/DEPLOYMENT-STEPS.md)** - Complete walkthrough
2. Review **[Environment Resources](docs/ENVIRONMENT-RESOURCES.md)** - Know what will be created
3. Check **[Cost Estimation](docs/COST-ESTIMATION.md)** - Understand costs

### For Module Development
1. Read **[Modules Guide](docs/MODULES-GUIDE.md)** - Learn how to use modules
2. Review **[Architecture](docs/ARCHITECTURE.md)** - Understand design decisions

### For CI/CD Setup
1. Read **[DEPLOYMENT-GUIDE.md](DEPLOYMENT-GUIDE.md)** - Azure DevOps pipeline setup

### For Troubleshooting
1. Check **[Troubleshooting](docs/TROUBLESHOOTING.md)** - Common issues and solutions

---

## 🎯 Environments

| Environment | Path | Purpose |
|-------------|------|---------|
| **Production** | `environments/canada-central/prod/` | Production workloads |
| **Development** | `environments/canada-central/dev/` | Development and testing |

---

## 🔄 Two-Stage Deployment

### Stage 1: Initial Deployment (loadBalancer)
- Deploy all infrastructure
- AKS uses Azure Load Balancer for egress
- Istio is enabled and gets a Load Balancer IP

### Stage 2: Firewall Routing (userDefinedRouting)
- Switch AKS to use Azure Firewall for egress
- Apply route table to AKS subnet
- All traffic flows through centralized firewall

See **[Deployment Steps](docs/DEPLOYMENT-STEPS.md)** for details.

---

## 📊 What Gets Created

When you run `terraform apply` in `environments/canada-central/prod/`:

### Networking (15-18 resources)
- Hub VNet with 4 subnets
- Spoke VNet with 3 subnets
- VNet peering (hub ↔ spoke)
- 5 Private DNS zones with VNet links
- 3 NSGs, 1 Route Table

### Security (4 resources)
- Azure Firewall Premium with policy
- Azure Bastion
- 2 Public IPs

### Compute (8-12 resources)
- AKS cluster with Istio
- System node pool (2-3 nodes)
- User node pool (2-5 nodes)
- 2 VMs (jumpbox, agent)

### Storage (5-7 resources)
- Storage Account with private endpoints
- Container Registry with private endpoint
- Key Vault with private endpoint
- File Share

### Data (2 resources)
- PostgreSQL Flexible Server
- Private endpoint

### Monitoring (3 resources)
- Log Analytics Workspace
- Application Insights
- Action Group

**Total: ~45-50 resources**

See **[Environment Resources](docs/ENVIRONMENT-RESOURCES.md)** for complete details.

---

## 🚦 Simplifications Made

This infrastructure was simplified from a complex multi-region setup:

- ✅ **Single Region** - Canada Central only (was 4 regions)
- ✅ **Single Resource Group** - One RG per environment (was 4)
- ✅ **Shared AKS Subnet** - One subnet for all node pools (was 2)
- ✅ **Istio Inbuilt** - AKS feature (was manual installation)
- ✅ **Removed Scripts** - Deployment via Makefile/Terraform (was shell scripts)
- ✅ **Simplified Bootstrap** - 6 resources (was 23)
- ✅ **Cost Reduction** - 71% reduction in bootstrap costs

See **[SIMPLIFICATION-SUMMARY.md](SIMPLIFICATION-SUMMARY.md)** for details.

---

## 🤝 Contributing

1. Create feature branch
2. Make changes
3. Run validation: `terraform fmt`, `terraform validate`
4. Create Pull Request
5. PR validation pipeline runs automatically

---

## 📝 Version

**Version**: 2.1.0
**Last Updated**: November 2025
**Terraform**: >= 1.10.3
**Azure Provider**: ~> 4.51.0
