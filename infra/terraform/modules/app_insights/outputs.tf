output "app_insights_id" {
  description = "ID of Application Insights"
  value       = azurerm_application_insights.main.id
}

output "app_insights_name" {
  description = "Name of Application Insights"
  value       = azurerm_application_insights.main.name
}

output "instrumentation_key" {
  description = "Instrumentation key for Application Insights"
  value       = azurerm_application_insights.main.instrumentation_key
  sensitive   = true
}

output "connection_string" {
  description = "Connection string for Application Insights"
  value       = azurerm_application_insights.main.connection_string
  sensitive   = true
}

output "app_id" {
  description = "Application ID"
  value       = azurerm_application_insights.main.app_id
}
