# Canada Central Production Environment - Main Configuration
# Single Resource Group Architecture

# ========================================
# Resource Group
# ========================================

resource "azurerm_resource_group" "main" {
  name     = local.rg_name
  location = local.region
  tags     = local.common_tags
}

# ========================================
# Monitoring
# ========================================

module "log_analytics" {
  source = "../../../modules/monitoring/log-analytics"
  
  workspace_name      = "log-${local.naming_prefix}"
  location            = local.region
  resource_group_name = azurerm_resource_group.main.name
  retention_in_days   = var.log_analytics_retention_days
  
  tags = local.common_tags
}

# ========================================
# Networking - Hub VNet
# ========================================

module "hub_vnet" {
  source = "../../../modules/networking/hub-vnet"
  
  vnet_name           = local.hub_vnet_name
  location            = local.region
  resource_group_name = azurerm_resource_group.main.name
  address_space       = local.hub_vnet_address_space
  
  # Hub VNet Subnet CIDRs
  firewall_subnet_cidr        = local.hub_firewall_subnet_cidr
  firewall_mgmt_subnet_cidr  = local.hub_firewall_mgmt_subnet_cidr
  bastion_subnet_cidr        = local.hub_bastion_subnet_cidr
  shared_services_subnet_cidr = local.hub_shared_services_subnet_cidr
  private_endpoints_subnet_cidr = local.hub_private_endpoints_subnet_cidr
  jumpbox_subnet_cidr        = local.hub_jumpbox_subnet_cidr
  
  tags = local.common_tags
}

# ========================================
# Networking - Spoke VNet
# ========================================

module "spoke_vnet" {
  count  = var.spoke_vnets == null ? 1 : 0
  source = "../../../modules/networking/spoke-vnet"
  
  vnet_name           = local.spoke_vnet_name
  location            = local.region
  resource_group_name = azurerm_resource_group.main.name
  address_space       = local.spoke_vnet_address_space[0]
  address_spaces      = local.spoke_vnet_address_space
  
  # Legacy single-spoke default with three subnets
  aks_node_pool_subnet_cidr    = local.aks_node_pool_subnet_cidr
  private_endpoints_subnet_cidr = local.private_endpoints_subnet_cidr
  jumpbox_subnet_cidr           = local.jumpbox_subnet_cidr
  
  tags = local.common_tags
}

module "spoke_vnets" {
  for_each = var.spoke_vnets != null ? var.spoke_vnets : {}
  source   = "../../../modules/networking/spoke-vnet"
  
  vnet_name           = each.value.vnet_name
  location            = local.region
  resource_group_name = azurerm_resource_group.main.name
  address_space       = each.value.address_spaces[0]
  address_spaces      = each.value.address_spaces
  subnets             = each.value.subnets
  aks_node_pool_subnet_cidr     = each.value.subnets["aks_nodes"].address_prefixes[0]
  private_endpoints_subnet_cidr = each.value.subnets["private_endpoints"].address_prefixes[0]
  jumpbox_subnet_cidr           = each.value.subnets["jumpbox"].address_prefixes[0]
  
  tags = local.common_tags
}

# ========================================
# Networking - VNet Peering
# ========================================

locals {
  # Build a normalized collection of spokes
  _single_spoke = var.spoke_vnets == null ? {
    default = {
      vnet_id                        = module.spoke_vnet[0].vnet_id
      vnet_name                      = module.spoke_vnet[0].vnet_name
      aks_node_pool_subnet_id        = module.spoke_vnet[0].aks_node_pool_subnet_id
      private_endpoints_subnet_id    = module.spoke_vnet[0].private_endpoints_subnet_id
      jumpbox_subnet_id              = module.spoke_vnet[0].jumpbox_subnet_id
    }
  } : {}

  spokes = var.spoke_vnets == null ? local._single_spoke : {
    for k, m in module.spoke_vnets : k => {
      vnet_id                     = m.vnet_id
      vnet_name                   = m.vnet_name
      aks_node_pool_subnet_id     = m.aks_node_pool_subnet_id
      private_endpoints_subnet_id = m.private_endpoints_subnet_id
      jumpbox_subnet_id           = m.jumpbox_subnet_id
    }
  }

  primary_spoke_key = keys(local.spokes)[0]
  primary_spoke     = local.spokes[local.primary_spoke_key]
}

module "vnet_peering" {
  for_each = local.spokes
  source   = "../../../modules/networking/vnet-peering"
  
  hub_vnet_name           = module.hub_vnet.vnet_name
  hub_vnet_id             = module.hub_vnet.vnet_id
  hub_resource_group_name = azurerm_resource_group.main.name
  
