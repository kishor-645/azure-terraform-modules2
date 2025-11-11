# PostgreSQL Flexible Server Module Outputs

output "postgresql_id" {
  description = "PostgreSQL server ID"
  value       = azurerm_postgresql_flexible_server.this.id
}

output "postgresql_name" {
  description = "PostgreSQL server name"
  value       = azurerm_postgresql_flexible_server.this.name
}

output "postgresql_fqdn" {
  description = "PostgreSQL server FQDN"
  value       = azurerm_postgresql_flexible_server.this.fqdn
}

output "postgresql_version" {
  description = "PostgreSQL version"
  value       = azurerm_postgresql_flexible_server.this.version
}

output "administrator_login" {
  description = "Administrator login"
  value       = azurerm_postgresql_flexible_server.this.administrator_login
}

output "database_names" {
  description = "Created database names"
  value       = [for db in azurerm_postgresql_flexible_server_database.databases : db.name]
}

output "high_availability_enabled" {
  description = "High availability status"
  value       = var.high_availability_enabled
}

output "connection_string" {
  description = "PostgreSQL connection string"
  value       = "postgresql://${var.administrator_login}@${azurerm_postgresql_flexible_server.this.fqdn}:5432"
  sensitive   = true
}
