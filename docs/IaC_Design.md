# Infrastructure as Code Design - FluxOps

## Overview

This document outlines the Infrastructure as Code (IaC) design for the FluxOps ML pipeline project, built using Terraform and following modular architecture principles.

---

## Design Philosophy

### Core Principles

1. **Modularity**: Each Azure resource type is encapsulated in a reusable module
2. **Separation of Concerns**: Infrastructure logic separated from application code
3. **DRY (Don't Repeat Yourself)**: Common configurations defined once, used everywhere
4. **Security by Default**: Secure configurations as baseline
5. **Scalability**: Designed to grow from dev to production

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    Root Configuration                        │
│                       (main.tf)                              │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │              Local Variables & Tags                  │  │
│  │  • Project naming conventions                        │  │
│  │  • Environment-specific configs                      │  │
│  │  • Common tags (Project, Environment, ManagedBy)     │  │
│  └──────────────────────────────────────────────────────┘  │
│                           │                                  │
│                           ▼                                  │
│  ┌───────────────────────────────────────────────────────┐ │
│  │                 Module: Resource Group                │ │
│  │  • Creates resource group                            │ │
│  │  • Sets location and tags                            │ │
│  │  Outputs: RG name, ID, location                      │ │
│  └────────────────────┬──────────────────────────────────┘ │
│                       │                                     │
│         ┌─────────────┼─────────────┐                      │
│         ▼             ▼             ▼                      │
│  ┌──────────┐  ┌───────────┐  ┌────────────┐             │
│  │ Storage  │  │    Key    │  │    App     │             │
│  │ Module   │  │   Vault   │  │  Insights  │             │
│  │          │  │  Module   │  │   Module   │             │
│  └────┬─────┘  └─────┬─────┘  └──────┬─────┘             │
│       │              │                │                    │
│       └──────────────┴────────────────┘                    │
│                      │                                     │
│                      ▼                                     │
│             ┌─────────────────┐                           │
│             │   Function App  │                           │
│             │     Module      │                           │
│             │                 │                           │
│             └─────────────────┘                           │
│                                                            │
└─────────────────────────────────────────────────────────────┘
```

---

## Module Structure

### 1. Resource Group Module

**Purpose**: Creates and manages Azure Resource Group

**Location**: `infra/terraform/modules/resource_group/`

**Files**:
- `main.tf`: Resource definitions
- `variables.tf`: Input parameters
- `outputs.tf`: Exported values

**Key Resources**:
```hcl
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}
```

**Design Decisions**:
- Single responsibility: Only manages RG creation
- Location and tags configurable
- All other modules depend on this

---

### 2. Storage Module

**Purpose**: Provisions Azure Storage Account with blob containers

**Location**: `infra/terraform/modules/storage/`

**Key Features**:
- TLS 1.2 minimum version enforcement
- Blob versioning enabled
- 7-day delete retention policy
- Three containers: `models`, `logs`, `data`

**Resource Hierarchy**:
```
Storage Account
├── Container: models (ML model artifacts)
├── Container: logs (Pipeline logs)
└── Container: data (Training data)
```

**Design Decisions**:
- **Private Access**: All containers set to private
- **Versioning**: Enabled for audit trail
- **Retention**: 7-day soft delete for disaster recovery
- **Naming**: Lowercase, no special characters (Azure requirement)

**Security Configuration**:
```hcl
min_tls_version = "TLS1_2"
blob_properties {
  versioning_enabled = true
  delete_retention_policy {
    days = 7
  }
}
```

---

### 3. Key Vault Module

**Purpose**: Manages secrets and sensitive configuration

**Location**: `infra/terraform/modules/key_vault/`

**Stored Secrets**:
1. `storage-connection-string`: Full storage connection string
2. `storage-account-key`: Primary access key

**Access Policies**:

1. **Deployer (Service Principal)**:
   - Full secret permissions
   - Required for Terraform to manage secrets

2. **Function App (Managed Identity)**:
   - Get and List secrets only
   - Follows least privilege principle

**Design Decisions**:
- **Soft Delete**: 7-day retention (configurable)
- **Purge Protection**: Disabled for dev/test (enable for prod)
- **Dynamic Access Policies**: Automatically grants Function App access

**Security Features**:
```hcl
soft_delete_retention_days = 7
purge_protection_enabled   = false  # Set true for production
```

---

### 4. Function App Module

**Purpose**: Deploys Python-based Azure Function for ML inference

**Location**: `infra/terraform/modules/function_app/`

**Components**:
1. **App Service Plan**: Linux-based, configurable SKU
2. **Function App**: Python 3.11 runtime
3. **System-Assigned Identity**: For accessing Key Vault

**Application Settings**:
```hcl
app_settings = {
  "STORAGE_CONNECTION_STRING"           = var.storage_connection_string
  "KEY_VAULT_URI"                       = var.key_vault_uri
  "FUNCTIONS_WORKER_RUNTIME"            = "python"
  "AzureWebJobsFeatureFlags"            = "EnableWorkerIndexing"
  "APPINSIGHTS_CONNECTION_STRING"       = var.app_insights_connection_string
}
```

**Design Decisions**:
- **Linux OS**: Better Python runtime support
- **Managed Identity**: No credentials in code
- **App Insights Integration**: Built-in monitoring
- **Worker Indexing**: Faster cold start times

**Site Configuration**:
```hcl
site_config {
  application_stack {
    python_version = "3.11"
  }
}
```

---

### 5. Application Insights Module

**Purpose**: Monitoring and telemetry collection

**Location**: `infra/terraform/modules/app_insights/`

**Components**:
1. **Log Analytics Workspace**: Data storage backend
2. **Application Insights**: Telemetry collection

**Configuration**:
```hcl
sku                = "PerGB2018"
retention_in_days  = 30
application_type   = "web"
```

**Design Decisions**:
- **Workspace-based**: Modern architecture, better querying
- **30-day retention**: Balance cost vs. observability
- **Web application type**: Optimized for HTTP workloads

---

## Root Configuration

**Location**: `infra/terraform/main.tf`

### Local Variables

Generates consistent naming across resources:

```hcl
locals {
  project_name = var.project_name
  environment  = var.environment
  
  common_tags = {
    Project     = local.project_name
    Environment = local.environment
    ManagedBy   = "Terraform"
    Repository  = "FluxOps"
  }
  
  # Auto-generated names
  resource_group_name  = "${local.project_name}-${local.environment}-rg"
  storage_account_name = lower(replace("${local.project_name}${local.environment}sa", "-", ""))
  # ... more names
}
```

### Module Orchestration

Dependencies explicitly defined:

```hcl
module "storage" {
  source = "./modules/storage"
  # ... configuration
  depends_on = [module.resource_group]
}

