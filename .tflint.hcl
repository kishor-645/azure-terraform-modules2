# TFLint Configuration for Azure Infrastructure
# https://github.com/terraform-linters/tflint

config {
  module              = true
  force               = false
  disabled_by_default = false
}

plugin "azurerm" {
  enabled = true
  version = "0.25.1"
  source  = "github.com/terraform-linters/tflint-ruleset-azurerm"
}

plugin "terraform" {
  enabled = true
  version = "0.5.0"
  source  = "github.com/terraform-linters/tflint-ruleset-terraform"
  preset  = "recommended"
}

# Azure-specific rules
rule "azurerm_resource_missing_tags" {
  enabled = true
  tags    = ["Environment", "ManagedBy", "Project"]
}

rule "azurerm_storage_account_name_convention" {
  enabled = true
}

rule "azurerm_virtual_machine_scale_set_extensions_time_budget" {
  enabled = true
}

# Terraform best practices
rule "terraform_comment_syntax" {
  enabled = true
}

rule "terraform_deprecated_index" {
  enabled = true
}

rule "terraform_deprecated_interpolation" {
  enabled = true
}

rule "terraform_documented_outputs" {
  enabled = true
}

rule "terraform_documented_variables" {
  enabled = true
}

rule "terraform_module_pinned_source" {
  enabled = true
}

rule "terraform_naming_convention" {
  enabled = true
  format  = "snake_case"
}

rule "terraform_required_providers" {
  enabled = true
}

rule "terraform_required_version" {
  enabled = true
}

rule "terraform_standard_module_structure" {
  enabled = true
}

rule "terraform_typed_variables" {
  enabled = true
}

rule "terraform_unused_declarations" {
  enabled = true
}

rule "terraform_unused_required_providers" {
  enabled = true
}

rule "terraform_workspace_remote" {
  enabled = false  # We use Azure Storage backend
}