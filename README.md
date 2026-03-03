# 🚀 FluxOps - ML Pipeline Automation with Terraform & GitHub Actions

[![GitHub Actions](https://img.shields.io/badge/GitHub-Actions-blue?logo=github)](https://github.com/features/actions)
[![Terraform](https://img.shields.io/badge/Terraform-1.5+-purple?logo=terraform)](https://terraform.io)
[![Azure](https://img.shields.io/badge/Azure-Cloud-blue?logo=microsoft-azure)](https://azure.microsoft.com)
[![Python](https://img.shields.io/badge/Python-3.11-blue?logo=python)](https://python.org)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**FluxOps** is a production-ready ML pipeline infrastructure demonstrating modern DevOps and MLOps best practices. This project showcases **Infrastructure as Code (IaC)** with Terraform, **automated CI/CD** with GitHub Actions, and **serverless ML deployment** on Azure.

> **📚 Quick Links**: 
> - [Project Overview](./PROJECT_OVERVIEW.md) - High-level summary and features
> - [Quick Start Guide](./QUICKSTART.md) - 5-minute setup instructions
> - [Deployment Checklist](./DEPLOYMENT_CHECKLIST.md) - Step-by-step deployment guide

---

## 🎯 Project Goals

Build and automate an end-to-end ML pipeline infrastructure demonstrating:

- ✅ **Reproducible Infrastructure** - 100% Terraform-managed resources
- ✅ **Modular Design** - Reusable Terraform modules
- ✅ **Automated CI/CD** - Complete GitHub Actions pipeline
- ✅ **Secure by Default** - Azure Key Vault, managed identities, RBAC
- ✅ **Production-Ready** - Monitoring, testing, error handling
- ✅ **Cost-Effective** - ~$17/month for dev environment

---

## 🏗️ Architecture

### High-Level Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                       GitHub Actions                            │
│  Validate → Plan → Deploy → Test → Destroy                     │
└─────────────────┬───────────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Azure Infrastructure                         │
│                                                                 │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐     │
│  │   Resource   │    │   Storage    │    │  Key Vault   │     │
│  │    Group     │───▶│   Account    │───▶│   Secrets    │     │
│  └──────────────┘    │              │    └──────────────┘     │
│                      │ • Models     │                         │
│                      │ • Logs       │                         │
│                      │ • Data       │                         │
│                      └──────┬───────┘                         │
│                             │                                 │
│  ┌──────────────┐    ┌──────┴───────┐    ┌──────────────┐   │
│  │     App      │    │   Function   │    │   Azure ML   │   │
│  │   Insights   │◀───│     App      │───▶│  (Optional)  │   │
│  │  Monitoring  │    │   (Python)   │    │   Registry   │   │
│  └──────────────┘    └──────────────┘    └──────────────┘   │
│                                                               │
└─────────────────────────────────────────────────────────────────┘
```

### Core Components

| Component | Purpose | Technology |
|-----------|---------|------------|
| **Terraform** | Infrastructure provisioning | HashiCorp Terraform 1.5+ |
| **GitHub Actions** | CI/CD automation | GitHub Workflows |
| **Azure Storage** | Model & log persistence | Azure Blob Storage |
| **Key Vault** | Secrets management | Azure Key Vault |
| **Function App** | ML inference API | Azure Functions (Python 3.11) |
| **App Insights** | Monitoring & observability | Azure Application Insights |
| **Azure ML** | Model registry (optional) | Azure Machine Learning |

---

## 🛠️ Tech Stack

### Infrastructure & DevOps
- **Terraform 1.5+** - Infrastructure as Code
- **GitHub Actions** - CI/CD automation
- **Azure CLI 2.50+** - Cloud management
- **PowerShell/Bash** - Scripting

### Application & ML
- **Python 3.11** - Primary language
- **scikit-learn** - Machine learning framework
- **Azure Functions** - Serverless compute
- **NumPy/Pandas** - Data processing

### Monitoring & Testing
- **Application Insights** - Telemetry & monitoring
- **pytest** - Unit testing framework
- **pytest-cov** - Code coverage reporting

---

## 📦 Project Structure

```
FluxOps/
├── .github/
│   └── workflows/
│       └── fluxops-pipeline.yml   # GitHub Actions CI/CD pipeline
├── infra/
│   └── terraform/
│       ├── main.tf                # Root infrastructure orchestration
│       ├── variables.tf           # Input variables
│       ├── outputs.tf             # Output values
│       ├── terraform.tfvars       # Variable values (customize this)
│       └── modules/
│           ├── resource_group/    # Resource Group module
│           ├── storage/           # Storage Account module
│           ├── key_vault/         # Key Vault module
│           ├── function_app/      # Function App module
│           └── app_insights/      # Application Insights module
├── src/
│   ├── ml_pipeline/
│   │   ├── train_model.py         # Model training script
│   │   ├── inference.py           # Inference utilities
│   │   ├── requirements.txt       # Python dependencies
│   │   └── tests/
│   │       └── test_pipeline.py   # Unit tests
│   └── function_app/
│       ├── function_app.py        # Azure Function endpoints
│       ├── requirements.txt       # Function dependencies
│       ├── host.json              # Function runtime config
│       └── local.settings.json    # Local development settings
├── scripts/
│   ├── hydrate.ps1                # Provision Azure resources
│   ├── dehydrate.ps1              # Tear down Azure resources
│   ├── validate-setup.ps1         # Validate prerequisites (Windows)
│   ├── validate-setup.sh          # Validate prerequisites (Linux/Mac)
│   └── upload_model_to_azurite.py # Local testing utility
├── docs/
│   ├── IaC_Design.md              # Infrastructure design doc
│   ├── Pipeline_Logic.md          # Pipeline workflow doc
│   ├── Case_Study.md              # Use cases & lessons learned
│   └── CI_CD_Comparison.md        # CI/CD platform comparison
├── README.md                      # This file
├── PROJECT_OVERVIEW.md            # High-level summary
├── QUICKSTART.md                  # Quick start guide
├── DEPLOYMENT_CHECKLIST.md        # Deployment checklist
└── LICENSE                        # MIT License
```

---

## 🚀 Getting Started

### Prerequisites

- **Azure Account** with active subscription
- **GitHub Account** for CI/CD
- **Terraform** >= 1.5.0 ([Download](https://terraform.io/downloads))
- **Azure CLI** >= 2.50.0 ([Download](https://docs.microsoft.com/cli/azure/install-azure-cli))
- **Python** 3.11 ([Download](https://python.org/downloads))
- **Git** ([Download](https://git-scm.com/downloads))

### Validation Script

Run the validation script to check prerequisites:

**Windows (PowerShell):**
```powershell
.\scripts\validate-setup.ps1
```

**Linux/Mac (Bash):**
```bash
chmod +x scripts/validate-setup.sh
./scripts/validate-setup.sh
```

### Azure Authentication Setup

1. **Login to Azure:**
```bash
az login
az account set --subscription "<your-subscription-id>"
```

2. **Create Service Principal:**
```bash
az ad sp create-for-rbac --name "fluxops-sp" \
  --role="Contributor" \
  --scopes="/subscriptions/<your-subscription-id>"
```

3. **Configure GitHub Secrets:**

Navigate to: **GitHub Repository → Settings → Secrets and variables → Actions**

Add these repository secrets:
- `ARM_CLIENT_ID` - Application (client) ID
- `ARM_CLIENT_SECRET` - Client secret value
- `ARM_TENANT_ID` - Directory (tenant) ID
- `ARM_SUBSCRIPTION_ID` - Your subscription ID
- `AZURE_SUBSCRIPTION_ID` - Same as ARM_SUBSCRIPTION_ID

### Local Development

1. **Clone the repository:**
```bash
git clone https://github.com/<your-username>/FluxOps.git
cd FluxOps
```

2. **Initialize Terraform:**
```bash
cd infra/terraform
terraform init
```

3. **Validate configuration:**
```bash
terraform validate
terraform fmt -check
```

4. **Plan infrastructure:**
```bash
terraform plan
```

5. **Apply infrastructure:**
```bash
terraform apply
# Review the plan and type 'yes' to confirm
```

6. **Test ML pipeline locally:**
```bash
cd ../../src/ml_pipeline
python -m venv .venv
.venv\Scripts\activate  # Windows
# source .venv/bin/activate  # Linux/Mac
pip install -r requirements.txt
python train_model.py
pytest tests/ -v
```

7. **Test Function App locally:**
```bash
cd ../function_app
pip install -r requirements.txt
func start
```

---

## 🔄 CI/CD Pipeline

The GitHub Actions pipeline automates the entire deployment lifecycle with 5 stages:

### 1️⃣ **Validate Stage**
- Runs `terraform fmt -check`
- Runs `terraform validate`
- **Triggers:** Pull requests, main, develop branches

### 2️⃣ **Plan Stage**
- Generates Terraform execution plan
- Uploads plan as artifact
- **Triggers:** All branches

### 3️⃣ **Deploy Stage**
- Applies Terraform infrastructure
- Deploys Function App code
- Trains and uploads ML model
- **Triggers:** 
  - `main` branch (requires manual approval)
  - `develop` branch (automatic)

### 4️⃣ **Test Stage**
- Validates infrastructure resources
- Tests Function App endpoints
- Runs ML pipeline unit tests
- Generates code coverage reports
- **Triggers:** After successful deployment

### 5️⃣ **Destroy Stage**
- Tears down all infrastructure
- **Triggers:** Manual workflow dispatch only

### Pipeline Workflow Diagram

```
┌────────────┐     ┌────────────┐     ┌────────────┐
│  Validate  │────▶│    Plan    │────▶│   Deploy   │
│   Format   │     │ Terraform  │     │    Infra   │
│   Syntax   │     │    Plan    │     │    Code    │
└────────────┘     └────────────┘     └──────┬─────┘
                                              │
                                              ▼
                   ┌────────────┐     ┌────────────┐
                   │  Destroy   │◀────│    Test    │
                   │  (Manual)  │     │   Health   │
                   │   Cleanup  │     │   Tests    │
                   └────────────┘     └────────────┘
```

---

## 📊 Infrastructure Modules

### Resource Group Module
**Purpose:** Creates Azure Resource Group for organizing resources

**Inputs:**
- `resource_group_name` - Name of the resource group
- `location` - Azure region (e.g., "eastus")
- `tags` - Resource tags for organization

**Outputs:**
- `resource_group_name` - Resource group name
- `resource_group_id` - Resource group ID
- `location` - Deployment region

### Storage Module
**Purpose:** Provisions Storage Account with blob containers

**Blob Containers:**
- `models` - ML model artifacts (.pkl files)
- `logs` - Pipeline execution logs
- `data` - Training/inference datasets

**Inputs:**
- `storage_account_name` - Unique storage account name
- `account_tier` - Performance tier (Standard/Premium)
- `replication_type` - Replication strategy (LRS/GRS/ZRS)

**Outputs:**
- `storage_account_name` - Storage account name
- `connection_string` - Storage connection string
- `container_names` - List of container names

### Key Vault Module
**Purpose:** Creates Azure Key Vault for secure secret storage

**Secrets Stored:**
- `storage-connection-string` - Storage account connection
- `storage-account-key` - Storage account access key

**Inputs:**
- `key_vault_name` - Unique Key Vault name
- `storage_connection_string` - Storage connection to store

**Outputs:**
- `key_vault_uri` - Key Vault URI
- `key_vault_name` - Key Vault name

### Function App Module
**Purpose:** Deploys Linux-based Azure Function App with Python runtime

**Features:**
- System-assigned managed identity
- Application Insights integration
- Environment variables for Key Vault and Storage
- Python 3.11 runtime

**API Endpoints:**
- `GET /api/health` - Health check endpoint
- `POST /api/predict` - ML prediction endpoint
- `GET /api/model-info` - Model metadata endpoint

**Inputs:**
- `function_app_name` - Unique Function App name
- `app_service_plan_sku` - SKU tier (Y1/B1/P1v2)
- `storage_account_name` - Storage account reference

**Outputs:**
- `function_app_name` - Function App name
- `function_app_url` - Function App URL
- `function_app_identity` - Managed identity details

### Application Insights Module
**Purpose:** Sets up monitoring and telemetry collection

**Metrics Tracked:**
- Function execution times
- Request rates and patterns
- Error rates and exceptions
- Custom events and traces

**Inputs:**
- `app_insights_name` - Application Insights name
- `application_type` - Application type (e.g., "web")

**Outputs:**
- `instrumentation_key` - Instrumentation key
- `app_insights_id` - Application Insights resource ID

---

## 🧪 Testing

### Unit Tests

Run the ML pipeline unit tests:

```bash
cd src/ml_pipeline
pytest tests/ -v --cov=. --cov-report=html
```

**Test Coverage:**
- Model training validation
- Inference accuracy tests
- Data preprocessing tests
- Error handling scenarios

### Infrastructure Tests

Automated in CI/CD pipeline:
- Resource provisioning validation
- Endpoint health checks
- Secret accessibility tests
- Configuration validation

### Function App Testing

**Health Endpoint:**
```bash
curl https://<function-app-name>.azurewebsites.net/api/health
```

**Expected Response:**
```json
{
  "status": "healthy",
  "timestamp": "2026-01-23T10:30:00Z",
  "version": "1.0.0"
}
```

**Prediction Endpoint:**
```bash
curl -X POST https://<function-app-name>.azurewebsites.net/api/predict \
  -H "Content-Type: application/json" \
  -d '{
    "features": [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0]
  }'
```

**Expected Response:**
```json
{
  "prediction": 0.685,
  "model_version": "1.0.0",
  "timestamp": "2026-01-23T10:31:00Z"
}
```

---

## 🔐 Security Best Practices

### 1. Secrets Management
- ✅ All secrets stored in Azure Key Vault
- ✅ No secrets in code or version control
- ✅ GitHub secrets marked as encrypted
- ✅ Automatic secret rotation support

### 2. Access Control
- ✅ Managed identities for Function App (no credentials)
- ✅ RBAC (Role-Based Access Control) for resources
- ✅ Least privilege principle
- ✅ Service principal with minimal permissions

### 3. Network Security
- ✅ HTTPS enforcement (TLS 1.2+)
- ✅ Storage account firewall (configurable)
- ✅ Private endpoints support (optional)
- ✅ API authentication options

### 4. Compliance & Auditing
- ✅ Blob versioning enabled
- ✅ Soft delete for Key Vault secrets
- ✅ Audit logs via Application Insights
- ✅ Resource tagging for governance

---

## 📈 Monitoring & Observability

### Application Insights Metrics

**Availability:**
- Function App uptime percentage
- Endpoint availability monitoring
- Response time tracking

**Performance:**
- Average response times
- Request throughput
- Dependency duration

**Errors:**
- Exception tracking
- Failure rates
- Error categorization

**Usage:**
- Request patterns
- User analytics
- Custom event tracking

### Log Analytics Queries

Access logs via Azure Portal → Application Insights → Logs:

**Recent Predictions:**
```kusto
traces
| where timestamp > ago(1h)
| where message contains "prediction"
| project timestamp, message, severityLevel
| order by timestamp desc
```

**Error Analysis:**
```kusto
exceptions
| where timestamp > ago(24h)
| summarize count() by type, outerMessage
| order by count_ desc
```

**Performance Metrics:**
```kusto
requests
| where timestamp > ago(1h)
| summarize avg(duration), percentile(duration, 95) by name
```

---

## 🔧 Configuration

### Terraform Variables

Edit `infra/terraform/terraform.tfvars`:

```hcl
# Project Settings
project_name = "fluxops"
environment  = "dev"
location     = "eastus"

# Storage Configuration
storage_account_tier     = "Standard"
storage_replication_type = "LRS"

# Function App Configuration
function_app_sku = "B1"  # Y1 (Consumption), B1 (Basic), P1v2 (Premium)

# Resource Tagging
tags = {
  Owner       = "MLOps Team"
  CostCenter  = "Engineering"
  Environment = "Development"
  Project     = "FluxOps"
}
```

### Environment-Specific Configurations

Create separate variable files for different environments:

**dev.tfvars:**
```hcl
environment              = "dev"
function_app_sku         = "B1"
storage_replication_type = "LRS"
```

**staging.tfvars:**
```hcl
environment              = "staging"
function_app_sku         = "P1v2"
storage_replication_type = "GRS"
```

**prod.tfvars:**
```hcl
environment              = "prod"
function_app_sku         = "P2v2"
storage_replication_type = "GRS"
enable_private_endpoints = true
```

**Usage:**
```bash
terraform apply -var-file=prod.tfvars
```

---

## 💰 Cost Estimation

### Development Environment (~$17/month)

| Resource | SKU | Monthly Cost |
|----------|-----|--------------|
| Resource Group | - | Free |
| Storage Account | Standard LRS | ~$1 |
| Key Vault | Standard | ~$0.50 |
| Function App | B1 Plan | ~$13 |
| Application Insights | Standard | ~$2.50 |
| **Total** | | **~$17** |

### Production Environment (~$150/month)

| Resource | SKU | Monthly Cost |
|----------|-----|--------------|
| Storage Account | Standard GRS | ~$5 |
| Key Vault | Premium | ~$2 |
| Function App | P1v2 Plan | ~$120 |
| Application Insights | Standard | ~$20 |
| Private Endpoints | Optional | ~$7 |
| **Total** | | **~$154** |

**Cost Optimization Tips:**
- Use Consumption plan (Y1) for low-traffic scenarios
- Enable auto-scaling for Function Apps
- Set retention policies for logs
- Use Azure Cost Management alerts

---

## 🗑️ Cleanup

### Manual Cleanup (Local)

```bash
cd infra/terraform
terraform destroy
```

Review the resources to be destroyed and type `yes` to confirm.

### GitHub Actions Cleanup

1. Navigate to: **Actions** tab
2. Select **"FluxOps Pipeline"** workflow
3. Click **"Run workflow"**
4. Select **"Destroy"** option
5. Confirm destruction

### Cost Verification

After cleanup, verify no resources remain:

```bash
az resource list --resource-group fluxops-dev-rg
```

Expected output: Empty list or "Resource group not found"

---

## 📚 Documentation

### Quick References
- [README.md](./README.md) - This file
- [PROJECT_OVERVIEW.md](./PROJECT_OVERVIEW.md) - High-level project summary
- [QUICKSTART.md](./QUICKSTART.md) - 5-minute setup guide
- [DEPLOYMENT_CHECKLIST.md](./DEPLOYMENT_CHECKLIST.md) - Step-by-step deployment

### Deep Dive Documentation
- [IaC_Design.md](./docs/IaC_Design.md) - Terraform architecture & modules
- [Pipeline_Logic.md](./docs/Pipeline_Logic.md) - CI/CD workflow details
- [Case_Study.md](./docs/Case_Study.md) - Use cases, ROI, lessons learned
- [CI_CD_Comparison.md](./docs/CI_CD_Comparison.md) - CI/CD platform comparison

---

## 🎓 Learning Outcomes

This project demonstrates proficiency in:

- ✅ **Infrastructure as Code** - Modular Terraform design with reusable modules
- ✅ **CI/CD Automation** - Complete GitHub Actions pipeline implementation
- ✅ **Cloud-Native Architecture** - Serverless ML deployment on Azure
- ✅ **Security Engineering** - Secrets management, RBAC, managed identities
- ✅ **Observability** - Comprehensive monitoring and logging
- ✅ **Testing** - Infrastructure and application testing
- ✅ **Documentation** - Clear, maintainable technical documentation
- ✅ **DevOps Best Practices** - Automation, reproducibility, version control

---

## 🤝 Contributing

Contributions are welcome! Please follow these guidelines:

1. **Fork the repository**
2. **Create a feature branch:**
   ```bash
   git checkout -b feature/amazing-feature
   ```
3. **Make your changes** and commit:
   ```bash
   git commit -m 'Add amazing feature'
   ```
4. **Push to your branch:**
   ```bash
   git push origin feature/amazing-feature
   ```
5. **Open a Pull Request**

### Contribution Guidelines
- Follow existing code style and conventions
- Add tests for new features
- Update documentation as needed
- Ensure all tests pass before submitting PR

---

## 📄 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

**TL;DR:** You can use, modify, and distribute this project freely, with attribution.

---

## 🔗 Resources & References

### Official Documentation
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [GitHub Actions Documentation](https://docs.github.com/actions)
- [Azure Functions Python Guide](https://docs.microsoft.com/azure/azure-functions/functions-reference-python)
- [Azure Architecture Center](https://docs.microsoft.com/azure/architecture/)

### Tutorials & Guides
- [Terraform Best Practices](https://www.terraform-best-practices.com/)
- [Azure DevOps for ML](https://docs.microsoft.com/azure/architecture/reference-architectures/ai/mlops-python)
- [GitHub Actions CI/CD](https://docs.github.com/actions/deployment/about-deployments/deploying-with-github-actions)

### Community
- [Terraform Registry](https://registry.terraform.io/)
- [Azure Community](https://techcommunity.microsoft.com/azure)
- [MLOps Community](https://mlops.community/)

---

## 📧 Contact & Support

**Project:** FluxOps  
**Author:** MLOps Engineering Team  
**Repository:** [github.com/drewbai/FluxOps](https://github.com/drewbai/FluxOps)

### Getting Help
- 🐛 **Bug Reports:** [Open an issue](https://github.com/drewbai/FluxOps/issues)
- 💡 **Feature Requests:** [Submit a request](https://github.com/drewbai/FluxOps/issues)
- 💬 **Questions:** [Discussions](https://github.com/drewbai/FluxOps/discussions)

---

## 🏆 Acknowledgments

Special thanks to:
- **HashiCorp** - For Terraform and excellent documentation
- **Microsoft Azure** - For comprehensive cloud services
- **GitHub** - For robust CI/CD platform and collaboration tools
- **Open Source Community** - For invaluable ML and DevOps libraries
- **Contributors** - Everyone who has contributed to this project

---

## 🎯 Project Status

| Aspect | Status |
|--------|--------|
| Infrastructure | ✅ Complete |
| CI/CD Pipeline | ✅ Complete |
| ML Pipeline | ✅ Complete |
| Documentation | ✅ Complete |
| Testing | ✅ Complete |
| Security | ✅ Complete |
| Production Ready | ✅ Yes |

**Last Updated:** January 23, 2026

---

**⭐ If you find this project useful, please consider giving it a star!**

**🔔 Watch this repository** to stay updated with new features and improvements.

---

## 🚦 Quick Command Reference

```bash
# Terraform
terraform init                          # Initialize Terraform
terraform validate                      # Validate configuration
terraform plan                          # Preview changes
terraform apply                         # Apply changes
terraform destroy                       # Destroy infrastructure

# Azure CLI
az login                                # Login to Azure
az account list                         # List subscriptions
az resource list -g fluxops-dev-rg      # List resources

# Python/Testing
pytest tests/ -v                        # Run tests
pytest tests/ --cov                     # Run with coverage
python train_model.py                   # Train model

# Azure Functions
func start                              # Start local function
func azure functionapp publish <name>   # Deploy function

# Git
git status                              # Check status
git add .                               # Stage changes
git commit -m "message"                 # Commit changes
git push origin main                    # Push to remote
```

---

<div align="center">

**Built with ❤️ by the MLOps Team**

[Report Bug](https://github.com/drewbai/FluxOps/issues) · 
[Request Feature](https://github.com/drewbai/FluxOps/issues) · 
[View Documentation](./docs/)

</div>
