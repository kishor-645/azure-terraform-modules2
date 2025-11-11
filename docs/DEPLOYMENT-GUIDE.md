# Azure Terraform Infrastructure Deployment Guide

Complete step-by-step guide for deploying the ERP infrastructure on Azure using Terraform.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Architecture Overview](#architecture-overview)
3. [Initial Setup](#initial-setup)
4. [Configuration](#configuration)
5. [Deployment Steps](#deployment-steps)
6. [Post-Deployment](#post-deployment)
7. [Troubleshooting](#troubleshooting)

## Prerequisites

### Required Tools

- **Azure CLI** >= 2.50.0
- **Terraform** >= 1.10.3
- **kubectl** >= 1.28.0
- **Git** (for cloning the repository)

### Azure Requirements

- Active Azure subscription
- Owner or Contributor role on the subscription
- Azure AD tenant with permissions to create service principals
- SSH key pair for VM access

### Install Tools

```bash
# Install Azure CLI (Linux/Mac)
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Install Terraform
wget https://releases.hashicorp.com/terraform/1.10.3/terraform_1.10.3_linux_amd64.zip
unzip terraform_1.10.3_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
```

## Architecture Overview

### Infrastructure Components

The infrastructure consists of:

1. **Networking**
   - Hub Virtual Network (10.0.0.0/16 for prod, 10.2.0.0/16 for dev)
   - Spoke Virtual Network (10.1.0.0/16 for prod, 10.3.0.0/16 for dev)
   - Azure Firewall with Premium SKU
   - Azure Bastion for secure access
   - Private DNS Zones for private endpoints

2. **Compute**
   - Private AKS Cluster with Istio Service Mesh (inbuilt)
   - Shared subnet for system and user node pools
   - Jumpbox VM for administrative access
   - Agent VM for CI/CD operations

3. **Storage & Data**
   - Azure Key Vault (Premium)
   - Azure Storage Account (Blob & File)
   - Azure Container Registry (Premium)
   - PostgreSQL Flexible Server

4. **Monitoring**
   - Log Analytics Workspace
   - Diagnostic settings for all resources

### Key Features

- **Single Resource Group**: All resources deployed in one resource group per environment
- **Single Region**: All resources in Canada Central region
- **Shared AKS Subnet**: Both system and user node pools use the same subnet
- **Istio Inbuilt**: Istio service mesh enabled as inbuilt AKS feature
- **Private Endpoints**: All Azure services accessed via private endpoints
- **Hub-Spoke Topology**: Centralized firewall for security

## Initial Setup

### 1. Login to Azure

```bash
az login
az account set --subscription "YOUR_SUBSCRIPTION_ID"
```

### 2. Clone Repository

```bash
git clone <repository-url>
cd azure-terraform-modules
```

### 3. Setup Backend Storage (First Time Only)

The Terraform state is stored in Azure Storage. Create the storage account:

```bash
cd 0-bootstrap
terraform init
terraform plan -var-file=bootstrap.tfvars
terraform apply -var-file=bootstrap.tfvars
```

## Configuration

### 1. Choose Environment

Navigate to the desired environment:

```bash
# For Production
cd environments/canada-central/prod

# For Development
cd environments/canada-central/dev
```

### 2. Configure Variables

Copy the example tfvars file:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your values:

```hcl
# Required Variables
subscription_id = "your-subscription-id"
tenant_id      = "your-tenant-id"

# AKS Admin Group
aks_admin_group_object_ids = ["your-azure-ad-group-object-id"]

# SSH Keys
jumpbox_ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2E..."
agent_vm_ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2E..."

# PostgreSQL Credentials
postgresql_admin_login    = "postgresadmin"
postgresql_admin_password = "SecurePassword123!@#"
```

### 3. Get Azure AD Group Object ID

```bash
# List Azure AD groups
az ad group list --display-name "AKS-Admins" --query "[].id" -o tsv
```

## Deployment Steps

### Stage 1: Initial Deployment

Stage 1 deploys all infrastructure except the AKS route table (which requires Istio LB IP).

#### 1. Initialize Terraform

```bash
terraform init
```

#### 2. Review Plan

```bash
terraform plan
```

#### 3. Apply Configuration

```bash
terraform apply
```

Type `yes` when prompted. This will take approximately 30-45 minutes.

#### 4. Get AKS Credentials

```bash
# Get the resource group name from outputs
terraform output resource_group_name

# Get AKS credentials
az aks get-credentials \
  --resource-group $(terraform output -raw resource_group_name) \
  --name $(terraform output -raw aks_cluster_name) \
  --admin
```

#### 5. Discover Istio Internal Load Balancer IP

```bash
# Wait for Istio to be ready (may take 5-10 minutes)
kubectl wait --for=condition=ready pod -l app=istio-ingressgateway -n istio-system --timeout=300s

# Get the Istio internal LB IP
kubectl get svc istio-ingressgateway -n istio-system -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

Copy the IP address (e.g., `10.100.0.100`).

### Stage 2: Complete Deployment

Stage 2 adds the route table to route AKS outbound traffic through Azure Firewall.

#### 1. Update terraform.tfvars

```hcl
deployment_stage = "stage2"
istio_internal_lb_ip = "10.100.0.100"  # IP from previous step
```

#### 2. Apply Route Table

```bash
terraform apply
```

This will create the route table and associate it with the AKS subnet.

## Post-Deployment

### Verify Deployment

#### 1. Check AKS Cluster

```bash
kubectl get nodes
kubectl get pods -A
```

#### 2. Verify Istio

```bash
kubectl get pods -n istio-system
kubectl get svc -n istio-system
```

#### 3. Test Private Endpoints

```bash
# From jumpbox, test private endpoint connectivity
az vm run-command invoke \
  --resource-group $(terraform output -raw resource_group_name) \
  --name vm-jumpbox-* \
  --command-id RunShellScript \
  --scripts "nslookup <storage-account-name>.blob.core.windows.net"
```

### Access Resources

#### Access Jumpbox via Bastion

1. Go to Azure Portal
2. Navigate to Azure Bastion resource
3. Click "Connect" → "Bastion"
4. Select the jumpbox VM
5. Enter credentials

#### Access AKS Cluster

```bash
# From jumpbox or local machine
az aks get-credentials \
  --resource-group $(terraform output -raw resource_group_name) \
  --name $(terraform output -raw aks_cluster_name) \
  --admin

kubectl get nodes
```

## Module Usage Guide

### Networking Modules

#### Hub VNet Module

Creates the hub virtual network with subnets for:
- Azure Firewall
- Azure Firewall Management
- Azure Bastion
- Shared Services
- Private Endpoints

**Usage:**
```hcl
module "hub_vnet" {
  source = "../../../modules/networking/hub-vnet"
  
  vnet_name           = "vnet-hub-canadacentral-prod"
  location            = "canadacentral"
  resource_group_name = azurerm_resource_group.main.name
  address_space       = ["10.0.0.0/16"]
  
  tags = local.common_tags
}
```

#### Spoke VNet Module

Creates the spoke virtual network with:
- **Shared AKS Node Pool Subnet** (10.1.0.0/20) - Used by both system and user node pools
- Private Endpoints Subnet (10.1.16.0/24)
- Jumpbox/Agent VM Subnet (10.1.17.0/27)

**Usage:**
```hcl
module "spoke_vnet" {
  source = "../../../modules/networking/spoke-vnet"
  
  vnet_name           = "vnet-spoke-canadacentral-prod"
  location            = "canadacentral"
  resource_group_name = azurerm_resource_group.main.name
  address_space       = ["10.1.0.0/16"]
  
  aks_node_pool_subnet_cidr = "10.1.0.0/20"
  private_endpoints_subnet_cidr = "10.1.16.0/24"
  jumpbox_subnet_cidr = "10.1.17.0/27"
  
  tags = local.common_tags
}
```

### Compute Modules

#### AKS Cluster Module

Creates a private AKS cluster with:
- Istio service mesh (inbuilt feature)
- Shared subnet for node pools
- Azure RBAC integration
- Key Vault secrets provider

**Key Features:**
- **Istio Inbuilt**: Enabled via `service_mesh_profile` block
- **Shared Subnet**: Both node pools use `aks_node_pool_subnet_id`
- **Private Cluster**: No public API endpoint

**Usage:**
```hcl
module "aks_cluster" {
  source = "../../../modules/compute/aks-cluster"
  
  cluster_name             = "aks-canadacentral-prod"
  location                 = "canadacentral"
  resource_group_name      = azurerm_resource_group.main.name
  aks_node_pool_subnet_id  = module.spoke_vnet.aks_node_pool_subnet_id
  
  # Istio Configuration
  istio_internal_ingress_gateway_enabled = true
  istio_external_ingress_gateway_enabled = false
  
  # ... other variables
}
```

### Storage Modules

#### Key Vault Module

Creates Azure Key Vault with private endpoint.

**Usage:**
```hcl
module "key_vault" {
  source = "../../../modules/storage/key-vault"
  
  key_vault_name      = "kv-erp-cc-prod"
  location            = "canadacentral"
  resource_group_name = azurerm_resource_group.main.name
  
  enable_private_endpoint = true
  private_endpoint_subnet_id = module.spoke_vnet.private_endpoints_subnet_id
  private_dns_zone_ids = [module.private_dns_zones["keyvault"].dns_zone_id]
}
```

#### Container Registry Module

Creates Azure Container Registry with private endpoint.

**Usage:**
```hcl
module "container_registry" {
  source = "../../../modules/storage/container-registry"
  
  registry_name      = "acrerpccprod"
  location           = "canadacentral"
  resource_group_name = azurerm_resource_group.main.name
  
  sku = "Premium"
  
  enable_private_endpoint = true
  private_endpoint_subnet_id = module.spoke_vnet.private_endpoints_subnet_id
  private_dns_zone_ids = [module.private_dns_zones["acr"].dns_zone_id]
}
```

## Troubleshooting

### Common Issues

#### 1. Terraform State Lock

**Error:** `Error acquiring the state lock`

**Solution:**
```bash
terraform force-unlock <LOCK_ID>
```

#### 2. AKS Node Pool Not Ready

**Error:** Nodes in `NotReady` state

**Solution:**
```bash
# Check node status
kubectl describe node <node-name>

# Check system pods
kubectl get pods -n kube-system
```

#### 3. Istio Not Available

**Error:** `istio-ingressgateway` service not found

**Solution:**
```bash
# Wait for Istio to be deployed (can take 10-15 minutes)
kubectl wait --for=condition=ready pod -l app=istio-ingressgateway -n istio-system --timeout=600s

# Check Istio pods
kubectl get pods -n istio-system
```

#### 4. Private Endpoint DNS Resolution

**Error:** Cannot resolve private endpoint DNS names

**Solution:**
1. Verify private DNS zones are linked to VNet
2. Check DNS zone records are created
3. Test from within the VNet (use jumpbox)

#### 5. Firewall Blocking Traffic

**Error:** Outbound traffic blocked

**Solution:**
1. Check firewall application rules
2. Verify network rules allow required traffic
3. Check route table is associated with subnet

### Getting Help

1. Check Terraform logs: `terraform apply -debug`
2. Review Azure Portal for resource status
3. Check Log Analytics workspace for diagnostic logs
4. Review module README files in `modules/` directory

## Cleanup

To destroy the infrastructure:

```bash
# Stage 2 cleanup (remove route table first)
terraform destroy -target=module.route_table_aks

# Full cleanup
terraform destroy
```

**Warning:** This will delete all resources. Ensure you have backups of important data.

## Additional Resources

- [Terraform Azure Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [AKS Documentation](https://docs.microsoft.com/azure/aks/)
- [Istio Documentation](https://istio.io/latest/docs/)
- [Azure Firewall Documentation](https://docs.microsoft.com/azure/firewall/)

---

**Version:** 2.0.0  
**Last Updated:** November 2025
