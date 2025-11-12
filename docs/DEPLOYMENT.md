# Deployment Guide

Complete guide to deploy the ERP infrastructure from scratch to production.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Phase 1: Bootstrap](#phase-1-bootstrap)
3. [Phase 2: Infrastructure Deployment](#phase-2-infrastructure-deployment)
4. [Phase 3: Verification](#phase-3-verification)
5. [Quick Reference](#quick-reference)

---

## Prerequisites

### Required Tools

```bash
# Azure CLI (>= 2.50.0)
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Terraform (>= 1.10.3)
wget https://releases.hashicorp.com/terraform/1.10.3/terraform_1.10.3_linux_amd64.zip
unzip terraform_1.10.3_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# kubectl (>= 1.28.0)
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# Verify installations
az --version
terraform --version
kubectl version --client
```

### Azure Setup

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

# Your public key: ~/.ssh/erp-azure-key.pub
```

---

## Phase 1: Bootstrap

Bootstrap creates foundational infrastructure for Terraform state management.

### Step 1.1: Configure Bootstrap

```bash
cd 0-bootstrap

# Copy example configuration
cp bootstrap.tfvars.example bootstrap.tfvars

# Edit with your values
nano bootstrap.tfvars
```

**Required in `bootstrap.tfvars`:**

```hcl
subscription_id         = "your-subscription-id"
environment            = "prod"
enable_ddos_protection = false
```

### Step 1.2: Deploy Bootstrap

```bash
# Initialize Terraform
terraform init

# Review plan
terraform plan -var-file="bootstrap.tfvars"

# Apply
terraform apply -var-file="bootstrap.tfvars"

# Save outputs
terraform output -json > bootstrap-outputs.json
```

**Created**: State storage, Key Vault, Resource Groups

### Step 1.3: Store Secrets

```bash
# Get Key Vault name
KEYVAULT_NAME=$(terraform output -raw key_vault_name)

# Store PostgreSQL credentials
az keyvault secret set --vault-name $KEYVAULT_NAME \
  --name postgresql-admin-login --value "pgadmin"

az keyvault secret set --vault-name $KEYVAULT_NAME \
  --name postgresql-admin-password --value "YourSecurePassword123!"

# Store Jumpbox credentials
az keyvault secret set --vault-name $KEYVAULT_NAME \
  --name jumpbox-admin-username --value "azureuser"

az keyvault secret set --vault-name $KEYVAULT_NAME \
  --name jumpbox-admin-password --value "YourSecurePassword123!"

# Store Agent VM credentials
az keyvault secret set --vault-name $KEYVAULT_NAME \
  --name agent-vm-admin-username --value "azureuser"

az keyvault secret set --vault-name $KEYVAULT_NAME \
  --name agent-vm-admin-password --value "YourSecurePassword123!"
```

---

## Phase 2: Infrastructure Deployment

### Step 2.1: Configure Environment

```bash
cd ../environments/canada-central/prod

# Create terraform.tfvars
cat > terraform.tfvars <<EOF
# Basic Configuration
subscription_id = "your-subscription-id"
environment     = "prod"
region          = "canadacentral"
region_abbr     = "cc"

# Deployment Stage
deployment_stage = "stage1"

# SSH Key
ssh_public_key = "$(cat ~/.ssh/erp-azure-key.pub)"

# AKS Configuration
aks_kubernetes_version = "1.28"
aks_system_node_count  = 2
aks_user_node_count    = 2

# Monitoring
alert_email_receivers = ["your-email@example.com"]

# Tags
tags = {
  Environment = "prod"
  ManagedBy   = "terraform"
  Project     = "ERP"
}

# Secrets (populated from Key Vault)
postgresql_admin_login    = ""
postgresql_admin_password = ""
jumpbox_admin_username    = ""
jumpbox_admin_password    = ""
agent_vm_admin_username   = ""
agent_vm_admin_password   = ""
EOF

# Retrieve secrets from Key Vault
../../../scripts/get-secrets-from-keyvault.sh $KEYVAULT_NAME terraform.tfvars
```

### Step 2.2: Deploy Stage 1

Stage 1 deploys all infrastructure with AKS using Azure Load Balancer for egress.

```bash
# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Review plan
terraform plan -out=tfplan-stage1

# Apply Stage 1
terraform apply tfplan-stage1
```

**⏱️ Deployment time**: 20-30 minutes

**Resources created**:
- Hub and Spoke VNets with peering
- Azure Firewall Premium + Azure Bastion
- AKS cluster with Istio
- PostgreSQL Flexible Server
- Storage Account, Container Registry, Key Vault
- Log Analytics Workspace + Application Insights
- Virtual Machines (Jumpbox, Agent)

### Step 2.3: Get Istio Load Balancer IP

```bash
# Get AKS credentials
../../../scripts/get-aks-credentials.sh aks-erp-cc-prod rg-erp-cc-prod

# Get Istio Load Balancer IP
ISTIO_IP=$(../../../scripts/get-istio-lb-ip.sh)
echo "Istio Load Balancer IP: $ISTIO_IP"
```

### Step 2.4: Deploy Stage 2

Stage 2 switches AKS to use Azure Firewall for egress (user-defined routing).

```bash
# Update terraform.tfvars
sed -i 's/deployment_stage = "stage1"/deployment_stage = "stage2"/' terraform.tfvars
echo "istio_ingress_ip = \"$ISTIO_IP\"" >> terraform.tfvars

# Review plan
terraform plan -out=tfplan-stage2

# Apply Stage 2
terraform apply tfplan-stage2
```

**⏱️ Deployment time**: 5-10 minutes

**Changes**:
- Route table created and associated with AKS subnet
- Default route (0.0.0.0/0) points to Azure Firewall
- All AKS traffic now flows through centralized firewall

---

## Phase 3: Verification

### Step 3.1: Verify AKS

```bash
# Check nodes
kubectl get nodes

# Check Istio
kubectl get pods -n istio-system

# Check all namespaces
kubectl get pods --all-namespaces
```

### Step 3.2: Verify Resources

```bash
# List all resources in resource group
az resource list --resource-group rg-erp-cc-prod --output table

# Check AKS status
az aks show --name aks-erp-cc-prod \
  --resource-group rg-erp-cc-prod \
  --query "provisioningState"

# Check Firewall status
az network firewall show --name fw-hub-cc-prod \
  --resource-group rg-erp-cc-prod \
  --query "provisioningState"
```

### Step 3.3: Test Connectivity

```bash
# Test from AKS pod
kubectl run test-pod --image=nginx --rm -it -- /bin/bash
# Inside pod:
curl -I https://mcr.microsoft.com

# Check Firewall logs
az monitor log-analytics query \
  --workspace <workspace-id> \
  --analytics-query "AzureDiagnostics | where Category == 'AzureFirewallApplicationRule' | take 10"
```

### Step 3.4: Run Validation Script

```bash
../../../scripts/validate-deployment.sh
```

---

## Quick Reference

### Common Commands

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

### Troubleshooting

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common issues and solutions.

### Clean Up

```bash
# Destroy environment
cd environments/canada-central/prod
terraform destroy

# Destroy bootstrap (WARNING: Deletes state storage!)
cd ../../../0-bootstrap
terraform destroy
```

---

## What Gets Deployed

### Networking
- Hub VNet (10.0.0.0/16) with 4 subnets
- Spoke VNet (10.1.0.0/16) with 3 subnets
- VNet peering (hub ↔ spoke)
- 5 Private DNS zones
- 3 NSGs, 1 Route Table

### Security
- Azure Firewall Premium with policy
- Azure Bastion
- 2 Public IPs

### Compute
- AKS cluster with Istio
- System node pool (2-3 nodes)
- User node pool (2-5 nodes)
- 2 VMs (jumpbox, agent)

### Storage
- Storage Account with private endpoints
- Container Registry with private endpoint
- Key Vault with private endpoint
- File Share

### Data
- PostgreSQL Flexible Server
- Private endpoint

### Monitoring
- Log Analytics Workspace
- Application Insights
- Action Group

**Total**: ~45-50 resources

---

## Two-Stage Deployment Explained

### Why Two Stages?

AKS and Azure Firewall have a circular dependency:
- AKS needs to route traffic through Firewall (requires Firewall IP)
- Firewall needs to allow AKS traffic (requires AKS subnet)

### Stage 1: Initial Deployment
- Deploy all infrastructure
- AKS uses `loadBalancer` outbound type
- Istio gets a Load Balancer IP
- No route table on AKS subnet

### Stage 2: Firewall Routing
- Switch AKS to `userDefinedRouting` outbound type
- Create route table with default route to Firewall
- Associate route table with AKS subnet
- All traffic now flows through Firewall

---

**Version**: 2.1.0
**Last Updated**: November 2025

