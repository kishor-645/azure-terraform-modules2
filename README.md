# Azure ERP Infrastructure - Terraform

Production-ready enterprise infrastructure for ERP systems on Azure using hub-spoke network topology with comprehensive security and monitoring.

## 🚀 Quick Start

**New to this project?** Start here:

1. **[Quick Start Guide](docs/QUICK-START.md)** - Deploy in 30 minutes
2. **[Architecture Overview](docs/ARCHITECTURE.md)** - Understand the design
3. **[Troubleshooting](docs/TROUBLESHOOTING.md)** - Common issues and solutions

**Basic deployment:**

```bash
# 1. Bootstrap (create state storage)
cd 0-bootstrap
terraform init
terraform apply -var-file="bootstrap.tfvars"

# 2. Deploy infrastructure
cd ../environments/canada-central/prod
terraform init
terraform apply
```

## 📚 Documentation

| Document | Purpose |
|----------|---------|
| [Quick Start](docs/QUICK-START.md) | 30-minute deployment guide |
| [Deployment Guide](docs/DEPLOYMENT.md) | Complete step-by-step instructions |
| [Architecture](docs/ARCHITECTURE.md) | Network topology and design decisions |
| [Modules Guide](docs/MODULES.md) | How to use Terraform modules |
| [Troubleshooting](docs/TROUBLESHOOTING.md) | Common issues and solutions |
| [Bootstrap Guide](0-bootstrap/README.md) | Bootstrap infrastructure setup |
| [Pipeline Guide](pipelines/README.md) | CI/CD with Azure DevOps |

## 🏗️ What This Deploys

### Infrastructure Overview

**Network Architecture:**
- Hub-Spoke topology with VNet peering
- Hub VNet (10.0.0.0/16) - Centralized security services
- Spoke VNet (10.1.0.0/16) - Application workloads
- Azure Firewall Premium for centralized egress control
- Private DNS zones for all Azure services

**Compute Resources:**
- Private AKS cluster with Istio service mesh
- System node pool (auto-scaling 1-5 nodes)
- User node pool (auto-scaling 1-5 nodes)
- Jumpbox VM for management
- Agent VM for CI/CD

**Data & Storage:**
- PostgreSQL Flexible Server (private endpoint)
- Storage Account with blob and file shares
- Azure Container Registry (Premium)
- Azure Key Vault (Premium)

**Security:**
- Azure Bastion for secure VM access
- Network Security Groups on all subnets
- User-defined routes for traffic control
- All PaaS services use private endpoints

**Monitoring:**
- Log Analytics Workspace
- Application Insights
- Diagnostic settings on all resources

### Key Features

- ✅ **Zero Trust Network** - All resources private, no public endpoints
- ✅ **Istio Service Mesh** - Built-in AKS add-on for microservices
- ✅ **Two-Stage Deployment** - Avoids circular dependencies
- ✅ **Centralized Security** - All traffic inspected by Azure Firewall
- ✅ **Comprehensive Logging** - All resources send logs to Log Analytics
- ✅ **High Availability** - Multi-zone deployment for critical services
- ✅ **Auto-Scaling** - AKS node pools scale based on demand

### Resources Created

Approximately **45-50 Azure resources** including:
- 2 VNets with 8 subnets
- 1 AKS cluster with 2 node pools
- 1 Azure Firewall Premium
- 1 Azure Bastion
- 1 PostgreSQL Flexible Server
- 1 Storage Account
- 1 Container Registry
- 1 Key Vault
- 2 Virtual Machines
- 6 Private DNS Zones
- Multiple NSGs, Route Tables, and Private Endpoints

## 📁 Repository Structure

```
.
├── 0-bootstrap/              # Bootstrap infrastructure (state storage, Key Vault)
├── environments/
│   └── canada-central/
│       └── prod/             # Production environment configuration
├── modules/                  # Reusable Terraform modules
│   ├── networking/           # VNets, peering, DNS zones
│   ├── security/             # Firewall, Bastion, NSGs, route tables
│   ├── compute/              # AKS cluster, VMs
│   ├── storage/              # Storage Account, ACR, Key Vault
│   ├── data/                 # PostgreSQL database
│   └── monitoring/           # Log Analytics, Application Insights
├── scripts/                  # Helper scripts for deployment and management
├── pipelines/                # Azure DevOps CI/CD pipelines
└── docs/                     # Comprehensive documentation
```

## 🛠️ Prerequisites

**Required Tools:**
- Azure CLI >= 2.50.0
- Terraform >= 1.10.3
- kubectl >= 1.28.0

**Azure Requirements:**
- Active Azure subscription
- Owner or Contributor role
- SSH key pair for VM access

**Verify installations:**
```bash
az --version
terraform --version
kubectl version --client
```

## 🔄 Two-Stage Deployment

This infrastructure uses a two-stage deployment to avoid circular dependencies:

**Stage 1:** Deploy all infrastructure with AKS using Azure Load Balancer for egress

**Stage 2:** Switch AKS to use Azure Firewall for egress (user-defined routing)

## 🔧 Helper Scripts

| Script | Purpose |
|--------|---------|
| `scripts/check-existing-resources.sh` | Check for resource conflicts before deployment |
| `scripts/setup-backend.sh` | Configure Terraform backend |
| `scripts/validate-cidr.py` | Validate CIDR ranges |
| `scripts/get-aks-credentials.sh` | Get AKS cluster credentials |
| `scripts/get-istio-lb-ip.sh` | Get Istio ingress gateway IP |
| `scripts/get-secrets-from-keyvault.sh` | Retrieve secrets from Key Vault |
| `scripts/validate-deployment.sh` | Validate deployment success |

## 🤝 Contributing

1. Create a feature branch from `main`
2. Make your changes
3. Run validation: `terraform fmt -recursive && terraform validate`
4. Create a Pull Request
5. PR validation pipeline runs automatically

## 📝 Version Information

- **Version**: 2.1.0
- **Last Updated**: November 2025
- **Terraform**: >= 1.10.3
- **Azure Provider**: ~> 4.51.0