  spoke_vnet_name           = each.value.vnet_name
  spoke_vnet_id             = each.value.vnet_id
  spoke_resource_group_name = azurerm_resource_group.main.name
  
  enable_gateway_transit = false
  use_hub_gateway        = false
}

# ========================================
# Private DNS Zones
# ========================================

locals {
  # Private DNS zones for private endpoints
  # Note: AKS private DNS zone is automatically created when private_cluster_enabled=true
  # Do NOT manually create it as it will conflict with Azure's automatic creation
  private_dns_zones = {
    acr      = "privatelink.azurecr.io"
    keyvault = "privatelink.vaultcore.azure.net"
    blob     = "privatelink.blob.core.windows.net"
    file     = "privatelink.file.core.windows.net"
    postgres = "privatelink.postgres.database.azure.com"
  }
}

module "private_dns_zones" {
  source = "../../../modules/networking/private-dns-zone"
  
  for_each = local.private_dns_zones
  
  dns_zone_name       = each.value
  resource_group_name = azurerm_resource_group.main.name
  
  linked_vnet_ids = [for s in local.spokes : s.vnet_id]
  
  tags = merge(local.common_tags, {
    Service = each.key
  })
}

# ========================================
# Security - Azure Firewall
# ========================================

module "azure_firewall" {
  source = "../../../modules/security/azure-firewall"
  
  firewall_name               = "azfw-${local.region}-${local.environment}"
  location                    = local.region
  resource_group_name         = azurerm_resource_group.main.name
  firewall_policy_name        = "azfwpol-${local.region}-${local.environment}"
  firewall_public_ip_name     = "pip-azfw-${local.region}-${local.environment}"
  firewall_management_ip_name = "pip-azfw-mgmt-${local.region}-${local.environment}"
  
  firewall_subnet_id            = module.hub_vnet.firewall_subnet_id
  firewall_management_subnet_id = module.hub_vnet.firewall_management_subnet_id
  
  availability_zones = ["1", "2", "3"]
  
  internal_lb_ip                   = var.istio_internal_lb_ip
  fetch_cloudflare_ips_dynamically = true
  
  threat_intelligence_mode = var.firewall_threat_intel_mode
  idps_mode                = var.firewall_idps_mode
  
  hub_vnet_cidr   = local.hub_vnet_address_space
  spoke_vnet_cidr = local.spoke_vnet_address_space[0]
  
  log_analytics_workspace_id = module.log_analytics.workspace_id
  
  tags = local.common_tags
}

# ========================================
# Security - Route Table for AKS
# ========================================

module "route_table_aks" {
  source = "../../../modules/security/route-table"
  
  count = local.deployment_stage == "stage2" ? 1 : 0
  
  route_table_name              = "rt-aks-${local.region}-${local.environment}"
  location                      = local.region
  resource_group_name           = azurerm_resource_group.main.name
  disable_bgp_route_propagation = true
  
  routes = [
    {
      name                   = "default-via-firewall"
      address_prefix         = "0.0.0.0/0"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = module.azure_firewall.firewall_private_ip
    }
  ]
  
  subnet_ids = [for s in local.spokes : s.aks_node_pool_subnet_id]
  
  depends_on = [
    module.azure_firewall
  ]
  
  tags = local.common_tags
}

# ========================================
# Security - Network Security Groups (NSGs)
# ========================================

# NSG for AKS Node Pool Subnet
module "nsg_aks" {
  source = "../../../modules/security/nsg"

  nsg_name            = "nsg-aks-${local.region}-${local.environment}"
  location            = local.region
  resource_group_name = azurerm_resource_group.main.name

  # Inbound rules for AKS
  inbound_rules = [
    {
      name                       = "Allow-LoadBalancer"
      priority                   = 100
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "AzureLoadBalancer"
      destination_address_prefix = "*"
      description                = "Allow Azure Load Balancer health probes"
    },
    {
      name                       = "Allow-VNet-Inbound"
      priority                   = 110
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "VirtualNetwork"
      description                = "Allow traffic within VNet"
    },
    {
      name                       = "Deny-All-Inbound"
      priority                   = 4096
      access                     = "Deny"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
      description                = "Deny all other inbound traffic"
    }
  ]

  # Outbound rules for AKS
  outbound_rules = [
    {
      name                       = "Allow-AzureCloud"
      priority                   = 100
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_ranges    = ["443"]
      source_address_prefix      = "*"
      destination_address_prefix = "AzureCloud"
      description                = "Allow outbound to Azure services"
    },
    {
      name                       = "Allow-Internet-HTTPS"
      priority                   = 110
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_ranges    = ["80", "443"]
      source_address_prefix      = "*"
      destination_address_prefix = "Internet"
      description                = "Allow outbound HTTP/HTTPS to Internet"
    },
    {
      name                       = "Allow-DNS"
      priority                   = 120
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "53"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
      description                = "Allow DNS queries"
    },
    {
      name                       = "Allow-NTP"
      priority                   = 130
      access                     = "Allow"
      protocol                   = "Udp"
      source_port_range          = "*"
      destination_port_range     = "123"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
      description                = "Allow NTP time sync"
    },
    {
      name                       = "Allow-VNet-Outbound"
      priority                   = 140
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "VirtualNetwork"
      description                = "Allow traffic within VNet"
    }
  ]

