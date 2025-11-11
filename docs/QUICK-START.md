# Quick Start Guide

Get your ERP infrastructure up and running in 30 minutes.

## Prerequisites Checklist

- [ ] Azure subscription with Owner/Contributor role
- [ ] Azure CLI installed and authenticated (`az login`)
- [ ] Terraform >= 1.10.3 installed
- [ ] kubectl >= 1.28.0 installed
- [ ] SSH key pair generated

## Step 1: Bootstrap (5 minutes)

Create foundational infrastructure for Terraform state management.

```bash
# Navigate to bootstrap directory
cd 0-bootstrap

# Create configuration file
cp bootstrap.tfvars.example bootstrap.tfvars

# Edit with your subscription ID
nano bootstrap.tfvars
```

**Required in `bootstrap.tfvars`:**
```hcl
subscription_id         = "your-subscription-id-here"
environment            = "prod"
enable_ddos_protection = false
```

```bash
# Deploy bootstrap
terraform init
terraform apply -var-file="bootstrap.tfvars"

# Save Key Vault name for later
KEYVAULT_NAME=$(terraform output -raw key_vault_name)
echo $KEYVAULT_NAME
```

**✅ Created**: State storage, Key Vault, Resource Groups

## Step 2: Store Secrets (2 minutes)

Store sensitive credentials in Key Vault.

```bash
# PostgreSQL credentials
az keyvault secret set --vault-name $KEYVAULT_NAME \
  --name postgresql-admin-login --value "pgadmin"

az keyvault secret set --vault-name $KEYVAULT_NAME \
  --name postgresql-admin-password --value "YourSecurePassword123!"

# Jumpbox credentials
az keyvault secret set --vault-name $KEYVAULT_NAME \
  --name jumpbox-admin-username --value "azureuser"

az keyvault secret set --vault-name $KEYVAULT_NAME \
  --name jumpbox-admin-password --value "YourSecurePassword123!"

# Agent VM credentials
az keyvault secret set --vault-name $KEYVAULT_NAME \
  --name agent-vm-admin-username --value "azureuser"

az keyvault secret set --vault-name $KEYVAULT_NAME \
  --name agent-vm-admin-password --value "YourSecurePassword123!"
```

**✅ Stored**: 6 secrets in Key Vault

## Step 3: Configure Environment (3 minutes)

Set up production environment configuration.

```bash
# Navigate to production environment
cd ../environments/canada-central/prod

# Create variables file
cat > terraform.tfvars <<EOF
# Basic Configuration
subscription_id = "your-subscription-id"
environment     = "prod"
region          = "canadacentral"
region_abbr     = "cc"

# Deployment Stage
deployment_stage = "stage1"

# SSH Key (paste your public key)
ssh_public_key = "$(cat ~/.ssh/id_rsa.pub)"

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
  CostCenter  = "IT"
}

# Secrets (will be populated from Key Vault)
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

**✅ Created**: terraform.tfvars with secrets

## Step 4: Deploy Stage 1 (20-30 minutes)

Deploy all infrastructure with AKS using loadBalancer for egress.

```bash
# Initialize Terraform
terraform init

# Review what will be created
terraform plan -out=tfplan-stage1

# Deploy infrastructure
terraform apply tfplan-stage1
```

**⏱️ Wait**: 20-30 minutes for deployment to complete

**✅ Created**: ~45-50 Azure resources including:
- Hub and Spoke VNets
- Azure Firewall Premium
- Azure Bastion
- AKS cluster with Istio
- PostgreSQL database
- Storage services
- Monitoring

## Step 5: Get Istio Load Balancer IP (1 minute)

```bash
# Get AKS credentials
../../../scripts/get-aks-credentials.sh aks-erp-cc-prod rg-erp-cc-prod

# Get Istio Load Balancer IP
ISTIO_IP=$(../../../scripts/get-istio-lb-ip.sh)
echo "Istio Load Balancer IP: $ISTIO_IP"
```

**✅ Retrieved**: Istio ingress gateway IP

## Step 6: Deploy Stage 2 (5-10 minutes)

Switch AKS to use Azure Firewall for egress.

```bash
# Update terraform.tfvars
sed -i 's/deployment_stage = "stage1"/deployment_stage = "stage2"/' terraform.tfvars
echo "istio_ingress_ip = \"$ISTIO_IP\"" >> terraform.tfvars

