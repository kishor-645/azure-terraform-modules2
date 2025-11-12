# Canada Central - Production Environment

Production infrastructure for ERP system in Canada Central region.

## 📋 Overview

- **Environment**: Production
- **Region**: Canada Central (canadacentral)
- **Resource Group**: `rg-erp-cc-prod`
- **Resources**: ~45-50 Azure resources
- **Cost**: $3,445 - $5,945 USD/month

## 📚 Documentation

- **[Environment Resources](../../../docs/ENVIRONMENT-RESOURCES.md)** - Complete list of resources created
- **[Deployment Steps](../../../docs/DEPLOYMENT-STEPS.md)** - Step-by-step deployment guide
- **[Infrastructure Deployment Guide](INFRASTRUCTURE-DEPLOYMENT-GUIDE.md)** - Detailed resource creation order
- **[Modules Guide](../../../docs/MODULES-GUIDE.md)** - Module usage reference

## 🚀 Quick Deployment

### Prerequisites

1. Bootstrap completed (state storage and Key Vault created)
2. Secrets stored in Key Vault
3. SSH key generated
4. Azure CLI authenticated

### Stage 1: Initial Deployment

```bash
# 1. Configure backend (use values from bootstrap outputs)
# Edit backend.tf with your storage account name

# 2. Create terraform.tfvars
cp terraform.tfvars.example terraform.tfvars
# Edit with your values

# 3. Retrieve secrets from Key Vault
../../../scripts/get-secrets-from-keyvault.sh <keyvault-name> terraform.tfvars

# 4. Initialize and deploy
terraform init
terraform plan -out=tfplan-stage1
terraform apply tfplan-stage1
```

**⏱️ Deployment time**: 20-30 minutes

### Stage 2: Firewall Routing

```bash
# 1. Get Istio Load Balancer IP
../../../scripts/get-istio-lb-ip.sh

# 2. Update terraform.tfvars
# Set: deployment_stage = "stage2"
# Set: istio_ingress_ip = "x.x.x.x"

# 3. Apply Stage 2
terraform plan -out=tfplan-stage2
terraform apply tfplan-stage2
```

**⏱️ Deployment time**: 5-10 minutes

## 📊 Resources Created

### Networking
- Hub VNet (10.0.0.0/16) with 4 subnets
- Spoke VNet (10.1.0.0/16) with 3 subnets
- VNet peering (hub ↔ spoke)
- 5 Private DNS zones
- Azure Firewall Premium
- Azure Bastion

### Compute
- AKS cluster (private, with Istio)
- System node pool (2-3 nodes)
- User node pool (2-5 nodes)
- Jumpbox VM
- Agent VM

### Storage & Data
- Storage Account (GRS)
- Container Registry (Premium)
- Key Vault
- File Share
- PostgreSQL Flexible Server

### Monitoring
- Log Analytics Workspace
- Application Insights
- Action Group

See **[Environment Resources](../../../docs/ENVIRONMENT-RESOURCES.md)** for complete details.

## 💰 Cost Breakdown

| Service | Monthly Cost (USD) |
|---------|-------------------|
| Azure Firewall Premium | $1,350 |
| AKS Cluster (nodes) | $1,000 - $3,500 |
| Azure Bastion | $295 |
| PostgreSQL Flexible Server | $200 - $400 |
| Storage Services | $50 - $100 |
| Monitoring | $50 - $100 |
| **Total** | **$3,445 - $5,945** |

## 🔧 Configuration

### Required Variables

Edit `terraform.tfvars`:

```hcl
# Basic
location         = "canadacentral"  # Azure region (e.g., eastus, westus2, uksouth)
subscription_id  = "your-subscription-id"

# Deployment
deployment_stage = "stage1"  # Change to "stage2" after Stage 1

# SSH Key
ssh_public_key   = "ssh-rsa AAAAB3..."

# AKS
aks_kubernetes_version = "1.28"
aks_system_node_count  = 2
aks_user_node_count    = 2

# Monitoring
alert_email_receivers = ["ops@example.com"]

# Tags
tags = {
  Environment = "prod"
  ManagedBy   = "terraform"
  Project     = "ERP"
}
```

### Secrets (from Key Vault)

These are automatically populated by `get-secrets-from-keyvault.sh`:
- `postgresql_admin_login`
- `postgresql_admin_password`
- `jumpbox_admin_username`
- `jumpbox_admin_password`
- `agent_vm_admin_username`
- `agent_vm_admin_password`

## 🔍 Verification

```bash
# Verify AKS access
../../../scripts/get-aks-credentials.sh aks-erp-cc-prod rg-erp-cc-prod
kubectl get nodes

# Check Istio
kubectl get pods -n istio-system

# Run validation
../../../scripts/validate-deployment.sh
```

## 🆘 Troubleshooting

See **[Troubleshooting Guide](../../../docs/TROUBLESHOOTING.md)** for common issues.

## 📝 Notes

- **Two-stage deployment** is required due to AKS outbound type change
- **Stage 1** uses loadBalancer for AKS egress
- **Stage 2** switches to userDefinedRouting through Azure Firewall
- All resources are in a **single resource group** for simplified management

---

**Version**: 2.1.0
**Last Updated**: November 2025
