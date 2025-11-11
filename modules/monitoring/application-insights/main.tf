# Application Insights Module
# Creates workspace-based Application Insights for application telemetry

terraform {
  required_version = ">= 1.10.3"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.51.0"
    }
  }
}

resource "azurerm_application_insights" "this" {
  name                = var.app_insights_name
  location            = var.location
  resource_group_name = var.resource_group_name
  workspace_id        = var.log_analytics_workspace_id
  application_type    = var.application_type
  
  retention_in_days             = var.retention_in_days
  daily_data_cap_in_gb          = var.daily_data_cap_in_gb
  daily_data_cap_notifications_disabled = var.daily_data_cap_notifications_disabled
  
  internet_ingestion_enabled = var.internet_ingestion_enabled
  internet_query_enabled     = var.internet_query_enabled
  
  local_authentication_disabled = var.local_authentication_disabled
  
  tags = merge(
    var.tags,
    {
      Purpose = "Application Telemetry"
    }
  )
}
