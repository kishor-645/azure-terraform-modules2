# Canada Central Production Environment Configuration
# Copy this file to terraform.tfvars and update values

# ========================================
# Azure Region/Location
# ========================================
# Change this to deploy to a different region (e.g., eastus, westus2, uksouth)
location = "canadacentral"

# ========================================
# Azure Subscription & Tenant
# ========================================
subscription_id = "45e252f2-d253-4baa-9afd-57a4fbac93f4"
tenant_id       = "8c440439-38da-4b76-9de0-002f47f4e860"

# ========================================
# Resource Group Configuration
# ========================================
# These resource groups will be created manually and imported into Terraform
resource_group_name          = "rg-erp-cc-prod"
aks_node_resource_group_name = "rg-aks-canadacentral-prod-nodes"

# ========================================
# Storage and Registry Configuration
# ========================================
# Exact names without dynamic suffixes
container_registry_name = "acrerpccprod"
storage_account_name    = "sterpccprod"

# ========================================
# Deployment Configuration
# ========================================
deployment_stage = "stage1" # Options: stage1, stage2

# ========================================
# Kubernetes Configuration
# ========================================
kubernetes_version         = "1.33"
aks_admin_group_object_ids = ["8711b4ad-7b9c-4f4f-9972-841191901995"]

# ========================================
# AKS Node Pool Configuration
# ========================================
# System Node Pool
system_node_pool_vm_size   = "Standard_D4s_v5"
system_node_pool_min_count = 1
system_node_pool_max_count = 5

# User Node Pool
user_node_pool_vm_size   = "Standard_F16s_v2"
user_node_pool_min_count = 1
user_node_pool_max_count = 5

# ========================================
# Azure Firewall Configuration
# ========================================
firewall_threat_intel_mode = "Deny" # Options: Off, Alert, Deny
firewall_idps_mode         = "Deny" # Options: Off, Alert, Deny

# ========================================
# Istio Configuration
# ========================================
# Leave empty for stage1, will be populated after AKS deployment
istio_internal_lb_ip = ""

# ========================================
# Jumpbox Configuration
# ========================================
jumpbox_vm_size        = "Standard_B2s"
jumpbox_admin_username = "azureuser"
jumpbox_admin_password = "ChangeMe123!@#" # Use Azure Key Vault or secure variable

# ========================================
# Agent VM Configuration
# ========================================
agent_vm_size           = "Standard_B2s"
agent_vm_admin_username = "azureuser"
agent_vm_admin_password = "ChangeMe123!@#" # Use Azure Key Vault or secure variable

# ========================================
# PostgreSQL Configuration
# ========================================
postgresql_version               = "17"
postgresql_admin_login           = "master"
postgresql_admin_password        = "ChangeMe123!@#" # Use Azure Key Vault or secure variable
postgresql_sku_name              = "GP_Standard_D4s_v3"
postgresql_storage_mb            = 131072 # 128 GB
postgresql_backup_retention_days = 7

# ========================================
# Monitoring Configuration
# ========================================
log_analytics_retention_days = 30

# ========================================
# Additional Tags
# ========================================
additional_tags = {
  Owner      = "DevOps Team"
  CostCenter = "IT-Operations"
  Project    = "ERP-Infrastructure"
}
