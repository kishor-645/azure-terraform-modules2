# Bootstrap Infrastructure

This directory contains Terraform configuration to create foundational infrastructure needed for state management in Canada Central.

## Purpose

The bootstrap process creates:
- **Terraform State Storage**: Azure Storage Account with blob container
- **Key Vault**: Secure storage for secrets and certificates
- **DDoS Protection Plan**: Optional DDoS protection
- **Resource Groups**: Organizational containers for bootstrap resources

## Prerequisites

1. **Azure CLI** installed and authenticated:
   ```bash
   az login
   az account set --subscription "YOUR_SUBSCRIPTION_ID"
   ```

2. **Terraform** >= 1.10.3 installed

3. **Permissions**: Owner or Contributor + User Access Administrator on subscription

## Usage

### Step 1: Configure Variables

```bash
# Copy example configuration
cp bootstrap.tfvars.example bootstrap.tfvars

# Edit with your values
vi bootstrap.tfvars
```

**Required Variables:**
- `subscription_id`: Your Azure subscription ID

**Optional Variables:**
- `enable_ddos_protection`: Enable DDoS Standard (default: false)

### Step 2: Initialize Terraform

```bash
terraform init
```

### Step 3: Review Plan

```bash
terraform plan -var-file="bootstrap.tfvars"
```

**Expected Resources:**
- 2 Resource Groups (state storage and Key Vault)
- 1 Storage Account (with GRS replication)
- 1 Storage Container (tfstate)
- 1 Key Vault (with RBAC)
- 1 Role Assignment (Key Vault Administrator)
- 1 DDoS Protection Plan (if enabled)

**Total:** ~6 resources (7 with DDoS)

### Step 4: Apply Configuration

```bash
terraform apply -var-file="bootstrap.tfvars"
```

**Duration:** ~3-5 minutes

### Step 5: Save Outputs

```bash
# Save outputs to file for reference
terraform output -json > bootstrap-outputs.json

# View backend configuration examples
terraform output backend_config_dev
terraform output backend_config_prod
```

## Outputs

Key outputs needed for deployments:

- `tfstate_storage_account_name`: Storage account name for backend configuration
- `key_vault_name`: Key Vault name for secrets management
- `ddos_protection_plan_id`: DDoS plan ID for VNet association (if enabled)
- `backend_config_*`: Copy-paste ready backend configurations

## Post-Bootstrap Steps

1. **Update Regional Backend Configs:**
   - Copy storage account names from outputs
   - Update `environments/<region>/<env>/backend.tf` files

2. **Restrict Network Access (Recommended):**
   ```bash
   # Restrict storage account to specific IPs
   az storage account update      --name <storage-account-name>      --resource-group <resource-group-name>      --default-action Deny

   # Allow your IP
   az storage account network-rule add      --account-name <storage-account-name>      --resource-group <resource-group-name>      --ip-address <your-public-ip>
   ```

3. **Configure Key Vault Access:**
   - Grant AKS managed identities access to Key Vaults
   - Store database passwords, certificates in Key Vault

4. **Enable Private Endpoints (Optional):**
   - Create private endpoints for storage accounts
   - Create private endpoints for Key Vaults
   - Update network rules to deny public access

## Security Considerations

### Storage Account Security
- ✅ HTTPS-only traffic enforced
- ✅ TLS 1.2 minimum version
- ✅ Geo-redundant storage (GRS) for disaster recovery
- ✅ Blob versioning enabled (30-day retention)
- ✅ Soft delete enabled (30 days)
- ⚠️ Public access initially allowed (restrict post-deployment)

### Key Vault Security
- ✅ RBAC authorization enabled
- ✅ Soft delete enabled (90 days)
- ✅ Purge protection enabled
- ✅ Current user granted Administrator role
- ⚠️ Public access initially allowed (add private endpoints)

## Troubleshooting

### Issue: Key Vault name already exists
**Error:** `A vault with the same name already exists in deleted state`

**Solution:**
```bash
# Purge soft-deleted Key Vault
az keyvault purge --name <kv-name>

# Or recover it
az keyvault recover --name <kv-name>
```

### Issue: Storage account name not available
**Error:** `The storage account name is not available`

**Solution:**
- Storage account names are globally unique
- Run `terraform destroy` and `terraform apply` to generate new random suffix
- Or manually specify suffix in variables

### Issue: Insufficient permissions
**Error:** `Authorization failed`

**Solution:**
- Ensure you have Owner or Contributor + User Access Administrator roles
- Check subscription-level permissions
- Verify Azure CLI is authenticated to correct subscription

## Maintenance

### Updating Bootstrap Infrastructure
```bash
# Always review changes before applying
terraform plan -var-file="bootstrap.tfvars"
terraform apply -var-file="bootstrap.tfvars"
```

### Destroying Bootstrap (⚠️ DANGEROUS)
```bash
# This will delete ALL state storage and Key Vaults
# Only do this if you're sure all regional infrastructure is destroyed first
terraform destroy -var-file="bootstrap.tfvars"
```

## Cost Estimation

Monthly costs (approximate):
- Storage Account (GRS): **~$20/month**
- Key Vault (Standard): **~$5/month**
- DDoS Protection Plan: **$2,944/month** (if enabled)

**Total without DDoS:** ~$25/month
**Total with DDoS:** ~$2,969/month

> **Note:** DDoS Protection Standard is expensive. Only enable if required for production workloads exposed to internet.

## Files

- `backend.tf`: Local backend configuration (bootstrap only)
- `main.tf`: Resource definitions
- `variables.tf`: Input variables
- `outputs.tf`: Output values
- `bootstrap.tfvars.example`: Example configuration file
- `README.md`: This file

## Next Steps

After bootstrap completes successfully:
1. ✅ Proceed to Session 2: Networking Modules
2. 📝 Save `bootstrap-outputs.json` for reference
3. 🔒 Store `bootstrap.tfvars` securely (DO NOT commit to Git)
4. 📋 Update regional backend configurations

---

**Created:** November 2025  
**Terraform Version:** >= 1.10.3  
**Provider Version:** azurerm ~> 4.51.0
