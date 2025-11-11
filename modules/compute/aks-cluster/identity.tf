# Managed Identity and Role Assignments for AKS

# ========================================
# User-Assigned Managed Identity
# ========================================

resource "azurerm_user_assigned_identity" "aks" {
  name                = var.aks_identity_name
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = merge(
    var.tags,
    {
      Purpose = "AKS Cluster Identity"
    }
  )
}

# ========================================
# Role Assignment: Network Contributor
# ========================================

resource "azurerm_role_assignment" "aks_network_contributor" {
  scope                = var.vnet_id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.aks.principal_id
}

# ========================================
# Role Assignment: ACR Pull
# ========================================

resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = var.acr_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id
  
  # Explicitly depend on the cluster to ensure it's created first
  depends_on = [
    azurerm_kubernetes_cluster.this
  ]
}

# ========================================
# Role Assignment: Key Vault Secrets User
# ========================================

resource "azurerm_role_assignment" "aks_key_vault_secrets_user" {
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_kubernetes_cluster.this.key_vault_secrets_provider[0].secret_identity[0].object_id
  
  # Explicitly depend on the cluster to ensure it's created first
  depends_on = [
    azurerm_kubernetes_cluster.this
  ]
}

# ========================================
# Role Assignment: Monitoring Metrics Publisher
# ========================================

resource "azurerm_role_assignment" "aks_monitoring_metrics_publisher" {
  scope                = azurerm_kubernetes_cluster.this.id
  role_definition_name = "Monitoring Metrics Publisher"
  principal_id         = azurerm_user_assigned_identity.aks.principal_id
}
