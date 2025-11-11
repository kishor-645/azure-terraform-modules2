# Spoke VNet Module
# Creates spoke VNet with 3 subnets

terraform {
  required_version = ">= 1.10.3"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.51.0"
    }
  }
}

# ========================================
# Spoke Virtual Network
# ========================================

resource "azurerm_virtual_network" "spoke" {
  name                = var.vnet_name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.address_spaces != null ? var.address_spaces : [var.address_space]

  tags = merge(
    var.tags,
    {
      VNetType = "Spoke"
      Purpose  = "AKS Workloads"
    }
  )
}

# ========================================
# Subnets (Dynamic; legacy compatibility)
# ========================================

locals {
  legacy_subnets = {
    # Maintain legacy identifiers so existing outputs remain meaningful
    aks_nodes = {
      name                                 = var.aks_node_pool_subnet_name
      address_prefixes                      = [var.aks_node_pool_subnet_cidr]
      service_endpoints                     = []
      private_endpoint_network_policies     = null
      private_link_service_network_policies = null
      delegations                           = []
    }
    private_endpoints = {
      name                                 = var.private_endpoints_subnet_name
      address_prefixes                      = [var.private_endpoints_subnet_cidr]
      service_endpoints                     = []
      private_endpoint_network_policies     = "Disabled"
      private_link_service_network_policies = null
      delegations                           = []
    }
    jumpbox = {
      name                                 = var.jumpbox_subnet_name
      address_prefixes                      = [var.jumpbox_subnet_cidr]
      service_endpoints                     = []
      private_endpoint_network_policies     = null
      private_link_service_network_policies = null
      delegations                           = []
    }
  }

  legacy_subnets_map = merge({}, local.legacy_subnets)
  subnets_source = merge(local.legacy_subnets_map, var.subnets != null ? var.subnets : {})

  # Normalize to ensure each value has a 'name'
  normalized_subnets = {
    for key, cfg in local.subnets_source :
    key => merge(
      cfg,
      {
        name = try(cfg.name, key)
      }
    )
  }
}

resource "azurerm_subnet" "spoke" {
  for_each = local.normalized_subnets

  name                 = each.value.name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = each.value.address_prefixes

  dynamic "delegation" {
    for_each = try(each.value.delegations, [])
    content {
      name = delegation.value.name
      service_delegation {
        name    = delegation.value.service_delegation.name
        actions = delegation.value.service_delegation.actions
      }
    }
  }

  service_endpoints = try(each.value.service_endpoints, [])

  # Network policy flags omitted for provider compatibility; set at calling modules as needed.
}
