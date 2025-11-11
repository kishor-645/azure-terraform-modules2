# Container Registry Module Outputs

# ========================================
# Registry Outputs
# ========================================

output "registry_id" {
  description = "Container registry ID"
  value       = azurerm_container_registry.this.id
}

output "registry_name" {
  description = "Container registry name"
  value       = azurerm_container_registry.this.name
}

output "login_server" {
  description = "Container registry login server"
  value       = azurerm_container_registry.this.login_server
}

output "admin_username" {
  description = "Admin username (if enabled)"
  value       = var.admin_enabled ? azurerm_container_registry.this.admin_username : null
  sensitive   = true
}

output "admin_password" {
  description = "Admin password (if enabled)"
  value       = var.admin_enabled ? azurerm_container_registry.this.admin_password : null
  sensitive   = true
}

# ========================================
# Private Endpoint Outputs
# ========================================

output "private_endpoint_id" {
  description = "Private endpoint ID"
  value       = var.enable_private_endpoint ? azurerm_private_endpoint.this[0].id : null
}

output "private_ip" {
  description = "Private endpoint IP"
  value       = var.enable_private_endpoint ? azurerm_private_endpoint.this[0].private_service_connection[0].private_ip_address : null
}

# ========================================
# Consolidated Output
# ========================================

output "registry_details" {
  description = "Consolidated registry details"
  value = {
    id                   = azurerm_container_registry.this.id
    name                 = azurerm_container_registry.this.name
    login_server         = azurerm_container_registry.this.login_server
    sku                  = var.sku
    admin_enabled        = var.admin_enabled
    has_private_endpoint = var.enable_private_endpoint
    georeplications      = length(var.georeplications)
  }
}

# ========================================
# Connection Instructions
# ========================================

output "connection_instructions" {
  description = "Instructions for using the registry"
  value = <<-EOT
    ===================================
    ACR Connection Instructions
    ===================================
    
    1. Login with Azure CLI:
       az acr login --name ${var.registry_name}
    
    2. Login with Docker:
       docker login ${azurerm_container_registry.this.login_server}
    
    3. Tag image:
       docker tag myimage:latest ${azurerm_container_registry.this.login_server}/myimage:latest
    
    4. Push image:
       docker push ${azurerm_container_registry.this.login_server}/myimage:latest
    
    5. Pull image in AKS (with AcrPull role):
       kubectl create deployment myapp --image=${azurerm_container_registry.this.login_server}/myimage:latest
    
    Login Server: ${azurerm_container_registry.this.login_server}
    Private Endpoint: ${var.enable_private_endpoint}
    ===================================
  EOT
}
