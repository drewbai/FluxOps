output "storage_account_name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.main.name
}

output "storage_account_id" {
  description = "ID of the storage account"
  value       = azurerm_storage_account.main.id
}

output "primary_blob_endpoint" {
  description = "Primary blob endpoint"
  value       = azurerm_storage_account.main.primary_blob_endpoint
}

output "primary_access_key" {
  description = "Primary access key"
  value       = azurerm_storage_account.main.primary_access_key
  sensitive   = true
}

output "connection_string" {
  description = "Storage account connection string"
  value       = azurerm_storage_account.main.primary_connection_string
  sensitive   = true
}

output "models_container_name" {
  description = "Name of the models container"
  value       = azurerm_storage_container.models.name
}

output "logs_container_name" {
  description = "Name of the logs container"
  value       = azurerm_storage_container.logs.name
}

output "data_container_name" {
  description = "Name of the data container"
  value       = azurerm_storage_container.data.name
}
