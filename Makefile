# Makefile for Terraform Infrastructure Management
# Usage: make <target>

.PHONY: help bootstrap validate format lint security plan apply destroy clean test docs

# Default target
.DEFAULT_GOAL := help

# Variables
REGION ?= canada-central
ENV ?= prod
TF_DIR = environments/$(REGION)/$(ENV)

# Colors for output
GREEN  := \033[0;32m
YELLOW := \033[0;33m
RED    := \033[0;31m
NC     := \033[0m # No Color

##@ General

help: ## Display this help message
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Setup

install-tools: ## Install required tools (terraform, tflint, checkov, pre-commit)
	@echo "$(GREEN)Installing required tools...$(NC)"
	@command -v terraform >/dev/null 2>&1 || { echo "Installing Terraform..."; brew install terraform; }
	@command -v tflint >/dev/null 2>&1 || { echo "Installing TFLint..."; brew install tflint; }
	@command -v checkov >/dev/null 2>&1 || { echo "Installing Checkov..."; pip3 install checkov; }
	@command -v pre-commit >/dev/null 2>&1 || { echo "Installing Pre-commit..."; pip3 install pre-commit; }
	@command -v az >/dev/null 2>&1 || { echo "Installing Azure CLI..."; brew install azure-cli; }
	@echo "$(GREEN)✓ All tools installed!$(NC)"

setup-hooks: ## Setup git pre-commit hooks
	@echo "$(GREEN)Setting up pre-commit hooks...$(NC)"
	@pre-commit install
	@pre-commit install --hook-type commit-msg
	@echo "$(GREEN)✓ Pre-commit hooks installed!$(NC)"

bootstrap: ## Run bootstrap to create state storage
	@echo "$(GREEN)Running bootstrap...$(NC)"
	@cd 0-bootstrap && terraform init && terraform apply -var-file=bootstrap.tfvars
	@echo "$(GREEN)✓ Bootstrap complete!$(NC)"

##@ Code Quality

validate: ## Validate Terraform configuration
	@echo "$(GREEN)Validating Terraform...$(NC)"
	@cd $(TF_DIR) && terraform init -backend=false && terraform validate
	@echo "$(GREEN)✓ Validation successful!$(NC)"

format: ## Format Terraform files
	@echo "$(GREEN)Formatting Terraform files...$(NC)"
	@terraform fmt -recursive .
	@echo "$(GREEN)✓ Formatting complete!$(NC)"

lint: ## Run TFLint
	@echo "$(GREEN)Running TFLint...$(NC)"
	@tflint --init
	@find . -type f -name "*.tf" -not -path "*/.terraform/*" | xargs dirname | sort -u | xargs -I {} tflint {}
	@echo "$(GREEN)✓ Linting complete!$(NC)"

security: ## Run Checkov security scan
	@echo "$(GREEN)Running Checkov security scan...$(NC)"
	@checkov -d . --config-file .checkov.yaml
	@echo "$(GREEN)✓ Security scan complete!$(NC)"

docs: ## Generate Terraform documentation
	@echo "$(GREEN)Generating Terraform documentation...$(NC)"
	@terraform-docs markdown table --output-file README.md --output-mode inject modules/
	@echo "$(GREEN)✓ Documentation generated!$(NC)"

##@ Deployment - Stage 1

init: ## Initialize Terraform
	@echo "$(GREEN)Initializing Terraform...$(NC)"
	@cd $(TF_DIR) && terraform init
	@echo "$(GREEN)✓ Initialization complete!$(NC)"

plan-stage1: init ## Create Stage 1 execution plan (before Istio)
	@echo "$(GREEN)Creating Stage 1 plan...$(NC)"
	@cd $(TF_DIR) && terraform plan -var="deployment_stage=stage1" -out=tfplan-stage1
	@echo "$(GREEN)✓ Plan created: tfplan-stage1$(NC)"

apply-stage1: ## Apply Stage 1 configuration
	@echo "$(YELLOW)Applying Stage 1 configuration...$(NC)"
	@cd $(TF_DIR) && terraform apply tfplan-stage1
	@echo "$(GREEN)✓ Stage 1 applied successfully!$(NC)"
	@echo "$(YELLOW)Next steps:$(NC)"
	@echo "  1. Get AKS credentials: make get-aks-credentials"
	@echo "  2. Get Istio LB IP: make get-istio-ip"
	@echo "  3. Update terraform.tfvars with istio_internal_lb_ip"
	@echo "  4. Apply Stage 2: make apply-stage2"

get-aks-credentials: ## Get AKS credentials
	@echo "$(GREEN)Getting AKS credentials...$(NC)"
	@cd $(TF_DIR) && bash ../../../scripts/get-aks-credentials.sh
	@echo "$(GREEN)✓ Credentials configured!$(NC)"

get-istio-ip: ## Get Istio internal load balancer IP
	@echo "$(GREEN)Getting Istio internal LB IP...$(NC)"
	@cd $(TF_DIR) && bash ../../../scripts/get-istio-lb-ip.sh
	@echo "$(YELLOW)Update terraform.tfvars with this IP before Stage 2$(NC)"

##@ Deployment - Stage 2

plan-stage2: ## Create Stage 2 execution plan (after Istio)
	@echo "$(GREEN)Creating Stage 2 plan...$(NC)"
	@cd $(TF_DIR) && terraform plan -var="deployment_stage=stage2" -out=tfplan-stage2
	@echo "$(GREEN)✓ Plan created: tfplan-stage2$(NC)"

apply-stage2: ## Apply Stage 2 configuration (with UDR + DNAT)
	@echo "$(YELLOW)Applying Stage 2 configuration...$(NC)"
	@cd $(TF_DIR) && terraform apply tfplan-stage2
	@echo "$(GREEN)✓ Stage 2 applied successfully!$(NC)"
	@echo "$(GREEN)Deployment complete! Run smoke tests: make test$(NC)"

##@ Testing

test: ## Run smoke tests
	@echo "$(GREEN)Running smoke tests...$(NC)"
	@bash scripts/validate-deployment.sh
	@echo "$(GREEN)✓ All tests passed!$(NC)"

test-cidr: ## Validate CIDR allocations
	@echo "$(GREEN)Validating CIDR ranges...$(NC)"
	@python3 scripts/validate-cidr.py
	@echo "$(GREEN)✓ CIDR validation complete!$(NC)"

##@ Maintenance

state-list: ## List Terraform state resources
	@cd $(TF_DIR) && terraform state list

state-show: ## Show specific resource state (usage: make state-show RESOURCE=module.aks_cluster)
	@cd $(TF_DIR) && terraform state show $(RESOURCE)

refresh: ## Refresh Terraform state
	@echo "$(GREEN)Refreshing Terraform state...$(NC)"
	@cd $(TF_DIR) && terraform refresh
	@echo "$(GREEN)✓ State refreshed!$(NC)"

output: ## Show Terraform outputs
	@cd $(TF_DIR) && terraform output

backup-state: ## Backup Terraform state
	@echo "$(GREEN)Backing up Terraform state...$(NC)"
	@bash scripts/backup-terraform-state.sh
	@echo "$(GREEN)✓ Backup complete!$(NC)"

##@ Cleanup

clean: ## Clean Terraform cache and plans
	@echo "$(YELLOW)Cleaning Terraform cache...$(NC)"
	@find . -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null || true
	@find . -type f -name "tfplan*" -delete 2>/dev/null || true
	@find . -type f -name ".terraform.lock.hcl" -delete 2>/dev/null || true
	@echo "$(GREEN)✓ Cleanup complete!$(NC)"

destroy: ## Destroy Terraform-managed infrastructure (⚠️  DANGEROUS)
	@echo "$(RED)⚠️  WARNING: This will destroy ALL infrastructure!$(NC)"
	@echo "Type 'yes' to confirm: " && read -r confirm && [ "$$confirm" = "yes" ]
	@cd $(TF_DIR) && terraform destroy -auto-approve
	@echo "$(RED)Infrastructure destroyed!$(NC)"

##@ CI/CD

ci-validate: format validate lint security ## Run all CI validation checks
	@echo "$(GREEN)✓ All CI checks passed!$(NC)"

ci-plan: init plan-stage1 ## CI: Create execution plan
	@echo "$(GREEN)✓ CI plan complete!$(NC)"

ci-apply: apply-stage1 ## CI: Apply changes (requires approval)
	@echo "$(GREEN)✓ CI apply complete!$(NC)"

##@ Examples

example-canada-dev: ## Deploy Canada Central Dev
	@$(MAKE) REGION=canada-central ENV=dev apply-stage1

example-canada-prod: ## Deploy Canada Central Prod
	@$(MAKE) REGION=canada-central ENV=prod apply-stage1

example-eastus2-prod: ## Deploy East US 2 Prod
	@$(MAKE) REGION=eastus2 ENV=prod apply-stage1