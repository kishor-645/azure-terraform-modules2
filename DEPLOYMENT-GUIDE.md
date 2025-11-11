# Azure Terraform Infrastructure Deployment Guide

This guide provides step-by-step instructions for deploying the Azure infrastructure using Azure DevOps pipelines.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Azure DevOps Setup](#azure-devops-setup)
3. [Pipeline Overview](#pipeline-overview)
4. [PR Validation Pipeline](#pr-validation-pipeline)
5. [Deployment Pipeline](#deployment-pipeline)
6. [Key Vault Secret Management](#key-vault-secret-management)
7. [Deployment Flow](#deployment-flow)
8. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Azure Resources
- **Azure Subscription** with appropriate permissions
- **Azure Key Vault** with secrets stored (see [Key Vault Secret Management](#key-vault-secret-management))
- **Storage Account** for Terraform state backend
- **Service Connection** in Azure DevOps

### Azure DevOps
- **Azure DevOps Organization** and Project
- **Service Connection** to Azure subscription
- **Variable Groups** configured (optional, for non-sensitive variables)
- **Environments** created (dev, prod) with approval gates if needed

### Tools
- **Terraform** >= 1.10.3
- **Checkov** >= 3.1.0 (for security scanning)
- **TFLint** >= 0.50.3 (for code linting)

---

## Azure DevOps Setup

### 1. Create Service Connection

1. Go to **Project Settings** → **Service connections**
2. Click **New service connection** → **Azure Resource Manager**
3. Select **Service principal (automatic)** or **Service principal (manual)**
4. Configure:
   - **Subscription**: Select your Azure subscription
   - **Resource group**: Select or create a resource group
   - **Service connection name**: e.g., `sc-terraform-prod`
   - **Security**: Grant access permission to all pipelines

### 2. Create Variable Groups

Create variable groups for environment-specific configurations:

#### Variable Group: `terraform-prod-variables`
- `AZURE_SERVICE_CONNECTION`: `sc-terraform-prod`
- `BACKEND_RESOURCE_GROUP`: `rg-terraform-state-canadacentral`
- `BACKEND_STORAGE_ACCOUNT`: `sttfstateccprod`
- `BACKEND_CONTAINER`: `tfstate`
- `KEYVAULT_NAME`: `kv-erp-cc-prod` (or your Key Vault name)

#### Variable Group: `terraform-dev-variables`
- Similar structure for dev environment

### 3. Create Environments

1. Go to **Pipelines** → **Environments**
2. Create environments:
   - **dev**: For development deployments
   - **prod**: For production deployments (add approval gates if needed)

### 4. Store Secrets in Key Vault

See [Key Vault Secret Management](#key-vault-secret-management) section.

---

## Pipeline Overview

The repository includes two main pipelines:

1. **PR Validation Pipeline** (`azure-pipelines-pr-validation.yml`)
   - Runs on Pull Requests
   - Validates code without deploying
   - Runs Checkov and TFLint scans

2. **Deployment Pipeline** (`azure-pipelines-deployment.yml`)
   - Runs on merge to main/develop
   - Validates code
   - Retrieves secrets from Key Vault
   - Deploys infrastructure

---

## PR Validation Pipeline

### Purpose
Validates Terraform code quality and security before merging.

### Trigger
- Automatically runs on Pull Requests targeting `main` or `develop` branches

### Stages

#### 1. Validate Stage
1. **Terraform Format Check**
   - Ensures all `.tf` files are properly formatted
   - Fails if formatting issues found

2. **Terraform Init**
   - Initializes Terraform backend
   - Downloads providers and modules

3. **Terraform Validate**
   - Validates Terraform syntax and configuration

4. **TFLint Scan**
   - Lints Terraform code for best practices
   - Uses `.tflint.hcl` configuration
   - Fails on errors

5. **Checkov Security Scan**
   - Scans for security misconfigurations
   - Uses `.checkov.yaml` configuration
   - Fails on CRITICAL or HIGH severity issues

6. **Terraform Plan**
   - Creates execution plan (dry-run)
   - Validates resource dependencies
   - Does not apply changes

### Configuration

Update these variables in the pipeline:
- `AZURE_SERVICE_CONNECTION`: Your Azure service connection name
- `BACKEND_RESOURCE_GROUP`: Resource group for state storage
- `BACKEND_STORAGE_ACCOUNT`: Storage account name
- `BACKEND_CONTAINER`: Container name for state files

---

## Deployment Pipeline

### Purpose
Deploys infrastructure to Azure after code validation.

### Trigger
- Runs on merge to `main` (production) or `develop` (development)

### Stages

#### 1. Validate Stage
Same validation steps as PR pipeline:
- Terraform format check
- Terraform init
- Terraform validate
- TFLint scan
- Checkov security scan

#### 2. Deploy Stage
1. **Azure Login**
   - Authenticates to Azure using service connection

2. **Retrieve Secrets from Key Vault**
   - Runs `get-secrets-from-keyvault.sh` script
   - Retrieves secrets and updates `terraform.tfvars`
   - Secrets retrieved:
     - `postgresql-admin-login`
     - `postgresql-admin-password`
     - `jumpbox-admin-username`
     - `jumpbox-admin-password`
     - `agent-vm-admin-username`
     - `agent-vm-admin-password`

3. **Terraform Init**
   - Initializes Terraform backend

4. **Terraform Plan**
   - Creates execution plan
   - Saves plan to `tfplan` file

5. **Terraform Apply**
   - Applies infrastructure changes
   - Uses saved plan file

6. **Cleanup Sensitive Data**
   - Removes secrets from `terraform.tfvars` file
   - Prevents secrets from being committed

### Environment-Specific Behavior

The pipeline automatically detects the branch and sets:
- **main branch**: Deploys to `prod` environment
- **develop branch**: Deploys to `dev` environment

### Approval Gates

For production deployments, configure approval gates:
1. Go to **Pipelines** → **Environments** → **prod**
2. Add **Approvals** and **Checks**
3. Configure approvers and conditions

---

## Key Vault Secret Management

### Required Secrets

Store these secrets in Azure Key Vault:

| Secret Name | Description | Terraform Variable |
|------------|-------------|-------------------|
| `postgresql-admin-login` | PostgreSQL admin username | `postgresql_admin_login` |
| `postgresql-admin-password` | PostgreSQL admin password | `postgresql_admin_password` |
| `jumpbox-admin-username` | Jumpbox VM username | `jumpbox_admin_username` |
| `jumpbox-admin-password` | Jumpbox VM password | `jumpbox_admin_password` |
| `agent-vm-admin-username` | Agent VM username | `agent_vm_admin_username` |
| `agent-vm-admin-password` | Agent VM password | `agent_vm_admin_password` |

### Storing Secrets

#### Using Azure CLI
```bash
# Set Key Vault name
KEYVAULT_NAME="kv-erp-cc-prod"

# Store secrets
az keyvault secret set \
  --vault-name "$KEYVAULT_NAME" \
  --name "postgresql-admin-login" \
  --value "your-postgresql-username"

az keyvault secret set \
  --vault-name "$KEYVAULT_NAME" \
  --name "postgresql-admin-password" \
  --value "your-postgresql-password"

az keyvault secret set \
  --vault-name "$KEYVAULT_NAME" \
  --name "jumpbox-admin-username" \
  --value "azureuser"

az keyvault secret set \
  --vault-name "$KEYVAULT_NAME" \
  --name "jumpbox-admin-password" \
  --value "your-secure-password"

az keyvault secret set \
  --vault-name "$KEYVAULT_NAME" \
  --name "agent-vm-admin-username" \
  --value "azureuser"

az keyvault secret set \
  --vault-name "$KEYVAULT_NAME" \
  --name "agent-vm-admin-password" \
  --value "your-secure-password"
```

#### Using Azure Portal
1. Navigate to your Key Vault
2. Go to **Secrets** → **Generate/Import**
3. Create each secret with the names listed above
4. Set appropriate values

### Service Principal Permissions

The service principal used in Azure DevOps must have:
- **Key Vault Secrets User** role on the Key Vault
- Or **Get** and **List** permissions on secrets

Grant permissions:
```bash
# Get service principal object ID from Azure DevOps service connection
SP_OBJECT_ID="<service-principal-object-id>"
KEYVAULT_NAME="kv-erp-cc-prod"

# Grant Key Vault Secrets User role
az role assignment create \
  --role "Key Vault Secrets User" \
  --assignee "$SP_OBJECT_ID" \
  --scope "/subscriptions/<subscription-id>/resourceGroups/<rg-name>/providers/Microsoft.KeyVault/vaults/$KEYVAULT_NAME"
```

---

## Deployment Flow

### Development Workflow

1. **Create Feature Branch**
   ```bash
   git checkout -b feature/my-feature
   ```

2. **Make Changes**
   - Update Terraform code
   - Commit changes

3. **Create Pull Request**
   - PR Validation pipeline runs automatically
   - Review Checkov and TFLint results
   - Fix any issues

4. **Merge to Develop**
   - Deployment pipeline runs automatically
   - Infrastructure deployed to dev environment

5. **Merge to Main**
   - Deployment pipeline runs (with approval if configured)
   - Infrastructure deployed to prod environment

### Production Deployment Flow

```
┌─────────────────┐
│  Code Changes   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Create PR      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ PR Validation   │◄─── Checkov & TFLint Scans
│   Pipeline      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Merge to Main  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Validate Stage │◄─── Checkov & TFLint Scans
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Approval Gate  │◄─── Manual Approval (if configured)
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Deploy Stage   │
│  ┌───────────┐  │
│  │ Get KV    │  │◄─── Retrieve Secrets
│  │ Secrets   │  │
│  └─────┬─────┘  │
│        │        │
│  ┌─────▼─────┐  │
│  │ TF Init   │  │
│  └─────┬─────┘  │
│        │        │
│  ┌─────▼─────┐  │
│  │ TF Plan   │  │
│  └─────┬─────┘  │
│        │        │
│  ┌─────▼─────┐  │
│  │ TF Apply  │  │
│  └───────────┘  │
└─────────────────┘
```

---

## Troubleshooting

### Common Issues

#### 1. Key Vault Access Denied

**Error**: `Access denied to Key Vault`

**Solution**:
- Verify service principal has **Key Vault Secrets User** role
- Check Key Vault access policies
- Ensure service connection is using correct service principal

#### 2. Terraform Backend Access Denied

**Error**: `Error loading state: Access Denied`

**Solution**:
- Verify service principal has **Storage Blob Data Contributor** role on storage account
- Check storage account firewall rules
- Verify backend configuration in pipeline variables

#### 3. Checkov Scan Fails

**Error**: `Checkov found CRITICAL or HIGH severity issues`

**Solution**:
- Review Checkov output for specific issues
- Update `.checkov.yaml` to skip false positives if needed
- Fix security issues in Terraform code

#### 4. TFLint Scan Fails

**Error**: `TFLint found issues`

**Solution**:
- Review TFLint output for specific issues
- Update `.tflint.hcl` configuration if needed
- Fix linting issues in Terraform code

#### 5. Secrets Not Found

**Error**: `Secret 'xxx' not found in Key Vault`

**Solution**:
- Verify secret names match exactly (case-sensitive)
- Check Key Vault name in pipeline variables
- Ensure secrets are created in the correct Key Vault

#### 6. Terraform Plan Fails

**Error**: `Error running plan`

**Solution**:
- Check Terraform variable values
- Verify all required variables are set
- Review Terraform logs for specific errors
- Ensure backend state is accessible

### Debugging Tips

1. **Enable Debug Logging**
   - Add `TF_LOG=DEBUG` environment variable in pipeline
   - Review detailed Terraform logs

2. **Check Pipeline Logs**
   - Review each step's output
   - Look for error messages and warnings

3. **Validate Locally**
   - Run `terraform fmt -check -recursive`
   - Run `terraform validate`
   - Run `tflint` and `checkov` locally

4. **Verify Service Connection**
   - Test service connection in Azure DevOps
   - Verify service principal permissions in Azure

---

## Best Practices

1. **Always Review PR Validation Results**
   - Fix Checkov and TFLint issues before merging
   - Don't skip security scans

2. **Use Approval Gates for Production**
   - Require manual approval before production deployments
   - Review Terraform plan before approval

3. **Monitor Deployments**
   - Review pipeline logs after each deployment
   - Verify infrastructure in Azure Portal

4. **Keep Secrets Secure**
   - Never commit secrets to repository
   - Use Key Vault for all sensitive values
   - Rotate secrets regularly

5. **Version Control**
   - Tag releases after successful deployments
   - Keep Terraform state files backed up

---

## Additional Resources

- [Terraform Documentation](https://www.terraform.io/docs)
- [Checkov Documentation](https://www.checkov.io/)
- [TFLint Documentation](https://github.com/terraform-linters/tflint)
- [Azure DevOps Pipelines](https://docs.microsoft.com/en-us/azure/devops/pipelines/)

---

## Support

For issues or questions:
1. Review pipeline logs
2. Check troubleshooting section
3. Review Terraform and Azure documentation
4. Contact DevOps team

---

**Last Updated**: $(date)

