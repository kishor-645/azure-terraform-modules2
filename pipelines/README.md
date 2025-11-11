# Azure DevOps CI/CD Pipelines

Complete CI/CD automation for Terraform infrastructure deployment with security scanning and Key Vault integration.

## Pipeline Files

### Main Pipelines

- **`azure-pipelines-pr-validation.yml`**: PR validation pipeline with Checkov and TFLint scans
  - Runs automatically on Pull Requests
  - Validates code quality and security
  - Does not deploy infrastructure

- **`azure-pipelines-deployment.yml`**: Deployment pipeline with security scans and Key Vault secret retrieval
  - Runs on merge to main/develop branches
  - Validates code with Checkov and TFLint
  - Retrieves secrets from Azure Key Vault
  - Deploys infrastructure

### Additional Pipelines

- **`terraform-destroy.yml`**: Manual destruction pipeline (use with caution)

## Prerequisites

- Azure DevOps service connection
- Azure Key Vault with required secrets (see DEPLOYMENT-GUIDE.md)
- Variable groups configured (terraform-prod-variables, terraform-dev-variables)
- Environments created (dev, prod)

## Usage

1. **PR Validation**: Automatically runs on Pull Requests
2. **Deployment**: Runs on merge to main/develop branches

See [DEPLOYMENT-GUIDE.md](../DEPLOYMENT-GUIDE.md) for detailed setup and usage instructions.

## Features

- ✅ Checkov security scanning
- ✅ TFLint code linting
- ✅ Key Vault secret retrieval
- ✅ Automatic secret cleanup
- ✅ Environment-specific deployments
- ✅ Approval gates for production

v2.0.0 (November 2025)