module "function_app" {
  source = "./modules/function_app"
  # ... configuration
  depends_on = [
    module.storage,
    module.key_vault,
    module.app_insights
  ]
}
```

---

## Dependency Graph

```
Resource Group (base)
    │
    ├──> Storage Account
    │       │
    │       └──> Key Vault (stores storage secrets)
    │               │
    ├──> App Insights
    │       │
    └───────┴──────> Function App (depends on all above)
                         │
                         └──> Key Vault Access Policy (grants permissions)
```

**Critical Path**:
1. Resource Group must exist first
2. Storage and App Insights can be created in parallel
3. Key Vault requires Storage secrets
4. Function App requires all dependencies
5. Access policy grants Function App → Key Vault access

---

## Variable Management

### Input Variables (`variables.tf`)

```hcl
variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "fluxops"
}

variable "environment" {
  description = "Environment (dev/staging/prod)"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus"
}
```

### Variable Files

- `terraform.tfvars`: Default values
- `dev.tfvars`: Development overrides
- `prod.tfvars`: Production overrides

**Usage**:
```bash
terraform apply -var-file=prod.tfvars
```

---

## State Management

### Local State (Default)

```hcl
# Stored in: terraform.tfstate
# Best for: Single-user, testing
```

### Remote State (Recommended for Teams)

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstatexxxxxx"
    container_name       = "tfstate"
    key                  = "fluxops.tfstate"
  }
}
```

**Benefits**:
- Team collaboration
- State locking
- Encryption at rest
- Audit trail

---

## Security Considerations

