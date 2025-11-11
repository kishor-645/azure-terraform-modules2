# Local Values and Data Sources

data "azurerm_client_config" "current" {}

data "azurerm_subscription" "current" {}

data "http" "cloudflare_ips_v4" {
  url = "https://www.cloudflare.com/ips-v4"
}

locals {
  environment = "prod"
  region      = "canadacentral"
  region_code = "cc"

  base_common_tags = {
    Environment  = "Production"
    Region       = "Canada Central"
    ManagedBy    = "Terraform"
    Project      = "ERP-Infrastructure"
    CostCenter   = "IT-Operations"
    DeployedDate = timestamp()
  }

  common_tags = merge(
    local.base_common_tags,
    var.additional_tags
  )

  naming_prefix = "erp-${local.region_code}-${local.environment}"

  # Single resource group for all resources
  rg_name = "rg-${local.naming_prefix}"

  # ==========================
  # Hub configuration (defaults + overrides)
  # ==========================

  default_hub_subnets = {
    firewall = {
      name             = "AzureFirewallSubnet"
      address_prefixes = ["10.0.1.0/26"]
    }
    firewall_management = {
      name             = "AzureFirewallManagementSubnet"
      address_prefixes = ["10.0.2.0/26"]
    }
    bastion = {
      name             = "AzureBastionSubnet"
      address_prefixes = ["10.0.3.0/27"]
    }
    shared_services = {
      name             = "SharedServicesSubnet"
      address_prefixes = ["10.0.4.0/24"]
    }
    private_endpoints = {
      name                                 = "PrivateEndpointsSubnet"
      address_prefixes                      = ["10.0.5.0/24"]
      private_endpoint_network_policies     = "Disabled"
    }
  }

  default_hub_network = {
    vnet_name      = "vnet-hub-${local.region}-${local.environment}"
    address_spaces = ["10.0.0.0/16"]
    subnets        = jsondecode(jsonencode(local.default_hub_subnets))
    ddos_protection_plan_id = null
  }

  user_hub_network = var.hub_network

  hub_network = {
    vnet_name = coalesce(
      try(local.user_hub_network.vnet_name, null),
      local.default_hub_network.vnet_name
    )
    address_spaces = coalesce(
      try(local.user_hub_network.address_spaces, null),
      local.default_hub_network.address_spaces
    )
    ddos_protection_plan_id = try(local.user_hub_network.ddos_protection_plan_id, null)
    subnets = try(local.user_hub_network.subnets, null) != null ? jsondecode(jsonencode(local.user_hub_network.subnets)) : jsondecode(jsonencode(local.default_hub_network.subnets))
  }

  # ==========================
  # Spoke configuration (defaults + overrides)
  # ==========================

  default_spoke_key = "primary"

  default_spoke_subnets = {
    aks_nodes = {
      name             = "AKSNodeSubnet"
      address_prefixes = ["10.1.0.0/20"]
    }
    private_endpoints = {
      name                                 = "PrivateEndpointsSubnet"
      address_prefixes                      = ["10.1.16.0/24"]
      private_endpoint_network_policies     = "Disabled"
    }
    jumpbox = {
      name             = "JumpboxSubnet"
      address_prefixes = ["10.1.17.0/27"]
    }
  }

  default_spoke_network = {
    vnet_name      = "vnet-spoke-${local.region}-${local.environment}"
    address_spaces = ["10.1.0.0/16"]
    subnets        = jsondecode(jsonencode(local.default_spoke_subnets))
    tags           = {}
  }

  user_default_spoke = var.default_spoke_network

  resolved_default_spoke = {
    vnet_name = coalesce(
      try(local.user_default_spoke.vnet_name, null),
      local.default_spoke_network.vnet_name
    )
    address_spaces = coalesce(
      try(local.user_default_spoke.address_spaces, null),
      local.default_spoke_network.address_spaces
    )
    subnets = try(local.user_default_spoke.subnets, null) != null ? jsondecode(jsonencode(local.user_default_spoke.subnets)) : jsondecode(jsonencode(local.default_spoke_network.subnets))
    tags = merge(
      {},
      try(local.default_spoke_network.tags, {}),
      try(local.user_default_spoke.tags, {})
    )
  }

  user_spoke_map = var.spoke_vnets != null ? var.spoke_vnets : {}
  default_spoke_map = merge({}, { (local.default_spoke_key) = local.resolved_default_spoke })

  raw_spokes = merge(local.default_spoke_map, local.user_spoke_map)

  normalized_spokes = {
    for key, cfg in local.raw_spokes :
    key => {
      vnet_name = coalesce(
        try(cfg.vnet_name, null),
        "vnet-${key}-${local.region}-${local.environment}"
      )
      address_spaces = coalesce(
        try(cfg.address_spaces, null),
        key == local.default_spoke_key ? local.resolved_default_spoke.address_spaces : null
      )
      subnets = try(cfg.subnets, null) != null ? cfg.subnets : (key == local.default_spoke_key ? local.resolved_default_spoke.subnets : {})
      tags = merge(local.common_tags, try(cfg.tags, {}))
    }
  }

  spoke_keys = keys(local.normalized_spokes)
  default_binding_spoke_key = length(local.spoke_keys) > 0 ? (contains(local.spoke_keys, local.default_spoke_key) ? local.default_spoke_key : local.spoke_keys[0]) : null

  default_network_bindings = {
    aks = {
      vnet_key   = local.default_binding_spoke_key
      subnet_key = "aks_nodes"
    }
    private_endpoints = {
      vnet_key   = local.default_binding_spoke_key
      subnet_key = "private_endpoints"
    }
    jumpbox = {
      vnet_key   = local.default_binding_spoke_key
      subnet_key = "jumpbox"
    }
  }

  network_bindings = merge(
    local.default_network_bindings,
    var.network_bindings
  )

  # ==========================
  # General cluster/network settings
  # ==========================

  aks_cluster_name = "aks-${local.region}-${local.environment}"
  service_cidr     = "10.100.0.0/16"
  dns_service_ip   = "10.100.0.10"
  pod_cidr         = "10.244.0.0/16"

  deployment_stage = var.deployment_stage
  outbound_type    = var.deployment_stage == "stage1" ? "loadBalancer" : "userDefinedRouting"

  cloudflare_ipv4_list = split("\n", trimspace(data.http.cloudflare_ips_v4.response_body))

  # ==========================
  # Compatibility locals for main.tf expectations
  # ==========================
  hub_vnet_name           = local.hub_network.vnet_name
  hub_vnet_address_space  = local.hub_network.address_spaces[0]
  hub_firewall_subnet_cidr        = local.hub_network.subnets["firewall"].address_prefixes[0]
  hub_firewall_mgmt_subnet_cidr   = local.hub_network.subnets["firewall_management"].address_prefixes[0]
  hub_bastion_subnet_cidr         = local.hub_network.subnets["bastion"].address_prefixes[0]
  hub_shared_services_subnet_cidr = local.hub_network.subnets["shared_services"].address_prefixes[0]
  hub_private_endpoints_subnet_cidr = local.hub_network.subnets["private_endpoints"].address_prefixes[0]
  # Jumpbox subnet is not part of hub by default; provide a fallback
  hub_jumpbox_subnet_cidr = try(local.hub_network.subnets["jumpbox"].address_prefixes[0], "10.0.6.0/27")

  # Single-spoke legacy locals (used when var.spoke_vnets == null)
  spoke_vnet_name           = local.resolved_default_spoke.vnet_name
  spoke_vnet_address_space  = local.resolved_default_spoke.address_spaces
  aks_node_pool_subnet_cidr = local.resolved_default_spoke.subnets["aks_nodes"].address_prefixes[0]
  private_endpoints_subnet_cidr = local.resolved_default_spoke.subnets["private_endpoints"].address_prefixes[0]
  jumpbox_subnet_cidr            = local.resolved_default_spoke.subnets["jumpbox"].address_prefixes[0]

  default_module_toggles = {
    log_analytics      = true
    hub_vnet           = true
    spoke_vnets        = true
    vnet_peering       = true
    private_dns_zones  = true
    azure_firewall     = true
    route_table_aks    = true
    azure_bastion      = true
    key_vault          = true
    storage_account    = true
    container_registry = true
    postgresql         = true
    aks                = true
    jumpbox            = true
    agent_vm           = true
  }

  module_toggles = merge(local.default_module_toggles, var.module_toggles)
}
