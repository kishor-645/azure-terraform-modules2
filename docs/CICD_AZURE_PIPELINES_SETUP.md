# CI/CD Deployment Guide: Azure Pipelines Setup

Complete step-by-step guide to configure and deploy infrastructure via Azure Pipelines with environment groups, service connections, and variable management.

**Version**: 1.0.0  
**Last Updated**: November 2025  
**Target Audience**: DevOps Engineers, Infrastructure Architects

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Azure DevOps Project Setup](#azure-devops-project-setup)
3. [Service Connection Configuration](#service-connection-configuration)
4. [Azure Key Vault Setup](#azure-key-vault-setup)
5. [Variable Groups Configuration](#variable-groups-configuration)
6. [Environments & Approvals](#environments--approvals)
7. [Pipeline Configuration](#pipeline-configuration)
8. [Running the Pipeline](#running-the-pipeline)
9. [Troubleshooting](#troubleshooting)
10. [Best Practices](#best-practices)

---

## Prerequisites

### Required Azure Resources

- **Azure Subscription** with Owner or Contributor access
- **Azure DevOps Organization** with project created
- **Azure Storage Account** for Terraform backend state
- **Azure Key Vault** for secrets management
- **Azure Service Principal** with appropriate permissions

### Required Permissions

- **Azure DevOps**: Project Administrator or Build Administrator
- **Azure Subscription**: Owner, Contributor, or custom role with:
  - Microsoft.Storage/storageAccounts (read/write)
  - Microsoft.KeyVault/vaults (read/write secrets)
  - Microsoft.Authorization/roleAssignments (read/write)

### Tools & Access

- Git repository (Azure DevOps or GitHub)
- Terraform >= 1.10.3
- Azure CLI 2.0+

---

## Azure DevOps Project Setup

### Step 1: Create Project in Azure DevOps

1. Navigate to https://dev.azure.com
2. Click **New Project**
3. Enter project details:
   - **Project Name**: `azure-terraform-modules`
   - **Visibility**: Private (or select based on org policy)
   - **Version Control**: Git
4. Click **Create**

### Step 2: Prepare Git Repository

1. Clone repository:
   ```bash
   git clone https://dev.azure.com/your-org/azure-terraform-modules/_git/azure-terraform-modules
   cd azure-terraform-modules
   ```

2. Copy pipeline files to `pipelines/` directory:
   ```bash
   # Files should already be in place:
   # - pipelines/azure-pipelines-deployment.yml
   # - pipelines/azure-pipelines-pr-validation.yml
   # - pipelines/templates/
   ```

3. Commit and push:
   ```bash
   git add .
   git commit -m "Initial pipeline setup"
   git push origin main
   ```

---

## Service Connection Configuration

Service connections authenticate Azure DevOps to your Azure subscription for deployment.

### Step 1: Create Service Principal (if not exists)

Using Azure CLI:

```bash
# Set variables
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
TENANT_ID=$(az account show --query tenantId -o tsv)
SERVICE_PRINCIPAL_NAME="terraform-cicd-sp"

# Create service principal
az ad sp create-for-rbac \
  --name $SERVICE_PRINCIPAL_NAME \
  --role Contributor \
  --scopes /subscriptions/$SUBSCRIPTION_ID

# Output will show:
# "appId": "<CLIENT_ID>",
# "password": "<CLIENT_SECRET>",
# "tenant": "<TENANT_ID>"
# Save these values securely
```

### Step 2: Create Service Connection in Azure DevOps

1. Navigate to Project Settings → Service Connections
2. Click **Create Service Connection**
3. Select **Azure Resource Manager**
4. Choose authentication method: **Service Principal (manual)**
5. Fill in details:
   - **Environment**: Azure Cloud
   - **Scope Level**: Subscription
   - **Subscription ID**: Your Azure Subscription ID
   - **Subscription Name**: (auto-populated)
   - **Service Principal ID**: App ID from step 1 (`appId`)
   - **Service Principal Key**: Password from step 1 (`password`)
   - **Tenant ID**: Tenant ID from step 1 (`tenant`)
   - **Service Connection Name**: `terraform-azure-connection`
6. Check **Grant access permission to all pipelines**
7. Click **Verify and save**

### Step 3: Grant Service Principal Permissions

Assign Key Vault and Storage Account access:

```bash
# Get Service Principal Object ID
SERVICE_PRINCIPAL_OBJECT_ID=$(az ad sp show \
  --id $SERVICE_PRINCIPAL_NAME \
  --query id -o tsv)

# Assign Storage Account access (backend state)
az role assignment create \
  --assignee $SERVICE_PRINCIPAL_OBJECT_ID \
  --role "Storage Blob Data Contributor" \
  --scope /subscriptions/$SUBSCRIPTION_ID/resourceGroups/<RG_NAME>/providers/Microsoft.Storage/storageAccounts/<STORAGE_ACCOUNT_NAME>

# Assign Key Vault access (secret retrieval)
az role assignment create \
  --assignee $SERVICE_PRINCIPAL_OBJECT_ID \
  --role "Key Vault Secrets Officer" \
  --scope /subscriptions/$SUBSCRIPTION_ID/resourceGroups/<RG_NAME>/providers/Microsoft.KeyVault/vaults/<KEYVAULT_NAME>
```

---

## Azure Key Vault Setup

Key Vault stores sensitive values like passwords and database credentials.

### Step 1: Create/Identify Key Vault

If not already created:

```bash
KEYVAULT_NAME="terraform-secrets-$(date +%s)"
RESOURCE_GROUP="terraform-rg"

az keyvault create \
  --name $KEYVAULT_NAME \
  --resource-group $RESOURCE_GROUP \
  --location canadacentral
```

### Step 2: Add Secrets to Key Vault

Store passwords and credentials:

```bash
# Add required secrets
az keyvault secret set --vault-name $KEYVAULT_NAME \
  --name "postgresql-admin-password" \
  --value "SecurePassword123!@#"

az keyvault secret set --vault-name $KEYVAULT_NAME \
  --name "jumpbox-admin-password" \
  --value "SecureJumpboxPassword123!@#"

az keyvault secret set --vault-name $KEYVAULT_NAME \
  --name "vm-admin-password" \
  --value "SecureVMPassword123!@#"

# List secrets
az keyvault secret list --vault-name $KEYVAULT_NAME --query "[].name"
```

### Step 3: Grant Service Principal Access

```bash
# Set policy (already done via role assignment, but can also use set-policy)
az keyvault set-policy \
  --name $KEYVAULT_NAME \
  --object-id $SERVICE_PRINCIPAL_OBJECT_ID \
  --secret-permissions get list
```

---

## Variable Groups Configuration

Variable groups centralize environment-specific configuration in Azure DevOps.

### Step 1: Create Dev Variable Group

1. Navigate to **Pipelines → Library**
2. Click **+ Variable group**
3. Fill in details:
   - **Name**: `terraform-dev-variables`
   - **Description**: "Development environment Terraform variables"
4. Add variables (click **+ Add**):

| Variable Name | Value | Secret? |
|---|---|---|
| `AZURE_SERVICE_CONNECTION` | `terraform-azure-connection` | No |
| `ENVIRONMENT` | `dev` | No |
| `BACKEND_RESOURCE_GROUP` | `terraform-backend-rg` | No |
| `BACKEND_STORAGE_ACCOUNT` | `tfstatestg123` | No |
| `BACKEND_CONTAINER` | `tfstate` | No |
| `KEYVAULT_NAME` | `terraform-secrets-dev` | No |
| `AZURE_CLIENT_ID` | `<service_principal_app_id>` | Yes |
| `AZURE_CLIENT_SECRET` | `<service_principal_password>` | Yes |
| `AZURE_TENANT_ID` | `<tenant_id>` | Yes |

5. Click **Save**

### Step 2: Create Prod Variable Group

1. Click **+ Variable group**
2. Fill in details:
   - **Name**: `terraform-prod-variables`
   - **Description**: "Production environment Terraform variables"
3. Add variables with **prod-specific values**:

| Variable Name | Value | Secret? |
|---|---|---|
| `AZURE_SERVICE_CONNECTION` | `terraform-azure-connection` | No |
| `ENVIRONMENT` | `prod` | No |
| `BACKEND_RESOURCE_GROUP` | `terraform-backend-prod-rg` | No |
| `BACKEND_STORAGE_ACCOUNT` | `tfstategprod123` | No |
| `BACKEND_CONTAINER` | `tfstate-prod` | No |
| `KEYVAULT_NAME` | `terraform-secrets-prod` | No |
| `AZURE_CLIENT_ID` | `<service_principal_app_id>` | Yes |
| `AZURE_CLIENT_SECRET` | `<service_principal_password>` | Yes |
| `AZURE_TENANT_ID` | `<tenant_id>` | Yes |

4. Click **Save**

### Step 3: Reference Variable Groups in Pipeline

In `azure-pipelines-deployment.yml`:

```yaml
variables:
  - group: terraform-dev-variables   # For dev deployments
  # Or
  - group: terraform-prod-variables  # For prod deployments
  - name: TF_VERSION
    value: '1.10.3'
```

---

## Environments & Approvals

Environments add approval gates and deployment tracking.

### Step 1: Create Dev Environment

1. Navigate to **Pipelines → Environments**
2. Click **Create environment**
3. Fill in:
   - **Name**: `dev`
   - **Description**: "Development environment"
4. Click **Create**

### Step 2: Create Prod Environment with Approvals

1. Click **Create environment**
2. Fill in:
   - **Name**: `prod`
   - **Description**: "Production environment"
3. Click **Create**

### Step 3: Add Approval Check to Prod

1. Go to `prod` environment
2. Click the **Approvals and checks** button (or the three dots menu)
3. Click **Create → Approvals**
4. Fill in:
   - **Approvers**: Select team members/groups (e.g., DevOps Team)
   - **Instructions for approvers**: "Review Terraform plan before approving"
   - **Timeout (in minutes)**: 1440 (24 hours)
5. Click **Create**

### Step 4: Add Branch Control (Optional)

1. In `prod` environment, click **Approvals and checks**
2. Click **Create → Branch control**
3. Select **Protect branch**
   - **Branch**: `main`
   - **Timeout (in minutes)**: 1440
4. Click **Create**

---

## Pipeline Configuration

### Step 1: Configure Deployment Pipeline

Update `pipelines/azure-pipelines-deployment.yml`:

```yaml
# Set the branch trigger
trigger:
  branches:
    include:
      - main
      - develop

# Disable PR trigger if using separate PR validation pipeline
pr: none

# Variable group selection (conditional)
variables:
  ${{ if eq(variables['Build.SourceBranch'], 'refs/heads/main') }}:
    - group: terraform-prod-variables
  ${{ else }}:
    - group: terraform-dev-variables
  - name: TF_VERSION
    value: '1.10.3'
```

### Step 2: Verify Service Connection in Pipeline

Ensure these tasks reference the service connection:

```yaml
- task: TerraformTaskV4@4
  displayName: 'Terraform Init'
  inputs:
    provider: 'azurerm'
    command: 'init'
    workingDirectory: $(WORKING_DIRECTORY)
    backendServiceArm: '$(AZURE_SERVICE_CONNECTION)'
    backendAzureRmResourceGroupName: '$(BACKEND_RESOURCE_GROUP)'
    backendAzureRmStorageAccountName: '$(BACKEND_STORAGE_ACCOUNT)'
    backendAzureRmContainerName: '$(BACKEND_CONTAINER)'
    backendAzureRmKey: 'terraform.tfstate'

- task: AzureCLI@2
  displayName: 'Azure Login'
  inputs:
    azureSubscription: '$(AZURE_SERVICE_CONNECTION)'
    scriptType: 'bash'
    scriptLocation: 'inlineScript'
```

### Step 3: Environment Mapping in Deployment Job

```yaml
- deployment: TerraformDeploy
  displayName: 'Terraform Apply'
  environment: $(ENVIRONMENT)  # References env variable from variable group
  strategy:
    runOnce:
      deploy:
        steps:
          # Pipeline steps here
```

---

## Running the Pipeline

### Trigger 1: Automatic on Main Branch

When code is merged to `main`:

1. Validation stage runs automatically
2. If validation passes, pipeline waits at Deploy stage
3. Approvers receive approval request
4. Once approved, Terraform apply executes

### Trigger 2: Manual Trigger

1. Navigate to **Pipelines → Your Pipeline Name**
2. Click **Run pipeline**
3. Select branch: `main` or `develop`
4. Click **Run**

### Trigger 3: Pull Request Validation

When PR is created, `azure-pipelines-pr-validation.yml` runs automatically:
- Terraform format check
- Terraform validation
- TFLint scan
- Checkov security scan

**PR will not merge until checks pass.**

---

## Monitoring Pipeline Execution

### View Pipeline Run

1. Navigate to **Pipelines → Runs**
2. Click the latest run
3. Monitor stages:
   - **Validate**: Code quality & security scans
   - **Deploy**: Terraform plan & apply
4. Click on individual jobs to see logs

### View Deployment Status

1. Navigate to **Pipelines → Environments → [Environment Name]**
2. See deployment history and status
3. Click on deployment for logs and details

### Download Artifacts

1. In pipeline run, click **Artifacts**
2. Available artifacts (if configured):
   - `tfplan` (Terraform plan file)
   - `checkov-results` (Security scan results)

---

## Troubleshooting

### Issue 1: "Service Connection Authorization Failed"

**Cause**: Service principal doesn't have subscription access.

**Fix**:
```bash
# Verify service principal has Contributor role
az role assignment list --assignee $SERVICE_PRINCIPAL_OBJECT_ID

# Re-assign if needed
az role assignment create \
  --assignee $SERVICE_PRINCIPAL_OBJECT_ID \
  --role "Contributor" \
  --scope /subscriptions/$SUBSCRIPTION_ID
```

### Issue 2: "Key Vault Access Denied"

**Cause**: Service principal lacks Key Vault permissions.

**Fix**:
```bash
# Set Key Vault policy
az keyvault set-policy \
  --name $KEYVAULT_NAME \
  --object-id $SERVICE_PRINCIPAL_OBJECT_ID \
  --secret-permissions get list
```

### Issue 3: "Backend Storage Account Access Denied"

**Cause**: Service principal lacks storage access.

**Fix**:
```bash
# Grant Storage Blob Data Contributor role
az role assignment create \
  --assignee $SERVICE_PRINCIPAL_OBJECT_ID \
  --role "Storage Blob Data Contributor" \
  --scope /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Storage/storageAccounts/$STORAGE_ACCOUNT_NAME
```

### Issue 4: "TFLint: Command line arguments support was dropped"

**Cause**: Pipeline uses old tflint syntax.

**Fix**: Update pipeline to use `tflint --chdir`:
```yaml
script: |
  cd $(WORKING_DIRECTORY)
  tflint --init
  tflint --chdir . --format compact
```

### Issue 5: "Approval Timeout"

**Cause**: Approval request expired before review.

**Fix**: Increase timeout in environment approvals:
1. Go to **Environments → [Environment] → Approvals and checks**
2. Edit approval
3. Increase **Timeout** value (default: 1440 minutes)

### Issue 6: Pipeline Variable Not Resolved

**Cause**: Variable group not linked or variable name mistyped.

**Fix**:
1. Verify variable group is added to pipeline YAML
2. Ensure variable name matches exactly (case-sensitive)
3. Check variable group is saved in library

---

## Best Practices

### Security

1. **Service Principal Secrets**
   - Store in Key Vault, not in pipeline files
   - Rotate credentials every 90 days
   - Use separate service principals for dev/prod

2. **Secret Management**
   - Mark all secrets as "Secret" in variable groups
   - Use Key Vault for sensitive values
   - Never commit secrets to Git

3. **Access Control**
   - Limit approvers to security/ops teams for prod
   - Use branch protection rules for main branch
   - Audit access to service connections regularly

### Pipeline Reliability

1. **State Management**
   - Use remote backend in Azure Storage
   - Enable state file locking
   - Regularly backup state files

2. **Idempotency**
   - Design modules to be reapplied safely
   - Use `terraform refresh` periodically
   - Test destroy/recreate scenarios

3. **Monitoring & Logging**
   - Enable pipeline logs retention (default: 30 days)
   - Archive critical deployment logs
   - Set up alerts for failed deployments

### Deployment Strategy

1. **Staged Deployments**
   - Deploy to dev first, validate, then prod
   - Use separate branches for different stages
   - Require approvals for prod deployments

2. **Rollback Plan**
   - Maintain previous `.tfstate` backups
   - Document rollback procedures
   - Test rollback in lower environments

3. **Documentation**
   - Keep Terraform code documented (comments)
   - Maintain module README files
   - Document any manual approval decisions

### Code Quality

1. **Pre-commit Hooks**
   - Run locally before pushing:
     ```bash
     pre-commit run --all-files
     ```

2. **Linting & Validation**
   - Enforce TFLint rules (no failures on merge)
   - Run security scans (Checkov) in pipeline
   - Keep dependencies updated

3. **Code Review**
   - Require at least 2 approvers for main branch
   - Review Terraform plan in pull request
   - Document architectural decisions

---

## Quick Reference

### Important Commands

```bash
# View current variable groups
az pipelines variable group list --project terraform

# Create variable group via CLI
az pipelines variable group create \
  --name terraform-prod-variables \
  --variables VAR1=value1 VAR2=value2

# List deployments
az pipelines release list --project terraform

# Approve/reject deployment
az pipelines release deployment queue --id <deployment_id> --status approved
```

### Environment Variables Reference

| Variable | Required | Example | Notes |
|---|---|---|---|
| `AZURE_SERVICE_CONNECTION` | Yes | `terraform-azure-connection` | Service connection name |
| `ENVIRONMENT` | Yes | `prod` or `dev` | Used for approval gates |
| `BACKEND_RESOURCE_GROUP` | Yes | `terraform-backend-rg` | Storage account RG |
| `BACKEND_STORAGE_ACCOUNT` | Yes | `tfstatestg123` | Storage account name |
| `BACKEND_CONTAINER` | Yes | `tfstate` | Storage container |
| `KEYVAULT_NAME` | Yes | `terraform-secrets` | Key Vault name |
| `AZURE_CLIENT_ID` | Yes | `xxxxxxxx-xxxx-...` | Service principal app ID |
| `AZURE_CLIENT_SECRET` | Yes | (secret) | Service principal password |
| `AZURE_TENANT_ID` | Yes | `xxxxxxxx-xxxx-...` | Azure AD tenant ID |

---

## Additional Resources

- [Azure DevOps Documentation](https://learn.microsoft.com/azure/devops/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure Key Vault Best Practices](https://learn.microsoft.com/azure/key-vault/general/best-practices)
- [Azure Pipeline YAML Schema](https://learn.microsoft.com/azure/devops/pipelines/yaml-schema)

---

## Support & Feedback

For issues or questions:
1. Check the [Troubleshooting](#troubleshooting) section
2. Review pipeline logs in Azure DevOps
3. Contact the Infrastructure team
4. File an issue in the repository
