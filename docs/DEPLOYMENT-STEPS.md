# Complete Deployment Guide

Step-by-step guide to deploy the ERP infrastructure from scratch to production.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Phase 1: Bootstrap Setup](#phase-1-bootstrap-setup)
3. [Phase 2: Environment Deployment](#phase-2-environment-deployment)
4. [Phase 3: Post-Deployment Configuration](#phase-3-post-deployment-configuration)
5. [Phase 4: Verification](#phase-4-verification)

---

## Prerequisites

### Required Tools

Install these tools before starting:

```bash
# Azure CLI (version >= 2.50.0)
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Terraform (version >= 1.10.3)
wget https://releases.hashicorp.com/terraform/1.10.3/terraform_1.10.3_linux_amd64.zip
unzip terraform_1.10.3_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# kubectl (version >= 1.28.0)
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# Verify installations
az --version
terraform --version
kubectl version --client
```

### Azure Requirements

- Active Azure subscription
- Owner or Contributor role on subscription
- Azure CLI authenticated

```bash
# Login to Azure
az login

# Set subscription
az account set --subscription "YOUR_SUBSCRIPTION_ID"

# Verify
az account show
```

### Generate SSH Keys

```bash
# Generate SSH key pair for VMs
ssh-keygen -t rsa -b 4096 -f ~/.ssh/erp-azure-key -C "erp-infrastructure"

# Your public key will be at: ~/.ssh/erp-azure-key.pub
```

---

## Phase 1: Bootstrap Setup

Bootstrap creates the foundational infrastructure for Terraform state management.

### Step 1.1: Navigate to Bootstrap Directory

```bash
cd 0-bootstrap
```

### Step 1.2: Create Configuration File

```bash
# Copy example file
cp bootstrap.tfvars.example bootstrap.tfvars

# Edit with your values
nano bootstrap.tfvars
```

**Required values in `bootstrap.tfvars`:**

```hcl
subscription_id         = "your-subscription-id-here"
environment            = "prod"
enable_ddos_protection = false  # Set to true if needed ($2,944/month)
```

### Step 1.3: Initialize Terraform

```bash
terraform init
```

### Step 1.4: Review Plan

```bash
terraform plan -var-file="bootstrap.tfvars"
```

**Expected resources**: ~6 resources (7 with DDoS)
- 2 Resource Groups
- 1 Storage Account
- 1 Storage Container
- 1 Key Vault
- 1 Role Assignment
- 1 DDoS Protection Plan (optional)

### Step 1.5: Apply Bootstrap

```bash
terraform apply -var-file="bootstrap.tfvars"
```

Type `yes` when prompted.

### Step 1.6: Save Outputs

```bash
# Save outputs for reference
terraform output -json > bootstrap-outputs.json

# View backend configuration
terraform output backend_config_prod
```

**Copy the backend configuration** - you'll need it in the next phase.

### Step 1.7: Store Secrets in Key Vault

```bash
# Get Key Vault name from outputs
KEYVAULT_NAME=$(terraform output -raw key_vault_name)

# Store PostgreSQL credentials
az keyvault secret set --vault-name $KEYVAULT_NAME \
  --name postgresql-admin-login --value "your-admin-username"

az keyvault secret set --vault-name $KEYVAULT_NAME \
  --name postgresql-admin-password --value "your-secure-password"

# Store Jumpbox credentials
az keyvault secret set --vault-name $KEYVAULT_NAME \
  --name jumpbox-admin-username --value "azureuser"

az keyvault secret set --vault-name $KEYVAULT_NAME \
  --name jumpbox-admin-password --value "your-secure-password"

# Store Agent VM credentials
az keyvault secret set --vault-name $KEYVAULT_NAME \
  --name agent-vm-admin-username --value "azureuser"

az keyvault secret set --vault-name $KEYVAULT_NAME \
  --name agent-vm-admin-password --value "your-secure-password"
```

**✅ Bootstrap Complete!** You now have:
- Terraform state storage
- Key Vault with secrets
- Backend configuration for environments

---

## Phase 2: Environment Deployment

Deploy the production infrastructure.

### Step 2.1: Navigate to Production Environment

```bash
cd ../environments/canada-central/prod
```

### Step 2.2: Configure Backend

Edit `backend.tf` with the values from bootstrap outputs:

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate-cc-prod"
    storage_account_name = "sttfstate<unique>ccprod"  # From bootstrap output
    container_name       = "tfstate"
    key                  = "canada-central-prod.tfstate"
  }
}
```

### Step 2.3: Create Variables File

```bash
# Copy example (if exists) or create new
cp terraform.tfvars.example terraform.tfvars 2>/dev/null || touch terraform.tfvars

# Edit with your values
nano terraform.tfvars
```

**Required values in `terraform.tfvars`:**

```hcl
# Basic Configuration
subscription_id = "your-subscription-id"
environment     = "prod"
region          = "canadacentral"
region_abbr     = "cc"

# Deployment Stage
deployment_stage = "stage1"  # Start with stage1

# SSH Key for VMs
ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EA... your-public-key-here"

# AKS Configuration
aks_kubernetes_version = "1.28"  # Or latest stable
aks_system_node_count  = 2
aks_user_node_count    = 2

# Database Configuration (will be retrieved from Key Vault)
postgresql_admin_login    = ""  # Leave empty, will be filled from Key Vault
postgresql_admin_password = ""  # Leave empty, will be filled from Key Vault

# VM Configuration (will be retrieved from Key Vault)
jumpbox_admin_username = ""  # Leave empty
jumpbox_admin_password = ""  # Leave empty
agent_vm_admin_username = ""  # Leave empty
agent_vm_admin_password = ""  # Leave empty

# Monitoring
alert_email_receivers = ["your-email@example.com"]

# Tags
tags = {
  Environment = "prod"
  ManagedBy   = "terraform"
  Project     = "ERP"
  CostCenter  = "IT"
}
```

### Step 2.4: Retrieve Secrets from Key Vault

```bash
# Get Key Vault name from bootstrap
KEYVAULT_NAME="kv-erp-<unique>-cc-prod"  # From bootstrap outputs

# Run the script to populate terraform.tfvars with secrets
../../../scripts/get-secrets-from-keyvault.sh $KEYVAULT_NAME terraform.tfvars
```

### Step 2.5: Initialize Terraform

```bash
terraform init
```

This will configure the remote backend and download required providers.

### Step 2.6: Validate Configuration

```bash
# Format code
terraform fmt

# Validate configuration
terraform validate

# Optional: Run CIDR validation
../../../scripts/validate-cidr.py
```

### Step 2.7: Review Stage 1 Plan

```bash
terraform plan -out=tfplan-stage1
```

Review the plan carefully. You should see ~45-50 resources to be created.

### Step 2.8: Apply Stage 1 Deployment

```bash
terraform apply tfplan-stage1
```

**⏱️ Deployment time**: 20-30 minutes

**What's deployed**:
- All networking (Hub VNet, Spoke VNet, Firewall, Bastion)
- Storage services (Storage Account, Container Registry, Key Vault)
- Database (PostgreSQL Flexible Server)
- AKS Cluster with Istio enabled
- Virtual Machines (Jumpbox, Agent)

### Step 2.9: Get Istio Load Balancer IP

After Stage 1 completes, get the Istio ingress gateway IP:

```bash
# Get AKS credentials
../../../scripts/get-aks-credentials.sh aks-erp-cc-prod rg-erp-cc-prod

# Get Istio Load Balancer IP
../../../scripts/get-istio-lb-ip.sh
```

**Save this IP** - you'll need it for Stage 2.

### Step 2.10: Update for Stage 2

Edit `terraform.tfvars`:

```hcl
# Change deployment stage
deployment_stage = "stage2"

# Add Istio Load Balancer IP (from previous step)
istio_ingress_ip = "20.x.x.x"  # Your actual IP
```

### Step 2.11: Review Stage 2 Plan

```bash
terraform plan -out=tfplan-stage2
```

**Changes in Stage 2**:
- AKS outbound type: `loadBalancer` → `userDefinedRouting`
- Route table applied to AKS subnet
- Default route (0.0.0.0/0) points to Azure Firewall

### Step 2.12: Apply Stage 2 Deployment

```bash
terraform apply tfplan-stage2
```

**⏱️ Deployment time**: 5-10 minutes

**✅ Deployment Complete!** Your infrastructure is now fully deployed with centralized firewall routing.

---

## Phase 3: Post-Deployment Configuration

### Step 3.1: Verify AKS Access

```bash
# Get AKS credentials (if not already done)
../../../scripts/get-aks-credentials.sh aks-erp-cc-prod rg-erp-cc-prod

# Verify cluster access
kubectl get nodes
kubectl get namespaces

# Check Istio installation
kubectl get pods -n istio-system
```

### Step 3.2: Configure DNS (if needed)

If you have a custom domain:

```bash
# Get Istio Load Balancer IP
ISTIO_IP=$(kubectl get svc istio-ingressgateway -n istio-system -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

echo "Configure your DNS A record to point to: $ISTIO_IP"
```

### Step 3.3: Deploy Applications

Your AKS cluster is ready for application deployments:

```bash
# Example: Deploy a test application
kubectl create namespace test-app
kubectl apply -f your-app-manifests.yaml -n test-app
```

### Step 3.4: Configure Monitoring

```bash
# Verify Log Analytics workspace
az monitor log-analytics workspace show \
  --resource-group rg-erp-cc-prod \
  --workspace-name log-erp-cc-prod

# Check diagnostic settings
az monitor diagnostic-settings list \
  --resource /subscriptions/<sub-id>/resourceGroups/rg-erp-cc-prod/providers/Microsoft.ContainerService/managedClusters/aks-erp-cc-prod
```

---

## Phase 4: Verification

### Step 4.1: Run Validation Script

```bash
../../../scripts/validate-deployment.sh
```

### Step 4.2: Verify Resources in Azure Portal

1. Navigate to Azure Portal
2. Go to Resource Group: `rg-erp-cc-prod`
3. Verify all resources are created
4. Check resource health status

### Step 4.3: Test Connectivity

```bash
# Test Bastion connectivity to Jumpbox
# (Use Azure Portal Bastion feature)

# Test AKS connectivity
kubectl get nodes
kubectl get pods --all-namespaces

# Test PostgreSQL connectivity (from Jumpbox or AKS pod)
psql -h psql-erp-cc-prod.postgres.database.azure.com -U <admin-user> -d postgres
```

### Step 4.4: Review Costs

```bash
# Check cost analysis in Azure Portal
# Navigate to: Cost Management + Billing > Cost Analysis
# Filter by Resource Group: rg-erp-cc-prod
```

**Expected monthly cost**: $3,445 - $5,945 USD

---

## Quick Reference Commands

```bash
# Get AKS credentials
./scripts/get-aks-credentials.sh aks-erp-cc-prod rg-erp-cc-prod

# Get Istio LB IP
./scripts/get-istio-lb-ip.sh

# Validate CIDR ranges
./scripts/validate-cidr.py

# Backup Terraform state
./scripts/backup-terraform-state.sh

# Get secrets from Key Vault
./scripts/get-secrets-from-keyvault.sh <keyvault-name> <tfvars-file>
```

---

## Troubleshooting

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common issues and solutions.

---

## Next Steps

1. **Configure CI/CD**: See [DEPLOYMENT-GUIDE.md](../DEPLOYMENT-GUIDE.md) for Azure DevOps pipeline setup
2. **Deploy Applications**: Deploy your ERP applications to AKS
3. **Configure Monitoring**: Set up alerts and dashboards in Azure Monitor
4. **Security Hardening**: Review and apply additional security policies
5. **Backup Strategy**: Configure backup policies for databases and storage

---

**Last Updated**: November 2025  
**Version**: 2.1.0

