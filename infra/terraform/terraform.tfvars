# FluxOps Terraform Configuration
# This configuration sets environment-specific values

# Project Configuration
project_name = "fluxops"
environment  = "dev"
location     = "eastus"

# Storage Configuration
storage_account_tier      = "Standard"
storage_replication_type  = "LRS"

# Function App Configuration
function_app_sku = "B1"

# Custom Tags
tags = {
  Owner       = "MLOps Team"
  CostCenter  = "Engineering"
  Compliance  = "Standard"
}
