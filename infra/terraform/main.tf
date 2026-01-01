terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
  }

  # Uncomment below to use Azure Storage for remote state
  # backend "azurerm" {
  #   resource_group_name  = "terraform-state-rg"
  #   storage_account_name = "tfstatexxxxxx"
  #   container_name       = "tfstate"
  #   key                  = "fluxops.tfstate"
  # }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

# Local variables
locals {
  project_name = var.project_name
  environment  = var.environment

  common_tags = merge(
    var.tags,
    {
      Project     = local.project_name
      Environment = local.environment
      ManagedBy   = "Terraform"
      Repository  = "FluxOps"
    }
  )

  # Generate unique names with prefix
  resource_group_name          = "${local.project_name}-${local.environment}-rg"
  storage_account_name         = lower(replace("${local.project_name}${local.environment}sa", "-", ""))
  key_vault_name               = "${local.project_name}-${local.environment}-kv"
  function_app_name            = "${local.project_name}-${local.environment}-func"
  app_service_plan_name        = "${local.project_name}-${local.environment}-plan"
  app_insights_name            = "${local.project_name}-${local.environment}-ai"
  log_analytics_workspace_name = "${local.project_name}-${local.environment}-law"
}

# Resource Group Module
module "resource_group" {
  source = "./modules/resource_group"

  resource_group_name = local.resource_group_name
  location            = var.location
  tags                = local.common_tags
}

# Application Insights Module
module "app_insights" {
  source = "./modules/app_insights"

  app_insights_name            = local.app_insights_name
  log_analytics_workspace_name = local.log_analytics_workspace_name
  resource_group_name          = module.resource_group.resource_group_name
  location                     = var.location
  tags                         = local.common_tags

  depends_on = [module.resource_group]
}

# Storage Module
module "storage" {
  source = "./modules/storage"

  storage_account_name = local.storage_account_name
  resource_group_name  = module.resource_group.resource_group_name
  location             = var.location
  account_tier         = var.storage_account_tier
  replication_type     = var.storage_replication_type
  tags                 = local.common_tags

  depends_on = [module.resource_group]
}

# Key Vault Module
module "key_vault" {
  source = "./modules/key_vault"

  key_vault_name            = local.key_vault_name
  resource_group_name       = module.resource_group.resource_group_name
  location                  = var.location
  storage_connection_string = module.storage.connection_string
  storage_account_key       = module.storage.primary_access_key
  tags                      = local.common_tags

  depends_on = [module.resource_group, module.storage]
}

# Function App Module
module "function_app" {
  source = "./modules/function_app"

  function_app_name                = local.function_app_name
  app_service_plan_name            = local.app_service_plan_name
  resource_group_name              = module.resource_group.resource_group_name
  location                         = var.location
  sku_name                         = var.function_app_sku
  storage_account_name             = module.storage.storage_account_name
  storage_account_access_key       = module.storage.primary_access_key
  storage_connection_string        = module.storage.connection_string
  key_vault_uri                    = module.key_vault.key_vault_uri
  app_insights_connection_string   = module.app_insights.connection_string
  app_insights_instrumentation_key = module.app_insights.instrumentation_key
  tags                             = local.common_tags

  depends_on = [
    module.resource_group,
    module.storage,
    module.key_vault,
    module.app_insights
  ]
}

# Grant Function App access to Key Vault
resource "azurerm_key_vault_access_policy" "function_app" {
  key_vault_id = module.key_vault.key_vault_id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = module.function_app.function_app_principal_id

  secret_permissions = [
    "Get",
    "List"
  ]

  depends_on = [module.function_app]
}

data "azurerm_client_config" "current" {}
