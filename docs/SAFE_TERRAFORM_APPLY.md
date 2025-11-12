## SAFE_TERRAFORM_APPLY.md

Purpose
-------
This document lists minimal safety checks and best practices to follow before running `terraform apply` in order to avoid accidentally affecting existing network infrastructure (hub and spoke VNets) in the same Azure region but different resource groups.

Scope
-----
Applies to Terraform runs that will create or modify resources in the Canada Central region. It assumes you have a hub VNet with CIDR 10.0.0.0/16 and a spoke VNet with CIDR 10.1.0.0/16. Resources will be created in separate resource groups. The guidance also applies when you have other VNets in the same subscription/region.

Quick summary
-------------
- Terraform only manages resources defined in your configuration and tracked in the Terraform state.
- Creating resources in a different resource group does not automatically change resources in other resource groups.
- Be careful with name collisions, overlapping CIDR ranges (if you plan to peer networks), and accidentally targeting the wrong subscription or state file.

Pre-apply checklist (do these every time)
--------------------------------------
1. Provider & subscription
   - Ensure your `provider "azurerm"` block targets the intended subscription and tenant (or use environment variables: `ARM_SUBSCRIPTION_ID`, `ARM_TENANT_ID`).

2. Backend & state
   - Use a remote, state-locked backend (recommended: `azurerm` backend with storage account + blob container).
   - Confirm you are using the correct state file / workspace (terraform workspace show).

3. Inspect the plan
   - Run `terraform init`.
   - Run `terraform plan -out=plan.tfplan`.
   - Run `terraform show plan.tfplan` and review every create/update/destroy action.

4. Avoid managing existing resources unintentionally
   - If resources already exist and should be managed by Terraform, import them with `terraform import` instead of recreating.
   - If you only need to reference existing resources, use data sources (e.g. `data "azurerm_virtual_network"`).

5. Resource names and uniqueness
   - Confirm resource names (especially for storage accounts, DNS names, public IPs) won’t collide with existing ones. Some names must be globally unique.
   - Resource names are often scoped by resource group; still verify uniqueness where required.

6. Network CIDR and peering
   - Your hub (10.0.0.0/16) and spoke (10.1.0.0/16) are non-overlapping — good for future peering.
   - Do not attempt to peer VNets that have overlapping address spaces; Azure will reject the peering.
   - If you plan to connect to existing networks, verify their address spaces first.

7. Protect critical resources
   - Use `lifecycle { prevent_destroy = true }` on resources you never want deleted.
   - Use `ignore_changes` where appropriate for properties changed outside Terraform.

8. Separation of environments
   - Keep separate state files or Terraform workspaces per environment (dev/stage/prod) or per logical boundary to avoid accidental cross-environment changes.

9. Test before production
   - Apply changes in a test subscription or a non-production resource group first.

Useful commands
---------------
```bash
terraform init
terraform validate
terraform plan -out=plan.tfplan
terraform show plan.tfplan
terraform apply plan.tfplan
```

Example: provider block targeting a subscription
------------------------------------------------
```terraform
provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
}
```

Reference existing VNet instead of recreating
--------------------------------------------
```terraform
data "azurerm_virtual_network" "existing_hub" {
  name                = "existing-hub-vnet-name"
  resource_group_name = "existing-hub-rg"
}
```

When things can go wrong (risks)
-------------------------------
- Terraform will try to create a resource that already exists (causes conflict) if not imported.
- Misconfigured provider/subscription may run against the wrong subscription and show unexpected diffs.
- Overlapping CIDRs will block peering and can cause routing conflicts if you attempt network connectivity.

Final checklist before pressing apply
-----------------------------------
- Confirm subscription and backend.
- Confirm plan shows only intended creates/updates and no unexpected destroys.
- Confirm names and CIDRs do not conflict with existing infra you plan to connect.
- If unsure, run in a test environment first.

Notes
-----
This is a concise, practical checklist — adapt it to your team's policies (naming conventions, tagging, approval gates, CI pipelines). If you want, I can add a small example Terraform layout for isolated state per environment or an example backend configuration for Azure.

---
File created by automated assistant to summarize safety checks for `terraform apply`.
