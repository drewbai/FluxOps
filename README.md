# 🚀 FluxOps - ML Pipeline Automation with Terraform & GitLab CI/CD

[![GitLab CI/CD](https://img.shields.io/badge/GitLab-CI%2FCD-orange?logo=gitlab)](https://gitlab.com)
[![Terraform](https://img.shields.io/badge/Terraform-1.5+-purple?logo=terraform)](https://terraform.io)
[![Azure](https://img.shields.io/badge/Azure-Cloud-blue?logo=microsoft-azure)](https://azure.microsoft.com)
[![Python](https://img.shields.io/badge/Python-3.11-blue?logo=python)](https://python.org)

FluxOps is a production-ready ML pipeline infrastructure showcasing **Infrastructure as Code (IaC)**, **automated CI/CD**, and **modular design** for reproducible machine learning operations.

> **📚 Quick Links**: 
> - [Project Overview](./PROJECT_OVERVIEW.md) - High-level summary
> - [Quick Start Guide](./QUICKSTART.md) - 5-minute setup
> - [Deployment Checklist](./DEPLOYMENT_CHECKLIST.md) - Step-by-step guide

---

## 🎯 Project Goal

Provision and automate an end-to-end ML pipeline using **Terraform** for infrastructure and **GitLab CI/CD** for automation, demonstrating best practices in:
- ✅ Reproducible infrastructure provisioning
- ✅ Modular, reusable Terraform design
- ✅ Automated deployment and testing
- ✅ Secure secret management
- ✅ Comprehensive monitoring

---

## 🧱 Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         GitLab CI/CD                            │
│  Validate → Plan → Deploy → Test → Teardown                    │
└─────────────────┬───────────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Azure Infrastructure                         │
│                                                                 │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐    │
│  │   Resource   │    │   Storage    │    │  Key Vault   │    │
│  │    Group     │───▶│   Account    │───▶│   Secrets    │    │
│  └──────────────┘    │              │    └──────────────┘    │
│                      │ • Models     │                         │
│                      │ • Logs       │                         │
│                      │ • Data       │                         │
│                      └──────┬───────┘                         │
│                             │                                  │
│  ┌──────────────┐    ┌──────┴───────┐    ┌──────────────┐   │
│  │     App      │    │   Function   │    │   Azure ML   │   │
│  │   Insights   │◀───│     App      │───▶│  (Optional)  │   │
│  │  Monitoring  │    │   (Python)   │    │   Registry   │   │
│  └──────────────┘    └──────────────┘    └──────────────┘   │
│                                                                │
└─────────────────────────────────────────────────────────────────┘
```

### Components

| Component | Purpose | Technology |
|-----------|---------|------------|
| **Terraform** | Infrastructure provisioning | HashiCorp Terraform |
| **GitLab CI/CD** | Automation pipeline | GitLab Pipelines |
| **Azure Storage** | Model & log persistence | Azure Blob Storage |
| **Key Vault** | Secrets management | Azure Key Vault |
| **Function App** | ML inference API | Azure Functions (Python) |
| **App Insights** | Monitoring & observability | Azure Application Insights |
| **Azure ML** | Model registry (optional) | Azure Machine Learning |

---

## 🛠️ Tech Stack

- **Infrastructure**: Terraform 1.5+ (modular design)
- **CI/CD**: GitLab CI/CD
- **Language**: Python 3.11
- **ML Framework**: scikit-learn
- **Cloud Platform**: Microsoft Azure
- **Monitoring**: Azure Application Insights
- **Documentation**: Markdown, OneNote

---

## 📦 Project Structure

```
FluxOps/
├── .gitlab-ci.yml                 # CI/CD pipeline definition
├── README.md                      # This file
├── infra/
│   └── terraform/
│       ├── main.tf                # Root infrastructure orchestration
│       ├── variables.tf           # Input variables
│       ├── outputs.tf             # Output values
│       ├── terraform.tfvars       # Variable values
│       └── modules/
│           ├── resource_group/    # Resource Group module
│           │   ├── main.tf
│           │   ├── variables.tf
│           │   └── outputs.tf
│           ├── storage/           # Storage Account module
│           │   ├── main.tf
│           │   ├── variables.tf
│           │   └── outputs.tf
│           ├── key_vault/         # Key Vault module
│           │   ├── main.tf
│           │   ├── variables.tf
│           │   └── outputs.tf
│           ├── function_app/      # Function App module
│           │   ├── main.tf
│           │   ├── variables.tf
│           │   └── outputs.tf
│           └── app_insights/      # Application Insights module
│               ├── main.tf
│               ├── variables.tf
│               └── outputs.tf
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
└── docs/
    ├── IaC_Design.md              # Infrastructure design doc
    ├── Pipeline_Logic.md          # Pipeline workflow doc
    └── Case_Study.md              # Use case and lessons learned
```

---

## 🚀 Getting Started

### Prerequisites

- **Azure Account** with active subscription
- **GitLab Account** with CI/CD runners
- **Terraform** >= 1.5.0
- **Azure CLI** >= 2.50.0
- **Python** >= 3.11

### Azure Authentication Setup

1. **Create Service Principal**:
```bash
az login
az account set --subscription "<your-subscription-id>"

az ad sp create-for-rbac --name "fluxops-sp" \
  --role="Contributor" \
  --scopes="/subscriptions/<your-subscription-id>"
```

2. **Set GitLab CI/CD Variables** (Settings → CI/CD → Variables):
   - `ARM_CLIENT_ID`: Application (client) ID
   - `ARM_CLIENT_SECRET`: Client secret value
   - `ARM_TENANT_ID`: Directory (tenant) ID
   - `ARM_SUBSCRIPTION_ID`: Your subscription ID
   - `AZURE_SUBSCRIPTION_ID`: Same as above

### Local Development

1. **Clone the repository**:
```bash
git clone <your-repo-url>
cd FluxOps
```

2. **Initialize Terraform**:
```bash
cd infra/terraform
terraform init
```

3. **Validate configuration**:
```bash
terraform validate
terraform fmt -check
```

4. **Plan infrastructure**:
```bash
terraform plan
```

5. **Apply infrastructure** (local testing):
```bash
terraform apply
```

6. **Test ML pipeline locally**:
```bash
cd ../../src/ml_pipeline
pip install -r requirements.txt
python train_model.py
pytest tests/ -v
```

7. **Test Function App locally**:
```bash
cd ../function_app
pip install -r requirements.txt
func start
```

---

## 🔄 CI/CD Pipeline

The GitLab CI/CD pipeline consists of 5 stages:

### 1️⃣ Validate Stage
- Runs `terraform fmt -check`
- Runs `terraform validate`
- Triggers on: MRs, main, develop branches

### 2️⃣ Plan Stage
- Generates Terraform plan
- Outputs plan as artifact
- Triggers on: main, develop, MRs

### 3️⃣ Deploy Stage
- Applies Terraform plan
- Deploys Function App code
- Trains and uploads ML model
- Triggers on: 
  - `main` branch (manual approval required)
  - `develop` branch (automatic)

### 4️⃣ Test Stage
- Tests infrastructure resources
- Validates Function App endpoints
- Runs ML pipeline unit tests
- Generates coverage reports

### 5️⃣ Teardown Stage
- Destroys infrastructure (manual only)
- Scheduled cleanup for dev environment
- Triggers on: Manual action or schedule

---

## 📊 Infrastructure Modules

### Resource Group Module
Creates Azure Resource Group for organizing resources.

**Inputs**: `resource_group_name`, `location`, `tags`  
**Outputs**: `resource_group_name`, `resource_group_id`, `location`

### Storage Module
Provisions Storage Account with three containers:
- `models`: ML model artifacts
- `logs`: Pipeline execution logs
- `data`: Training/inference data

**Inputs**: `storage_account_name`, `account_tier`, `replication_type`  
**Outputs**: `storage_account_name`, `connection_string`, container names

### Key Vault Module
Creates Key Vault for secure secret storage.

**Secrets Stored**:
- Storage connection string
- Storage account key

**Inputs**: `key_vault_name`, `storage_connection_string`  
**Outputs**: `key_vault_uri`, `key_vault_name`

### Function App Module
Deploys Linux-based Azure Function App with Python 3.11.

**Features**:
- System-assigned managed identity
- Integration with Application Insights
- Environment variables for Key Vault and Storage

**Endpoints**:
- `GET /api/health` - Health check
- `POST /api/predict` - ML predictions
- `GET /api/model-info` - Model metadata

### Application Insights Module
Sets up monitoring and telemetry collection.

**Metrics Tracked**:
- Function execution times
- Request rates
- Error rates
- Custom events

---

## 🧪 Testing

### Unit Tests
```bash
cd src/ml_pipeline
pytest tests/ -v --cov=. --cov-report=html
```

### Infrastructure Tests
Automated in CI/CD pipeline:
- Resource provisioning validation
- Endpoint health checks
- Secret accessibility tests

### Function App Testing
```bash
# Test health endpoint
curl https://<function-app-name>.azurewebsites.net/api/health

# Test prediction endpoint
curl -X POST https://<function-app-name>.azurewebsites.net/api/predict \
  -H "Content-Type: application/json" \
  -d '{"features": [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0]}'
```

---

## 🔐 Security Best Practices

1. **Secrets Management**:
   - All secrets stored in Azure Key Vault
   - No secrets in code or version control
   - GitLab CI/CD variables marked as protected

2. **Access Control**:
   - Managed identities for Function App
   - RBAC for resource access
   - Least privilege principle

3. **Network Security**:
   - HTTPS enforcement
   - Storage account firewall (configurable)
   - Private endpoints (optional)

4. **Compliance**:
   - Blob versioning enabled
   - Soft delete for Key Vault
   - Audit logs via Application Insights

---

## 📈 Monitoring & Observability

### Application Insights Metrics

- **Availability**: Function App uptime
- **Performance**: Response times, throughput
- **Errors**: Exception tracking, failure rates
- **Usage**: Request patterns, user analytics

### Log Analytics

Access logs via Azure Portal:
```kusto
traces
| where timestamp > ago(1h)
| where message contains "prediction"
| project timestamp, message, severityLevel
```

---

## 🔧 Configuration

### Terraform Variables

Edit `infra/terraform/terraform.tfvars`:

```hcl
project_name = "fluxops"
environment  = "dev"
location     = "eastus"

storage_account_tier     = "Standard"
storage_replication_type = "LRS"
function_app_sku         = "B1"

tags = {
  Owner      = "MLOps Team"
  CostCenter = "Engineering"
}
```

### Environment-Specific Configs

Create environment-specific variable files:
- `dev.tfvars`
- `staging.tfvars`
- `prod.tfvars`

Use with:
```bash
terraform apply -var-file=prod.tfvars
```

---

## 🗑️ Cleanup

### Manual Cleanup
```bash
cd infra/terraform
terraform destroy
```

### GitLab Pipeline Cleanup
Navigate to: **CI/CD → Pipelines → Manual Actions → terraform_destroy**

---

## 📚 Documentation

### OneNote Pages

1. **IaC Design** (`docs/IaC_Design.md`)
   - Module architecture
   - Design decisions
   - Dependency graph

2. **Pipeline Logic** (`docs/Pipeline_Logic.md`)
   - CI/CD workflow
   - Stage details
   - Rollback procedures

3. **Case Study** (`docs/Case_Study.md`)
   - Use case scenarios
   - Performance metrics
   - Lessons learned

---

## 🎓 Learning Outcomes

This project demonstrates:

- ✅ **Modular Terraform Design**: Reusable infrastructure modules
- ✅ **CI/CD Automation**: End-to-end pipeline automation
- ✅ **Cloud-Native ML**: Serverless ML deployment
- ✅ **Security Best Practices**: Secret management, RBAC
- ✅ **Observability**: Comprehensive monitoring
- ✅ **Testing**: Infrastructure and code testing
- ✅ **Documentation**: Clear, maintainable docs

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Merge Request

---

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

## 🔗 Resources

- [Terraform Azure Provider Docs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [GitLab CI/CD Documentation](https://docs.gitlab.com/ee/ci/)
- [Azure Functions Python Guide](https://docs.microsoft.com/azure/azure-functions/functions-reference-python)
- [Azure Architecture Center](https://docs.microsoft.com/azure/architecture/)

---

## 📧 Contact

**Project**: FluxOps  
**Author**: MLOps Team  
**Repository**: [GitLab Repository URL]

---

## 🏆 Acknowledgments

- Terraform community for excellent documentation
- Azure for comprehensive cloud services
- GitLab for robust CI/CD platform
- Open-source ML community

---

**⭐ If you find this project useful, please consider giving it a star!**