  subnet_ids                 = [for s in local.spokes : s.aks_node_pool_subnet_id]
  log_analytics_workspace_id = module.log_analytics.workspace_id

  tags = local.common_tags

  depends_on = [
    module.spoke_vnets
  ]
}

# NSG for Private Endpoints Subnet
module "nsg_private_endpoints" {
  source = "../../../modules/security/nsg"

  nsg_name            = "nsg-pe-${local.region}-${local.environment}"
  location            = local.region
  resource_group_name = azurerm_resource_group.main.name

  # Inbound rules for Private Endpoints
  inbound_rules = [
    {
      name                       = "Allow-AKS-to-PrivateEndpoints"
      priority                   = 100
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_ranges    = ["443", "5432"]
      source_address_prefix      = "10.1.16.0/22"  # AKS subnet
      destination_address_prefix = "10.1.29.0/24"  # Private endpoints subnet
      description                = "Allow AKS to access private endpoints (HTTPS, PostgreSQL)"
    },
    {
      name                       = "Allow-VNet-Inbound"
      priority                   = 110
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "VirtualNetwork"
      description                = "Allow traffic within VNet"
    }
  ]

  # Outbound rules for Private Endpoints
  outbound_rules = [
    {
      name                       = "Allow-VNet-Outbound"
      priority                   = 100
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "VirtualNetwork"
      description                = "Allow traffic within VNet"
    }
  ]

  subnet_ids                 = [for s in local.spokes : s.private_endpoints_subnet_id]
  log_analytics_workspace_id = module.log_analytics.workspace_id

  tags = local.common_tags

  depends_on = [
    module.spoke_vnets
  ]
}

# ========================================
# Security - Azure Bastion
# ========================================

module "azure_bastion" {
  source = "../../../modules/security/bastion"

  bastion_name            = "bastion-${local.region}-${local.environment}"
  location                = local.region
  resource_group_name     = azurerm_resource_group.main.name
  bastion_subnet_id       = module.hub_vnet.bastion_subnet_id
  bastion_public_ip_name  = "pip-bastion-${local.region}-${local.environment}"

  bastion_sku            = "Standard"
  copy_paste_enabled     = true
  file_copy_enabled      = true
  ip_connect_enabled     = true
  tunneling_enabled      = true
  shareable_link_enabled = false
  scale_units            = 2
  
  log_analytics_workspace_id = module.log_analytics.workspace_id
  
  tags = local.common_tags
}

# ========================================
# Storage - Key Vault
# ========================================

module "key_vault" {
  source = "../../../modules/storage/key-vault"
  
  key_vault_name      = "kv-${local.naming_prefix}"
  location            = local.region
  resource_group_name = azurerm_resource_group.main.name
  
  sku_name = "premium"
  
  enable_private_endpoint = true
  private_endpoint_subnet_id = local.primary_spoke.private_endpoints_subnet_id
  private_dns_zone_ids = [module.private_dns_zones["keyvault"].dns_zone_id]
  
  log_analytics_workspace_id = module.log_analytics.workspace_id
  
  tags = local.common_tags
}

# ========================================
# Storage - Storage Account
# ========================================

module "storage_account" {
  source = "../../../modules/storage/storage-account"
  
  storage_account_name = replace("st${local.naming_prefix}", "-", "")
  location             = local.region
  resource_group_name  = azurerm_resource_group.main.name
  
  account_tier             = "Standard"
  account_replication_type = "ZRS"
  account_kind             = "StorageV2"
  
  enable_private_endpoint = true
  enable_file_private_endpoint = true
  private_endpoint_subnet_id = local.primary_spoke.private_endpoints_subnet_id
  private_dns_zone_ids_blob = [module.private_dns_zones["blob"].dns_zone_id]
  private_dns_zone_ids_file = [module.private_dns_zones["file"].dns_zone_id]
  
  tags = local.common_tags
}

# ========================================
# Storage - Container Registry
# ========================================

module "container_registry" {
  source = "../../../modules/storage/container-registry"
  
  registry_name      = "acr${replace(local.naming_prefix, "-", "")}"
  location           = local.region
  resource_group_name = azurerm_resource_group.main.name
  
  sku = "Premium"
  
