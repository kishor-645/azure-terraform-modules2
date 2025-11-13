# Local Values and Data Sources

locals {
  environment = "prod"
  region      = var.location

  # Region code mapping for naming conventions
  # Maps Azure region names to short codes used in resource naming
  region_code_map = {
    canadacentral      = "cc"
    canadaeast         = "ce"
    eastus             = "eus"
    eastus2            = "eus2"
    westus             = "wus"
    westus2            = "wus2"
    westus3            = "wus3"
    centralus          = "cus"
    southcentralus     = "scus"
    northcentralus     = "ncus"
    uksouth            = "uks"
    ukwest             = "ukw"
    westeurope         = "weu"
    northeurope        = "neu"
    francecentral      = "frc"
    francesouth        = "frs"
    germanywestcentral = "dewc"
    switzerlandnorth   = "chn"
    switzerlandwest    = "chw"
    norwayeast         = "noe"
    swedencentral      = "sec"
    uaenorth           = "uan"
    uaecentral         = "uac"
    japaneast          = "jpe"
    japanwest          = "jpw"
    koreacentral       = "krc"
    koreasouth         = "krs"
    southeastasia      = "sea"
    eastasia           = "eaa"
    australiaeast      = "aue"
    australiasoutheast = "ause"
    australiacentral   = "auc"
    australiacentral2  = "auc2"
    brazilsouth        = "brs"
    brazilsoutheast    = "brse"
    southafricanorth   = "zan"
    southafricawest    = "zaw"
    indiacentral       = "inc"
    indiasouth         = "ins"
    indiawest          = "inw"
    chinanorth         = "cnn"
    chinaeast          = "cne"
  }

  # Get region code from map, or use first 4 characters as fallback
  region_code = lookup(
    local.region_code_map,
    var.location,
    substr(var.location, 0, min(4, length(var.location)))
  )

  # Human-readable region name mapping (for tags)
  region_name_map = {
    canadacentral      = "Canada Central"
    canadaeast         = "Canada East"
    eastus             = "East US"
    eastus2            = "East US 2"
    westus             = "West US"
    westus2            = "West US 2"
    westus3            = "West US 3"
    centralus          = "Central US"
    southcentralus     = "South Central US"
    northcentralus     = "North Central US"
    uksouth            = "UK South"
    ukwest             = "UK West"
    westeurope         = "West Europe"
    northeurope        = "North Europe"
    francecentral      = "France Central"
    francesouth        = "France South"
    germanywestcentral = "Germany West Central"
    switzerlandnorth   = "Switzerland North"
    switzerlandwest    = "Switzerland West"
    norwayeast         = "Norway East"
    swedencentral      = "Sweden Central"
    uaenorth           = "UAE North"
    uaecentral         = "UAE Central"
    japaneast          = "Japan East"
    japanwest          = "Japan West"
    koreacentral       = "Korea Central"
    koreasouth         = "Korea South"
    southeastasia      = "Southeast Asia"
    eastasia           = "East Asia"
    australiaeast      = "Australia East"
    australiasoutheast = "Australia Southeast"
    australiacentral   = "Australia Central"
    australiacentral2  = "Australia Central 2"
    brazilsouth        = "Brazil South"
    brazilsoutheast    = "Brazil Southeast"
    southafricanorth   = "South Africa North"
    southafricawest    = "South Africa West"
    indiacentral       = "India Central"
    indiasouth         = "India South"
    indiawest          = "India West"
    chinanorth         = "China North"
    chinaeast          = "China East"
  }

  region_display_name = lookup(
    local.region_name_map,
    var.location,
    var.location # Fallback to location value if not in map
  )

  base_common_tags = {
    Environment  = "Production"
    Region       = local.region_display_name
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
      name                              = "PrivateEndpointsSubnet"
      address_prefixes                  = ["10.0.5.0/24"]
      private_endpoint_network_policies = "Disabled"
    }
  }

  default_hub_network = {
    vnet_name               = "vnet-hub-${local.region}-${local.environment}"
    address_spaces          = ["10.0.0.0/16"]
    subnets                 = jsondecode(jsonencode(local.default_hub_subnets))
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
    subnets                 = try(local.user_hub_network.subnets, null) != null ? jsondecode(jsonencode(local.user_hub_network.subnets)) : jsondecode(jsonencode(local.default_hub_network.subnets))
  }

  # ==========================
  # Spoke configuration (defaults + overrides)
  # ==========================

  default_spoke_subnets = {
    aks_nodes = {
      name             = "AKSNodeSubnet"
      address_prefixes = ["10.1.0.0/20"]
    }
    private_endpoints = {
      name                              = "PrivateEndpointsSubnet"
      address_prefixes                  = ["10.1.16.0/24"]
      private_endpoint_network_policies = "Disabled"
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

  aks_cluster_name = "aks-${local.region}-${local.environment}"
  service_cidr     = "10.100.0.0/16"
  dns_service_ip   = "10.100.0.10"
  pod_cidr         = "10.244.0.0/16"

  deployment_stage = var.deployment_stage
  outbound_type    = var.deployment_stage == "stage1" ? "loadBalancer" : "userDefinedRouting"

  # ==========================
  # Compatibility locals for main.tf expectations
  # ==========================
  hub_vnet_name                     = local.hub_network.vnet_name
  hub_vnet_address_space            = local.hub_network.address_spaces[0]
  hub_firewall_subnet_cidr          = local.hub_network.subnets["firewall"].address_prefixes[0]
  hub_firewall_mgmt_subnet_cidr     = local.hub_network.subnets["firewall_management"].address_prefixes[0]
  hub_bastion_subnet_cidr           = local.hub_network.subnets["bastion"].address_prefixes[0]
  hub_shared_services_subnet_cidr   = local.hub_network.subnets["shared_services"].address_prefixes[0]
  hub_private_endpoints_subnet_cidr = local.hub_network.subnets["private_endpoints"].address_prefixes[0]
  # Single-spoke legacy locals (used when var.spoke_vnets == null)
  spoke_vnet_name               = local.resolved_default_spoke.vnet_name
  spoke_vnet_address_space      = local.resolved_default_spoke.address_spaces
  aks_node_pool_subnet_cidr     = local.resolved_default_spoke.subnets["aks_nodes"].address_prefixes[0]
  private_endpoints_subnet_cidr = local.resolved_default_spoke.subnets["private_endpoints"].address_prefixes[0]

}
