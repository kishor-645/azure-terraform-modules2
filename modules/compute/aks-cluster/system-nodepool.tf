# System Node Pool Configuration
# Note: System node pool is defined in main.tf as default_node_pool
# This file contains additional configuration and documentation

# System Node Pool Characteristics:
# - Hosts critical system pods (CoreDNS, metrics-server, etc.)
# - Should have predictable capacity
# - Typically uses Standard_D4s_v5 or similar
# - Minimum 1 node, recommended 2-3 for HA
# - Should not be scaled to zero
# - Uses CriticalAddonsOnly taint (automatically applied by AKS)

# The system node pool is defined in main.tf under default_node_pool block
# Variables used:
# - system_node_pool_name (default: "system")
# - system_node_pool_vm_size (default: "Standard_D4s_v5")
# - system_node_pool_subnet_id (required)
# - system_node_pool_enable_autoscaling (default: true)
# - system_node_pool_min_count (default: 2)
# - system_node_pool_max_count (default: 5)
# - system_node_pool_max_pods (default: 30)
# - system_node_pool_os_disk_size_gb (default: 128)
# - system_node_pool_os_disk_type (default: "Managed")
# - system_node_pool_availability_zones (default: ["1", "2", "3"])