  enable_private_endpoint = true
  private_endpoint_subnet_id = local.primary_spoke.private_endpoints_subnet_id
  private_dns_zone_ids = [module.private_dns_zones["acr"].dns_zone_id]
  
  tags = local.common_tags
}

# ========================================
# Data - PostgreSQL Flexible Server
# ========================================

module "postgresql" {
  source = "../../../modules/data/postgresql-flexible"
  
  server_name      = "psql-${local.naming_prefix}"
  resource_group_name = azurerm_resource_group.main.name
  location          = local.region
  
  postgresql_version    = var.postgresql_version
  administrator_login   = var.postgresql_admin_login
  administrator_password = var.postgresql_admin_password
  
  sku_name              = var.postgresql_sku_name
  storage_mb            = var.postgresql_storage_mb
  backup_retention_days = var.postgresql_backup_retention_days
  
  delegated_subnet_id = local.primary_spoke.private_endpoints_subnet_id
  private_dns_zone_id = module.private_dns_zones["postgres"].dns_zone_id
  
  log_analytics_workspace_id = module.log_analytics.workspace_id
  
  tags = local.common_tags
}

# ========================================
# Compute - AKS Cluster
# ========================================

module "aks_cluster" {
  source = "../../../modules/compute/aks-cluster"
  
  cluster_name             = local.aks_cluster_name
  location                 = local.region
  resource_group_name      = azurerm_resource_group.main.name
  dns_prefix               = "${local.aks_cluster_name}-dns"
  node_resource_group_name = "rg-${local.aks_cluster_name}-nodes"
  kubernetes_version       = var.kubernetes_version
  
  vnet_id                = local.primary_spoke.vnet_id
  aks_node_pool_subnet_id = local.primary_spoke.aks_node_pool_subnet_id
  
  outbound_type  = local.outbound_type
  service_cidr   = local.service_cidr
  dns_service_ip = local.dns_service_ip
  pod_cidr       = local.pod_cidr
  private_cluster_enabled             = var.aks_private_cluster_enabled
  private_cluster_public_fqdn_enabled = false
  
  system_node_pool_vm_size   = var.system_node_pool_vm_size
  system_node_pool_min_count = var.system_node_pool_min_count
  system_node_pool_max_count = var.system_node_pool_max_count
  
  user_node_pool_enabled   = true
  user_node_pool_vm_size   = var.user_node_pool_vm_size
  user_node_pool_min_count = var.user_node_pool_min_count
  user_node_pool_max_count = var.user_node_pool_max_count
  
  aks_identity_name = "id-aks-${local.region}-${local.environment}"
  
  # ACR access
  acr_id = module.container_registry.registry_id
  
  # Key Vault access
  key_vault_id = module.key_vault.key_vault_id
  
  azure_rbac_enabled     = true
  tenant_id              = var.tenant_id
  admin_group_object_ids = var.aks_admin_group_object_ids
  
  # Istio Service Mesh (inbuilt feature)
  istio_internal_ingress_gateway_enabled = true
  istio_external_ingress_gateway_enabled = false
  
  log_analytics_workspace_id = module.log_analytics.workspace_id
  
  tags = local.common_tags
  
  depends_on = [
    module.vnet_peering,
    module.azure_firewall,
    module.container_registry,
    module.key_vault
  ]
}

# ========================================
# Compute - Jumpbox VM
# ========================================

module "jumpbox" {
  source = "../../../modules/compute/linux-vm"
  
  vm_name             = "vm-jumpbox-${local.naming_prefix}"
  location            = local.region
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = local.primary_spoke.jumpbox_subnet_id
  
  nic_name = "nic-jumpbox-${local.naming_prefix}"
  
  admin_username   = var.jumpbox_admin_username
  admin_password   = var.jumpbox_admin_password
  
  vm_size  = var.jumpbox_vm_size
  vm_purpose = "Jumpbox"
  
  os_disk_name = "disk-jumpbox-${local.naming_prefix}"
  
  tags = merge(local.common_tags, {
    Purpose = "Jumpbox"
  })
}

# ========================================
# Compute - Agent VM
# ========================================

module "agent_vm" {
  source = "../../../modules/compute/linux-vm"
  
  vm_name             = "vm-agent-${local.naming_prefix}"
  location            = local.region
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = local.primary_spoke.jumpbox_subnet_id
  
  nic_name = "nic-agent-${local.naming_prefix}"
  
  admin_username   = var.agent_vm_admin_username
  admin_password   = var.agent_vm_admin_password
  
  vm_size  = var.agent_vm_size
  vm_purpose = "Agent"
  
  os_disk_name = "disk-agent-${local.naming_prefix}"
  
  tags = merge(local.common_tags, {
    Purpose = "Agent"
  })
}
