resource "azurerm_service_plan" "main" {
  name                = var.app_service_plan_name
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Linux"
  sku_name            = var.sku_name

  tags = var.tags
}

resource "azurerm_linux_function_app" "main" {
  name                       = var.function_app_name
  location                   = var.location
  resource_group_name        = var.resource_group_name
  service_plan_id            = azurerm_service_plan.main.id
  storage_account_name       = var.storage_account_name
  storage_account_access_key = var.storage_account_access_key

  site_config {
    application_stack {
      python_version = "3.11"
    }

    application_insights_connection_string = var.app_insights_connection_string
    application_insights_key               = var.app_insights_instrumentation_key
  }

  app_settings = {
    "STORAGE_CONNECTION_STRING" = var.storage_connection_string
    "KEY_VAULT_URI"             = var.key_vault_uri
    "FUNCTIONS_WORKER_RUNTIME"  = "python"
    "AzureWebJobsFeatureFlags"  = "EnableWorkerIndexing"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}
