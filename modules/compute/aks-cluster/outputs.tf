# AKS Cluster Module Outputs

# ========================================
# Cluster Outputs
# ========================================

output "cluster_id" {
  description = "The ID of the AKS cluster"
  value       = azurerm_kubernetes_cluster.this.id
}

output "cluster_name" {
  description = "The name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.this.name
}

output "cluster_fqdn" {
  description = "The FQDN of the AKS cluster"
  value       = azurerm_kubernetes_cluster.this.fqdn
}

output "cluster_private_fqdn" {
  description = "The private FQDN of the AKS cluster"
  value       = azurerm_kubernetes_cluster.this.private_fqdn
}

output "kube_config_raw" {
  description = "Raw kubeconfig for the AKS cluster"
  value       = azurerm_kubernetes_cluster.this.kube_config_raw
  sensitive   = true
}

output "kube_admin_config_raw" {
  description = "Raw admin kubeconfig for the AKS cluster"
  value       = azurerm_kubernetes_cluster.this.kube_admin_config_raw
  sensitive   = true
}

output "node_resource_group" {
  description = "The auto-generated resource group containing AKS resources"
  value       = azurerm_kubernetes_cluster.this.node_resource_group
}

# ========================================
# Identity Outputs
# ========================================

output "identity_principal_id" {
  description = "The principal ID of the AKS managed identity"
  value       = azurerm_user_assigned_identity.aks.principal_id
}

output "identity_client_id" {
  description = "The client ID of the AKS managed identity"
  value       = azurerm_user_assigned_identity.aks.client_id
}

output "kubelet_identity_object_id" {
  description = "The object ID of the kubelet identity"
  value       = azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id
}

output "kubelet_identity_client_id" {
  description = "The client ID of the kubelet identity"
  value       = azurerm_kubernetes_cluster.this.kubelet_identity[0].client_id
}

# ========================================
# Network Outputs
# ========================================

output "outbound_type" {
  description = "The outbound type configured for the cluster"
  value       = azurerm_kubernetes_cluster.this.network_profile[0].outbound_type
}

output "network_plugin" {
  description = "The network plugin configured"
  value       = azurerm_kubernetes_cluster.this.network_profile[0].network_plugin
}

output "network_plugin_mode" {
  description = "The network plugin mode (Overlay)"
  value       = azurerm_kubernetes_cluster.this.network_profile[0].network_plugin_mode
}

output "network_policy" {
  description = "The network policy configured (Calico)"
  value       = azurerm_kubernetes_cluster.this.network_profile[0].network_policy
}

# ========================================
# Istio Service Mesh Outputs
# ========================================

output "istio_enabled" {
  description = "Whether Istio service mesh is enabled"
  value       = length(azurerm_kubernetes_cluster.this.service_mesh_profile) > 0
}

output "istio_internal_ingress_gateway_enabled" {
  description = "Whether Istio internal ingress gateway is enabled"
  value       = var.istio_internal_ingress_gateway_enabled
}

output "istio_external_ingress_gateway_enabled" {
  description = "Whether Istio external ingress gateway is enabled"
  value       = var.istio_external_ingress_gateway_enabled
}

# ========================================
# Node Pool Outputs
# ========================================

output "system_node_pool_name" {
  description = "Name of the system node pool"
  value       = var.system_node_pool_name
}

output "user_node_pool_name" {
  description = "Name of the user node pool"
  value       = var.user_node_pool_enabled ? azurerm_kubernetes_cluster_node_pool.user[0].name : null
}

output "user_node_pool_id" {
  description = "ID of the user node pool"
  value       = var.user_node_pool_enabled ? azurerm_kubernetes_cluster_node_pool.user[0].id : null
}

# ========================================
# Consolidated Output
# ========================================

output "cluster_details" {
  description = "Consolidated AKS cluster details"
  value = {
    id                   = azurerm_kubernetes_cluster.this.id
    name                 = azurerm_kubernetes_cluster.this.name
    fqdn                 = azurerm_kubernetes_cluster.this.fqdn
    private_fqdn         = azurerm_kubernetes_cluster.this.private_fqdn
    kubernetes_version   = azurerm_kubernetes_cluster.this.kubernetes_version
    node_resource_group  = azurerm_kubernetes_cluster.this.node_resource_group
    network_plugin       = azurerm_kubernetes_cluster.this.network_profile[0].network_plugin
    network_plugin_mode  = azurerm_kubernetes_cluster.this.network_profile[0].network_plugin_mode
    network_policy       = azurerm_kubernetes_cluster.this.network_profile[0].network_policy
    outbound_type        = azurerm_kubernetes_cluster.this.network_profile[0].outbound_type
    istio_enabled        = length(azurerm_kubernetes_cluster.this.service_mesh_profile) > 0
    private_cluster      = var.private_cluster_enabled
  }
}

# ========================================
# Connection Instructions
# ========================================

output "connection_instructions" {
  description = "Instructions for connecting to the AKS cluster"
  value = <<-EOT
    ===================================
    AKS Cluster Connection Instructions
    ===================================
    
    1. Get credentials (Azure AD user):
       az aks get-credentials \
         --resource-group ${var.resource_group_name} \
         --name ${var.cluster_name}
    
    2. Get credentials (admin - for troubleshooting):
       az aks get-credentials \
         --resource-group ${var.resource_group_name} \
         --name ${var.cluster_name} \
         --admin
    
    3. Verify connection:
       kubectl get nodes
    
    4. Get Istio internal LB IP (after Istio installation):
       kubectl get svc istio-ingressgateway -n istio-system -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
    
    Cluster FQDN: ${azurerm_kubernetes_cluster.this.private_fqdn}
    Private Cluster: ${var.private_cluster_enabled}
    Outbound Type: ${var.outbound_type}
    
    Note: For private clusters, connect from jumpbox or via VPN/Bastion
    ===================================
  EOT
}

# ========================================
# Istio Internal LB IP Discovery
# ========================================

output "istio_internal_lb_discovery_command" {
  description = "Command to discover Istio internal load balancer IP"
  value       = "kubectl get svc istio-ingressgateway -n istio-system -o jsonpath='{.status.loadBalancer.ingress[0].ip}'"
}
