# AKS Cluster Module with Single Subnet Configuration
# Uses 10.1.16.0/22 for BOTH system and user node pools initially
# Reserve 10.1.0.0/20 for future system pool split

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
# Local Values for Backward Compatibility
# ========================================

locals {
  # Use aks_node_pool_subnet_id if provided, otherwise fall back to system_node_pool_subnet_id for backward compatibility
  node_pool_subnet_id = coalesce(var.aks_node_pool_subnet_id, var.system_node_pool_subnet_id)
}

# ========================================
# AKS Cluster with Single Subnet
# ========================================

resource "azurerm_kubernetes_cluster" "this" {
  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.dns_prefix
  kubernetes_version  = var.kubernetes_version
  
  # Private Cluster Configuration
  private_cluster_enabled             = var.private_cluster_enabled
  private_dns_zone_id                 = var.private_dns_zone_id
  private_cluster_public_fqdn_enabled = var.private_cluster_public_fqdn_enabled

  # Node Resource Group
  node_resource_group = var.node_resource_group_name

  # Default (System) Node Pool
  # IMPORTANT: Both system and user pools use shared subnet
  # Subnet: Shared subnet for both system and user node pools
  default_node_pool {
    name           = var.system_node_pool_name
    vm_size        = var.system_node_pool_vm_size
    vnet_subnet_id = local.node_pool_subnet_id
    # Autoscaling is enabled when min_count and max_count are set
    # If autoscaling is disabled, only node_count is set
    min_count  = var.system_node_pool_enable_autoscaling ? var.system_node_pool_min_count : null
    max_count  = var.system_node_pool_enable_autoscaling ? var.system_node_pool_max_count : null
    node_count = var.system_node_pool_enable_autoscaling ? null : var.system_node_pool_count
    max_pods            = var.system_node_pool_max_pods
    os_disk_size_gb     = var.system_node_pool_os_disk_size_gb
    os_disk_type        = var.system_node_pool_os_disk_type
    zones               = var.system_node_pool_availability_zones
    
    upgrade_settings {
      max_surge = var.system_node_pool_max_surge
    }

    tags = merge(
      var.tags,
      {
        NodePoolType = "System"
        SubnetShared = "true"  # Indicator that subnet is shared with user pool
      }
    )
  }

  # Identity (User-Assigned Managed Identity)
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks.id]
  }

  # Network Profile - Azure CNI Overlay
  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_policy      = "calico"
    outbound_type       = var.outbound_type
    load_balancer_sku   = "standard"
    
    service_cidr   = var.service_cidr
    dns_service_ip = var.dns_service_ip
    
    # Pod CIDR for Overlay mode
    pod_cidr = var.pod_cidr
  }

  # Microsoft Entra ID (Azure AD) Integration with Kubernetes RBAC
  # This enables Microsoft Entra ID authentication with Azure RBAC for Kubernetes authorization
  azure_active_directory_role_based_access_control {
    azure_rbac_enabled     = true  # Enable Azure RBAC for Kubernetes authorization
    tenant_id              = var.tenant_id
    admin_group_object_ids = var.admin_group_object_ids
  }

  # Istio Service Mesh Profile (inbuilt feature)
  service_mesh_profile {
    mode = "Istio"
    # Istio revision - use "default" for the default Istio installation
    # Internal and external ingress gateways are automatically configured
    revisions = ["default"]
  }

  # Monitoring
  oms_agent {
    log_analytics_workspace_id = var.log_analytics_workspace_id
  }

  # Key Vault Secrets Provider
  key_vault_secrets_provider {
    secret_rotation_enabled  = var.key_vault_secrets_rotation_enabled
    secret_rotation_interval = var.key_vault_secrets_rotation_interval
  }

  # Auto-scaler Profile
  auto_scaler_profile {
    balance_similar_node_groups      = true
    expander                         = "random"
    max_graceful_termination_sec     = 600
    max_node_provisioning_time       = "15m"
    scale_down_delay_after_add       = "10m"
    scale_down_delay_after_delete    = "10s"
    scale_down_delay_after_failure   = "3m"
    scale_down_unneeded              = "10m"
    scale_down_unready               = "20m"
    scale_down_utilization_threshold = "0.5"
  }

  tags = merge(
    var.tags,
    {
      ClusterType  = "Private"
      NetworkMode  = "AzureCNIOverlay"
      ServiceMesh  = "Istio"
      SubnetConfig = "SingleShared"
    }
  )

  depends_on = [
    azurerm_role_assignment.aks_network_contributor
  ]
}