# Deploy Stage 2
terraform plan -out=tfplan-stage2
terraform apply tfplan-stage2
```

**⏱️ Wait**: 5-10 minutes for deployment to complete

**✅ Updated**: AKS now routes all traffic through Azure Firewall

## Step 7: Verify Deployment (2 minutes)

```bash
# Check AKS nodes
kubectl get nodes

# Check Istio
kubectl get pods -n istio-system

# Check all namespaces
kubectl get pods --all-namespaces

# Run validation script
../../../scripts/validate-deployment.sh
```

**✅ Verified**: Infrastructure is ready for application deployment

## 🎉 Deployment Complete!

Your infrastructure is now ready. Here's what you have:

### Resources Created
- ✅ Hub-Spoke network topology
- ✅ Azure Firewall Premium with IDPS
- ✅ Azure Bastion for secure VM access
- ✅ Private AKS cluster with Istio service mesh
- ✅ PostgreSQL Flexible Server
- ✅ Storage Account, Container Registry, Key Vault
- ✅ Centralized monitoring with Log Analytics

### Access Points
- **AKS**: Private cluster (access via jumpbox or Azure DevOps agent)
- **VMs**: Access via Azure Bastion in Azure Portal
- **PostgreSQL**: Private endpoint (access from AKS or jumpbox)
- **Monitoring**: Azure Portal → Log Analytics Workspace

### Next Steps
1. **Deploy Applications**: Deploy your ERP applications to AKS
2. **Configure DNS**: Point your domain to Istio Load Balancer IP
3. **Set Up CI/CD**: Configure Azure DevOps pipelines (see [DEPLOYMENT-GUIDE.md](../DEPLOYMENT-GUIDE.md))
4. **Configure Monitoring**: Set up alerts and dashboards
5. **Review Security**: Review firewall rules and NSG configurations

## 📊 Cost Summary

Your infrastructure will cost approximately:

| Service | Monthly Cost |
|---------|-------------|
| Azure Firewall Premium | $1,350 |
| AKS (4 nodes) | $1,000 - $1,500 |
| Azure Bastion | $295 |
| PostgreSQL | $200 - $400 |
| Storage & Monitoring | $100 - $200 |
| **Total** | **$3,445 - $3,945** |

## 🆘 Troubleshooting

### Issue: Terraform init fails
```bash
# Check Azure CLI authentication
az account show

# Re-authenticate if needed
az login
```

### Issue: Secrets not populated
```bash
# Manually run the script
../../../scripts/get-secrets-from-keyvault.sh $KEYVAULT_NAME terraform.tfvars

# Verify secrets exist in Key Vault
az keyvault secret list --vault-name $KEYVAULT_NAME
```

### Issue: AKS deployment fails
```bash
# Check quota limits
az vm list-usage --location canadacentral --output table

# Request quota increase if needed
```

### Issue: Can't access AKS
```bash
# Ensure you're on the jumpbox or have VPN access
# AKS is private - no public endpoint

# Get credentials again
../../../scripts/get-aks-credentials.sh aks-erp-cc-prod rg-erp-cc-prod
```

## 📚 Additional Resources

- **[Deployment Steps](DEPLOYMENT-STEPS.md)** - Detailed step-by-step guide
- **[Environment Resources](ENVIRONMENT-RESOURCES.md)** - Complete resource list
- **[Modules Guide](MODULES-GUIDE.md)** - Module usage reference
- **[Troubleshooting](TROUBLESHOOTING.md)** - Common issues and solutions

## 🔄 Clean Up (Optional)

To destroy all resources:

```bash
# Destroy environment
cd environments/canada-central/prod
terraform destroy

# Destroy bootstrap (WARNING: This deletes state storage!)
cd ../../../0-bootstrap
terraform destroy
```

**⚠️ Warning**: This will delete all resources and cannot be undone!

---

**Version**: 2.1.0  
**Last Updated**: November 2025