### 1. Secret Management

- ✅ No secrets in Terraform code
- ✅ Secrets stored in Key Vault
- ✅ Managed identities for authentication
- ✅ GitLab CI/CD variables for service principal

### 2. Access Control

- ✅ RBAC on all resources
- ✅ Least privilege principle
- ✅ Separate identities for deploy vs. runtime

### 3. Network Security

- ✅ TLS 1.2+ enforcement
- ✅ Private container access
- ✅ HTTPS for Function App endpoints

### 4. Compliance

- ✅ Soft delete enabled
- ✅ Versioning for blobs
- ✅ Audit logs via App Insights
- ✅ Tag-based resource tracking

---

## Scalability Patterns

### Horizontal Scaling

- Function App scales automatically (Consumption/Premium)
- Storage account supports millions of objects
- Key Vault handles high request volumes

### Environment Promotion

```bash
# Development
terraform apply -var-file=dev.tfvars

# Staging
terraform apply -var-file=staging.tfvars

# Production
terraform apply -var-file=prod.tfvars
```

### Multi-Region Deployment

- Replicate modules in different regions
- Use geo-redundant storage (GRS)
- Azure Front Door for global routing

---

## Cost Optimization

### Resource SKU Selection

| Environment | Function App SKU | Storage Tier | Retention |
|-------------|------------------|--------------|-----------|
| Dev         | B1 (Basic)       | Standard LRS | 7 days    |
| Staging     | S1 (Standard)    | Standard ZRS | 30 days   |
| Production  | P1V2 (Premium)   | Premium LRS  | 90 days   |

### Cost-Saving Tips

1. **Use tags** for cost allocation
2. **Enable autoscaling** for Function App
3. **Lifecycle policies** for old blobs
4. **Reserved instances** for prod workloads

---

## Testing Strategy

### 1. Static Analysis

```bash
terraform fmt -check
terraform validate
tflint
```

### 2. Plan Review

```bash
terraform plan -out=tfplan
terraform show tfplan
```

### 3. Automated Tests

- CI/CD pipeline validates on every commit
- Syntax checks in validate stage
- Deployment tests in test stage

### 4. Manual Testing

```bash
# Deploy to test environment
terraform apply -var-file=test.tfvars

# Run validation scripts
./scripts/validate-infrastructure.sh

# Cleanup
terraform destroy -var-file=test.tfvars
```

---

## Maintenance & Operations

### Updating Infrastructure

1. Modify Terraform code
2. Run `terraform plan` to preview changes
3. Review plan output carefully
4. Apply changes via CI/CD or manually
5. Monitor Application Insights for issues

### Rollback Procedure

```bash
# Revert to previous state
git checkout <previous-commit>
terraform apply

# Or destroy and recreate
terraform destroy
git checkout <stable-version>
terraform apply
```

### Monitoring Changes

- Track Terraform state changes
- Review Azure Activity Log
- Application Insights for runtime issues

---

## Lessons Learned

### What Worked Well

✅ **Modular design**: Easy to reuse and test  
✅ **Explicit dependencies**: Clear deployment order  
✅ **Local variables**: Consistent naming  
✅ **Comprehensive outputs**: Easy integration  

### Challenges & Solutions

❌ **Challenge**: Storage account names must be globally unique  
✅ **Solution**: Generate unique names using project + environment  

❌ **Challenge**: Key Vault soft delete prevents immediate recreation  
✅ **Solution**: Purge Key Vault explicitly or wait retention period  

❌ **Challenge**: Function App cold starts  
✅ **Solution**: Enable Worker Indexing, consider Premium plan  

### Future Improvements

- [ ] Add VNet integration
- [ ] Implement private endpoints
- [ ] Multi-region deployment
- [ ] Automated disaster recovery
- [ ] Cost alerting via Azure Budget

---

## References

- [Terraform Best Practices](https://www.terraform-best-practices.com/)
- [Azure Naming Conventions](https://docs.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/naming-and-tagging)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure Well-Architected Framework](https://docs.microsoft.com/azure/architecture/framework/)

---

**Document Version**: 1.0  
**Last Updated**: November 2025  
**Author**: MLOps Team
