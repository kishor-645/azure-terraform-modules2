# Canada Central Production Environment Outputs

output "resource_group_name" {
  description = "Main resource group name"
  value       = azurerm_resource_group.main.name
}

output "hub_vnet_id" {
  description = "Hub VNet ID"
  value       = module.hub_vnet.vnet_id
}

output "spoke_vnet_id" {
  description = "Spoke VNet ID"
  value       = var.spoke_vnets == null ? module.spoke_vnet[0].vnet_id : null
}

output "firewall_private_ip" {
  description = "Azure Firewall private IP"
  value       = module.azure_firewall.firewall_private_ip
}

output "firewall_public_ip" {
  description = "Azure Firewall public IP"
  value       = module.azure_firewall.firewall_public_ip
}

output "aks_cluster_name" {
  description = "AKS cluster name"
  value       = module.aks_cluster.cluster_name
}

output "aks_cluster_fqdn" {
  description = "AKS cluster FQDN"
  value       = module.aks_cluster.cluster_private_fqdn
}

output "deployment_stage" {
  description = "Current deployment stage"
  value       = local.deployment_stage
}

output "outbound_type" {
  description = "AKS outbound type"
  value       = local.outbound_type
}

output "istio_lb_ip_discovery_command" {
  description = "Command to discover Istio internal LB IP"
  value       = "kubectl get svc istio-ingressgateway -n istio-system -o jsonpath='{.status.loadBalancer.ingress[0].ip}'"
}

output "get_aks_credentials_command" {
  description = "Command to get AKS credentials"
  value       = "az aks get-credentials --resource-group ${azurerm_resource_group.main.name} --name ${module.aks_cluster.cluster_name}"
}
