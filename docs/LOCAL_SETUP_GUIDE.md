# LOCAL_SETUP_GUIDE.md

Complete guide to set up your local development environment for Azure Terraform infrastructure management.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Installation & Setup](#installation--setup)
3. [Tools Overview](#tools-overview)
4. [Available Make Commands](#available-make-commands)
5. [Code Quality & Validation Workflow](#code-quality--validation-workflow)
6. [Configuration Files](#configuration-files)
7. [Troubleshooting](#troubleshooting)
8. [Quick Start Checklist](#quick-start-checklist)

---

## Prerequisites

- **Linux** with `brew` or equivalent package manager
- **Python 3.8+** installed
- **Git** installed
- **Azure CLI** installed (for Azure authentication)
- ~2 GB free disk space

> **Note**: The Makefile uses `brew` for installation on macOS. Linux users should adapt commands to use `apt-get`, `yum`, etc.

---

## Installation & Setup

### Step 1: Install Required Tools

Run the following command to automatically install all required tools:

```bash
make install-tools
```

This command will install:
- **Terraform** — Infrastructure as Code tool
- **TFLint** — Terraform linter for best practices
- **Checkov** — Security scanning for IaC
- **Pre-commit** — Git hooks framework
- **Azure CLI** — Azure cloud management CLI

**Alternatively, install manually:**

#### Terraform
```bash
# macOS
brew install terraform

# Linux (Ubuntu/Debian)
sudo apt-get update && sudo apt-get install -y terraform

# Verify installation
terraform --version
```

#### TFLint
```bash
# macOS
brew install tflint

# Linux
curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash

# Verify installation
tflint --version
```

#### Checkov
```bash
# Install via pip
pip3 install checkov

# Verify installation
checkov --version
```

#### Pre-commit
```bash
# Install via pip
pip3 install pre-commit

# Verify installation
pre-commit --version
```

#### Azure CLI
```bash
# macOS
brew install azure-cli

# Linux
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Verify installation
az --version
```

### Step 2: Set Up Git Pre-commit Hooks

Run the following command to install git hooks:

```bash
make setup-hooks
```

This will automatically run code quality checks before each commit:
- Terraform format
- Terraform validation
- TFLint linting
- Checkov security scanning
- Git hooks (trailing whitespace, YAML validation)

**Manually set up:**
```bash
cd /path/to/azure-terraform-modules2
pre-commit install
pre-commit install --hook-type commit-msg
```

### Step 3: Verify Installation

```bash
# Check all tools
terraform --version
tflint --version
checkov --version
pre-commit --version
az --version
```

---

## Tools Overview

### 1. Terraform
**Purpose**: Infrastructure as Code tool for provisioning Azure resources.

**Key files**:
- `*.tf` — Terraform configuration files
- `terraform.tfvars` — Variable values
- `.terraform.lock.hcl` — Dependency lock file

**Common commands**:
```bash
terraform init          # Initialize Terraform working directory
terraform validate      # Validate configuration syntax
terraform plan          # Preview infrastructure changes
terraform apply         # Apply infrastructure changes
terraform destroy       # Destroy managed infrastructure
terraform fmt           # Format Terraform files
```

**Usage in repo**:
```bash
cd environments/canada-central/prod
terraform init
terraform plan
```

---

### 2. TFLint
**Purpose**: Linter for Terraform configurations that enforces best practices and naming conventions.

**Config file**: `.tflint.hcl`

**Key rules enforced**:
- `azurerm_resource_missing_tags` — Ensures resources have required tags (Environment, ManagedBy, Project)
- `azurerm_storage_account_name_convention` — Storage account naming standards
- `terraform_naming_convention` — Enforce snake_case variable/resource names
- `terraform_documented_outputs` — Outputs must have descriptions
- `terraform_documented_variables` — Variables must have descriptions
- `terraform_required_providers` — Specify required provider versions
- `terraform_module_pinned_source` — Pin module versions

**Usage**:
```bash
# Initialize TFLint plugins
tflint --init

# Lint specific directory
tflint modules/networking/hub-vnet

# Lint all Terraform files
tflint --config=.tflint.hcl .

# Using make command
make lint
```

**Example output**:
```
1 issue(s) found:

Error: azurerm_resource_missing_tags (azurerm_resource_missing_tags)

  on modules/compute/aks-cluster/main.tf line 15:
   15: resource "azurerm_kubernetes_cluster" "aks" {

Missing required tags: Environment, ManagedBy
```

**Fix**: Add required tags to resource blocks:
```terraform
tags = {
  Environment = "prod"
  ManagedBy   = "terraform"
  Project     = "azure-infrastructure"
}
```

---

### 3. Checkov
**Purpose**: Static code analysis and security scanning for Infrastructure as Code.

**Config file**: `.checkov.yaml`

**Key security checks**:
- CKV_AZURE_3: Ensure logging for Azure Key Vault is enabled
- CKV_AZURE_14: Ensure that Storage blobs restrict public access
- CKV_AZURE_32: Ensure that Key Vault enables purge protection
- CKV_AZURE_43: Ensure that Azure Firewall is enabled in Hub networks
- CKV_AZURE_63: Ensure that SQL servers do not allow ingress 0.0.0.0/0 (root)

**Severity levels**:
- **CRITICAL** — Hard fail (blocks CI/CD)
- **HIGH** — Hard fail (blocks CI/CD)
- **MEDIUM** — Soft fail (warning only)
- **LOW** — Soft fail (warning only)

**Usage**:
```bash
# Scan Terraform code
checkov -d . --config-file .checkov.yaml

# Scan specific directory
checkov -d modules/security --config-file .checkov.yaml

# Scan Terraform plan (JSON output)
terraform plan -json | checkov -f -

# Using make command
make security
```

**Example output**:
```
Check: CKV_AZURE_1: "Ensure that Virtual Machines use managed disks"
	PASSED for resource: azurerm_linux_virtual_machine.vm
	File: /path/to/main.tf:10-25

Check: CKV_AZURE_14: "Ensure that Storage blobs restrict public access"
	FAILED for resource: azurerm_storage_account.main
	File: /path/to/main.tf:1-9
```

---

### 4. Pre-commit Hooks
**Purpose**: Automatically run checks before committing code.

**Config file**: `.pre-commit-config.yaml`

**Hooks configured**:
- `terraform_fmt` — Auto-format Terraform files
- `terraform_validate` — Validate syntax
- `terraform_docs` — Generate documentation
- `terraform_tflint` — Run TFLint
- `terraform_checkov` — Run Checkov
- `trailing-whitespace` — Remove trailing spaces
- `end-of-file-fixer` — Fix end-of-file newlines
- `check-yaml` — Validate YAML syntax

**Usage**:
```bash
# Hooks run automatically on git commit
git add modules/networking/hub-vnet/main.tf
git commit -m "Add hub vnet"
# Pre-commit hooks will run automatically

# Run manually on all files
pre-commit run --all-files

# Run specific hook
pre-commit run terraform_fmt --all-files

# Bypass hooks (not recommended)
git commit --no-verify -m "Emergency commit"
```

**Example flow**:
```
$ git commit -m "Update hub vnet"
Trim Trailing Whitespace.....................................................Passed
Fix End of Files...........................................................Passed
Check Yaml........................................................Passed
Terraform Format..........................................................Failed
- Hook id: terraform_fmt

Fix End of Files...........................................................Passed
Terraform Validate......................................................Passed
TFLint..................................................................Failed
- Hook id: terraform_tflint

Error: azurerm_resource_missing_tags

→ Fix the issues, stage, and commit again
```

---

## Available Make Commands

### Setup Commands

```bash
make install-tools      # Install all required tools (terraform, tflint, checkov, etc.)
make setup-hooks        # Install git pre-commit hooks
make help               # Display all available commands
```

### Code Quality & Validation

```bash
make validate           # Validate Terraform configuration syntax
make format             # Auto-format all Terraform files
make lint               # Run TFLint on all .tf files
make security           # Run Checkov security scanning
make test-cidr          # Validate CIDR ranges and allocations
```

**Example**: Run all code quality checks before committing

```bash
make format lint security validate
```

### Initialization & Planning

```bash
make init               # Initialize Terraform (terraform init)
make plan-stage1        # Create execution plan for Stage 1 deployment
make plan-stage2        # Create execution plan for Stage 2 deployment
```

### Deployment Commands

```bash
make bootstrap          # Create Terraform state storage (one-time setup)
make apply-stage1       # Apply Stage 1 infrastructure
make apply-stage2       # Apply Stage 2 infrastructure (with firewall rules)
```

### Infrastructure Information

```bash
make output             # Show Terraform outputs (IP addresses, endpoints, etc.)
make state-list         # List all resources in state
make state-show RESOURCE=module.aks_cluster  # Show specific resource details
make refresh            # Refresh Terraform state from Azure
```

### Getting Credentials & Information

```bash
make get-aks-credentials  # Get AKS cluster credentials for kubectl
make get-istio-ip         # Get Istio internal load balancer IP
```

### Maintenance & Cleanup

```bash
make backup-state       # Backup Terraform state
make clean              # Clean .terraform dirs and plan files
make test               # Run smoke tests
```

### Destruction (⚠️ DANGEROUS)

```bash
make destroy            # Destroy ALL managed infrastructure (requires confirmation)
```

### CI/CD Commands

```bash
make ci-validate        # Run all CI validation checks (format + validate + lint + security)
make ci-plan            # CI: Create execution plan
make ci-apply           # CI: Apply changes
```

### Environment-Specific Examples

```bash
make example-dev        # Deploy to dev environment
make example-prod       # Deploy to prod environment

# Or manually specify region and environment
make REGION=canada-central ENV=prod apply-stage1
make REGION=canada-central ENV=dev plan-stage1
```

---

## Code Quality & Validation Workflow

### Before Every Commit

1. **Format code**:
   ```bash
   make format
   ```

2. **Validate syntax**:
   ```bash
   make validate
   ```

3. **Run linting**:
   ```bash
   make lint
   ```

4. **Run security scan**:
   ```bash
   make security
   ```

5. **Commit changes**:
   ```bash
   git add .
   git commit -m "Update hub vnet configuration"
   ```

**Shortcut** (run all checks):
```bash
make ci-validate
```

### Before Every Plan/Apply

1. **Create plan**:
   ```bash
   make plan-stage1
   ```

2. **Review plan**:
   ```bash
   terraform show tfplan-stage1
   ```

3. **Apply if safe**:
   ```bash
   make apply-stage1
   ```

### Typical Development Cycle

```bash
# 1. Make changes to Terraform files
vim modules/networking/hub-vnet/main.tf

# 2. Format and validate
make format validate

# 3. Run code quality checks
make lint security

# 4. Commit changes (pre-commit hooks will run)
git add modules/networking/hub-vnet/main.tf
git commit -m "Update hub vnet with new subnet"

# 5. Test locally in dev environment
cd environments/canada-central/dev
terraform init
terraform plan

# 6. If satisfied, push to Git
git push origin feature-branch

# 7. Review and merge PR
# (CI pipeline will run make ci-validate automatically)

# 8. Deploy to production
cd environments/canada-central/prod
terraform plan -out=tfplan
terraform apply tfplan
```

---

## Configuration Files

### .tflint.hcl (TFLint Configuration)

Located at the root of the repository. Key settings:

```hcl
config {
  module = true              # Lint modules
  force = false              # Don't force-exit on warnings
  disabled_by_default = false
}

# Azure-specific rules
plugin "azurerm" {
  enabled = true
  version = "0.25.1"
}

# Terraform best practice rules
rule "azurerm_resource_missing_tags" {
  enabled = true
  tags = ["Environment", "ManagedBy", "Project"]  # Required tags
}

rule "terraform_naming_convention" {
  enabled = true
  format = "snake_case"  # Variables/resources must be snake_case
}
```

**To modify rules**, edit `.tflint.hcl` and test:
```bash
tflint --init
tflint .
```

---

### .checkov.yaml (Checkov Configuration)

Located at the root of the repository. Key settings:

```yaml
framework:
  - terraform
  - terraform_plan

directory:
  - modules/
  - environments/

# Skip specific checks with justification
skip-check:
  - CKV_AZURE_33  # Storage uses private endpoints instead
  - CKV_AZURE_35  # Key Vault firewall via private endpoint

# Severity levels that block CI/CD
hard-fail-on:
  - CRITICAL
  - HIGH

# Severity levels that only warn
soft-fail-on:
  - MEDIUM
  - LOW
```

**To suppress a check for a resource**, add annotation:
```terraform
resource "azurerm_storage_account" "example" {
  # checkov:skip=CKV_AZURE_33: Storage uses private endpoints
  
  name              = "example"
  # ... other config
}
```

---

### .pre-commit-config.yaml (Pre-commit Configuration)

Located at the root of the repository. Defines which hooks run on commit.

**To add a new hook**, edit the file and reinstall:
```bash
pre-commit install
pre-commit run --all-files
```

**To skip hooks for a commit**:
```bash
git commit --no-verify -m "Emergency fix"
```

---

## Troubleshooting

### Issue: `command not found: terraform`

**Solution**: Ensure Terraform is installed and in PATH
```bash
brew install terraform
terraform --version
```

### Issue: TFLint fails with "plugin not found"

**Solution**: Initialize TFLint plugins
```bash
tflint --init
```

### Issue: Pre-commit hook fails on format

**Solution**: Pre-commit auto-formats on commit failure. Stage changes and retry:
```bash
git add .
git commit -m "message"  # Will fail and auto-format
git add .
git commit -m "message"  # Will pass
```

### Issue: Checkov fails with "CRITICAL" or "HIGH" severity

**Solution 1**: Fix the security issue (recommended)
```bash
# Read the check documentation
checkov -d modules/ --check CKV_AZURE_14

# Fix the resource configuration
vim modules/storage/storage-account/main.tf
```

**Solution 2**: Skip check with justification (use sparingly)
```yaml
# In .checkov.yaml
skip-check:
  - CKV_AZURE_14  # [Justification: Using private endpoints for access]
```

### Issue: `make plan` errors with backend issues

**Solution**: Ensure backend is configured and initialized
```bash
cd environments/canada-central/prod
rm -rf .terraform .terraform.lock.hcl
terraform init
terraform plan
```

### Issue: Pre-commit takes too long

**Solution**: Pre-commit can be slow on large repos. Check what's running:
```bash
pre-commit run --all-files --verbose
```

To skip hooks temporarily:
```bash
git commit --no-verify -m "message"
```

### Issue: Azure CLI authentication fails

**Solution**: Log in to Azure
```bash
az login
az account set --subscription "subscription-id"
az account show
```

---

## Quick Start Checklist

- [ ] Clone repository: `git clone <repo-url>`
- [ ] Install tools: `make install-tools`
- [ ] Set up hooks: `make setup-hooks`
- [ ] Verify tools: `terraform --version && tflint --version && checkov --version`
- [ ] Authenticate with Azure: `az login`
- [ ] Validate configuration: `make validate`
- [ ] Run code quality: `make ci-validate`
- [ ] Create dev plan: `make REGION=canada-central ENV=dev plan-stage1`
- [ ] Review plan output
- [ ] Read `docs/SAFE_TERRAFORM_APPLY.md` before any `terraform apply`
- [ ] Ready to deploy!

---

## Next Steps

1. Read [SAFE_TERRAFORM_APPLY.md](./SAFE_TERRAFORM_APPLY.md) before running `terraform apply`
2. Review [DEPLOYMENT.md](./DEPLOYMENT.md) for deployment process
3. Check [ARCHITECTURE.md](./ARCHITECTURE.md) for network topology
4. Review [MODULES.md](./MODULES.md) for available modules

---

## Additional Resources

- [Terraform Documentation](https://www.terraform.io/docs)
- [TFLint GitHub](https://github.com/terraform-linters/tflint)
- [Checkov Documentation](https://www.checkov.io/)
- [Pre-commit Framework](https://pre-commit.com/)
- [Azure Terraform Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest)

---

**Last updated**: November 13, 2025
