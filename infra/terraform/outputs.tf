output "resource_group_name" {
  description = "Name of the resource group"
  value       = module.resource_group.resource_group_name
}

output "storage_account_name" {
  description = "Name of the storage account"
  value       = module.storage.storage_account_name
}

output "storage_connection_string" {
  description = "Storage account connection string"
  value       = module.storage.connection_string
  sensitive   = true
}

output "key_vault_name" {
  description = "Name of the Key Vault"
  value       = module.key_vault.key_vault_name
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = module.key_vault.key_vault_uri
}

output "function_app_name" {
  description = "Name of the Function App"
  value       = module.function_app.function_app_name
}

output "function_app_url" {
  description = "URL of the Function App"
  value       = "https://${module.function_app.function_app_default_hostname}"
}

output "app_insights_name" {
  description = "Name of Application Insights"
  value       = module.app_insights.app_insights_name
}

output "app_insights_app_id" {
  description = "Application Insights App ID"
  value       = module.app_insights.app_id
}

output "models_container_name" {
  description = "Name of the models blob container"
  value       = module.storage.models_container_name
}

output "logs_container_name" {
  description = "Name of the logs blob container"
  value       = module.storage.logs_container_name
}

output "data_container_name" {
  description = "Name of the data blob container"
  value       = module.storage.data_container_name
}
