# User Node Pool for Application Workloads
# Uses same subnet as system pool
# Both pools coexist in shared subnet with Calico network policy isolation

resource "azurerm_kubernetes_cluster_node_pool" "user" {
  count = var.user_node_pool_enabled ? 1 : 0

  name                  = var.user_node_pool_name
  kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id
  vm_size               = var.user_node_pool_vm_size

  # Use shared subnet (same as system pool)
  # Use the same subnet ID as the system node pool
  vnet_subnet_id = coalesce(var.aks_node_pool_subnet_id, var.system_node_pool_subnet_id)

  # Autoscaling is enabled when min_count and max_count are set
  # If autoscaling is disabled, only node_count is set
  min_count  = var.user_node_pool_enable_autoscaling ? var.user_node_pool_min_count : null
  max_count  = var.user_node_pool_enable_autoscaling ? var.user_node_pool_max_count : null
  node_count = var.user_node_pool_enable_autoscaling ? null : var.user_node_pool_count

  max_pods        = var.user_node_pool_max_pods
  os_disk_size_gb = var.user_node_pool_os_disk_size_gb
  os_disk_type    = var.user_node_pool_os_disk_type
  zones           = var.user_node_pool_availability_zones

  # Node Labels
  node_labels = merge(
    var.user_node_pool_labels,
    {
      "nodepool-type" = "user"
      "environment"   = var.environment
      "workload"      = "application"
      "subnet-shared" = "true"
    }
  )

  # Node Taints (optional - for workload isolation)
  node_taints = var.user_node_pool_taints

  upgrade_settings {
    max_surge = var.user_node_pool_max_surge
  }

  tags = merge(
    var.tags,
    {
      NodePoolType = "User"
      Purpose      = "ApplicationWorkloads"
      SubnetShared = "true"
    }
  )
}