# FluxOps Deployment Checklist

Use this checklist to ensure successful deployment of FluxOps infrastructure.

---

## 📋 Pre-Deployment Checklist

### Prerequisites

- [ ] **Azure Account** with active subscription
- [ ] **Azure CLI** installed and updated (`az --version`)
- [ ] **Terraform** >= 1.5.0 installed (`terraform --version`)
- [ ] **Python** >= 3.11 installed (`python --version`)
- [ ] **Git** installed (`git --version`)
- [ ] **GitLab Account** (for CI/CD)
- [ ] **VS Code** or preferred IDE

### Azure Setup

- [ ] Login to Azure: `az login`
- [ ] Select subscription: `az account set --subscription "<subscription-id>"`
- [ ] Verify selected account: `az account show`
- [ ] Create service principal for Terraform:
  ```bash
  az ad sp create-for-rbac --name "fluxops-sp" \
    --role="Contributor" \
    --scopes="/subscriptions/<subscription-id>"
  ```
- [ ] Save service principal credentials (clientId, clientSecret, tenantId)

### GitLab Configuration

- [ ] Create/Fork GitLab repository
- [ ] Navigate to: **Settings → CI/CD → Variables**
- [ ] Add the following variables (mark as Protected & Masked):
  - [ ] `ARM_CLIENT_ID`
  - [ ] `ARM_CLIENT_SECRET`
  - [ ] `ARM_TENANT_ID`
  - [ ] `ARM_SUBSCRIPTION_ID`
  - [ ] `AZURE_SUBSCRIPTION_ID`

### Repository Setup

- [ ] Clone repository locally
- [ ] Review project structure
- [ ] Read `README.md`
- [ ] Read `QUICKSTART.md`

---

## 🔧 Configuration Checklist

### Terraform Configuration

- [ ] Navigate to `infra/terraform/`
- [ ] Review `terraform.tfvars`:
  - [ ] Set `project_name` (default: "fluxops")
  - [ ] Set `environment` (dev, staging, prod)
  - [ ] Set `location` (Azure region)
  - [ ] Customize `tags` as needed
- [ ] Review `variables.tf` for additional options
- [ ] Check module configurations in `modules/` directory

### Python Environment

- [ ] Create virtual environment:
  ```bash
  python -m venv .venv
  ```
- [ ] Activate virtual environment:
  - **Windows PowerShell**: `.\.venv\Scripts\Activate.ps1`
  - **Windows CMD**: `.venv\Scripts\activate.bat`
  - **Linux/Mac**: `source .venv/bin/activate`
- [ ] Install ML pipeline dependencies:
  ```bash
  cd src/ml_pipeline
  pip install -r requirements.txt
  ```
- [ ] Install Function App dependencies:
  ```bash
  cd ../function_app
  pip install -r requirements.txt
  ```

---

## 🧪 Local Testing Checklist

### Terraform Validation

- [ ] Initialize Terraform:
  ```bash
  cd infra/terraform
  terraform init
  ```
- [ ] Format check:
  ```bash
  terraform fmt -check -recursive
  ```
- [ ] Validate configuration:
  ```bash
  terraform validate
  ```
- [ ] Generate plan:
  ```bash
  terraform plan
  ```
- [ ] Review plan output for errors

### ML Pipeline Testing

- [ ] Navigate to `src/ml_pipeline/`
- [ ] Run training script:
  ```bash
  python train_model.py
  ```
- [ ] Verify model created in `models/` directory
- [ ] Run unit tests:
  ```bash
  pytest tests/ -v
  ```
- [ ] Check test coverage:
  ```bash
  pytest tests/ --cov=. --cov-report=html
  ```
- [ ] Review coverage report in `htmlcov/index.html`

### Function App Local Testing (Optional)

- [ ] Install Azure Functions Core Tools
- [ ] Navigate to `src/function_app/`
- [ ] Update `local.settings.json` with test values
- [ ] Start function locally:
  ```bash
  func start
  ```
- [ ] Test health endpoint: `http://localhost:7071/api/health`

---

## 🚀 Deployment Checklist

### Option 1: Local Deployment

- [ ] Ensure Azure CLI is authenticated
- [ ] Navigate to `infra/terraform/`
- [ ] Initialize Terraform:
  ```bash
  terraform init
  ```
- [ ] Apply infrastructure:
  ```bash
  terraform apply
  ```
- [ ] Review proposed changes
- [ ] Type `yes` to confirm deployment
- [ ] Wait for deployment to complete (~8-10 minutes)
- [ ] Save output values (resource names, URLs, etc.)

### Option 2: GitLab CI/CD Deployment

- [ ] Ensure GitLab CI/CD variables are configured
- [ ] Create feature branch or use `develop`
- [ ] Commit all changes:
  ```bash
  git add .
  git commit -m "Initial FluxOps setup"
  ```
- [ ] Push to GitLab:
  ```bash
  git push origin <branch-name>
  ```
- [ ] Navigate to **GitLab → CI/CD → Pipelines**
- [ ] Monitor pipeline execution:
  - [ ] ✅ Validate stage passes
  - [ ] ✅ Plan stage completes
  - [ ] ✅ Deploy stage (manual approval for main branch)
  - [ ] ✅ Test stage passes
- [ ] Review deployment logs for any issues

---

## ✅ Post-Deployment Verification

### Infrastructure Verification

- [ ] Check Azure Portal for created resources:
  - [ ] Resource Group exists
  - [ ] Storage Account created with 3 containers (models, logs, data)
  - [ ] Key Vault created with secrets
  - [ ] Function App running
  - [ ] Application Insights collecting data
- [ ] Verify resource names match expected pattern
- [ ] Check resource tags are applied

### Function App Verification

- [ ] Get Function App URL from Terraform outputs:
  ```bash
  terraform output function_app_url
  ```
- [ ] Test health endpoint:
  ```bash
  curl <function-app-url>/api/health
  ```
- [ ] Expected response:
  ```json
  {
    "status": "healthy",
    "service": "FluxOps ML Pipeline",
    "version": "1.0.0"
  }
  ```
- [ ] Test model info endpoint:
  ```bash
  curl <function-app-url>/api/model-info
  ```

### ML Model Verification

- [ ] Check if model was uploaded to Blob Storage:
  ```bash
  az storage blob list \
    --account-name <storage-account-name> \
    --container-name models \
    --output table
  ```
- [ ] Verify `model_v1.pkl` exists
- [ ] Check model size is reasonable (> 0 bytes)

### Security Verification

- [ ] Verify secrets in Key Vault:
  ```bash
  az keyvault secret list --vault-name <key-vault-name> --output table
  ```
- [ ] Check Function App has managed identity:
  ```bash
  az functionapp identity show --name <function-app-name> --resource-group <rg-name>
  ```
- [ ] Verify Key Vault access policy for Function App:
  ```bash
  az keyvault show --name <key-vault-name> --query "properties.accessPolicies"
  ```

### Monitoring Verification

- [ ] Navigate to Application Insights in Azure Portal
- [ ] Check **Live Metrics** shows data
- [ ] Verify **Logs** are being collected
- [ ] Review **Availability** metrics
- [ ] Set up alerts (optional):
  - [ ] Function failure rate > 5%
  - [ ] Response time > 5 seconds
  - [ ] Storage usage > 80%

---

## 🧪 End-to-End Testing

### Test ML Prediction Flow

1. [ ] Get Function App name and resource group:
   ```bash
   az functionapp list --query "[?contains(name, 'fluxops')].[name,resourceGroup]" -o table
   ```

2. [ ] Get function key (if using Function auth level):
   ```bash
   az functionapp keys list --name <func-name> --resource-group <rg-name>
   ```

3. [ ] Make prediction request:
   ```bash
   curl -X POST "<function-url>/api/predict?code=<function-key>" \
     -H "Content-Type: application/json" \
     -d '{"features": [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0]}'
   ```

4. [ ] Verify response contains:
   - `prediction` (0 or 1)
   - `probability` object
   - `confidence` value

5. [ ] Check Application Insights for logged request

### Load Testing (Optional)

- [ ] Use Apache Bench or similar tool
- [ ] Send 100 requests:
  ```bash
  ab -n 100 -c 10 -T "application/json" \
    -p test_payload.json \
    <function-url>/api/predict
  ```
- [ ] Monitor Application Insights during load test
- [ ] Review performance metrics

---

## 📊 Monitoring Setup

### Application Insights Alerts

- [ ] Navigate to Application Insights
- [ ] Create alert rules:
  - [ ] **High Error Rate**: > 5% failed requests
  - [ ] **Slow Response**: p95 > 5 seconds
  - [ ] **High Availability**: < 99% uptime
- [ ] Configure action groups (email, SMS, webhook)

### Cost Monitoring

- [ ] Set up Azure Cost Management budget
- [ ] Configure budget alerts:
  - [ ] 50% of budget reached
  - [ ] 80% of budget reached
  - [ ] 100% of budget reached
- [ ] Review daily cost reports

### Log Analytics Queries

- [ ] Save useful queries:
  - [ ] Request volume by endpoint
  - [ ] Error rate over time
  - [ ] Response time percentiles
  - [ ] Model prediction distribution

---

## 📚 Documentation Review

- [ ] Read `README.md` thoroughly
- [ ] Review `docs/IaC_Design.md` for architecture details
- [ ] Understand `docs/Pipeline_Logic.md` for CI/CD workflow
- [ ] Study `docs/Case_Study.md` for best practices
- [ ] Bookmark `QUICKSTART.md` for team onboarding

---

## 🔄 Maintenance Checklist

### Regular Maintenance

- [ ] **Weekly**: Review Application Insights for errors
- [ ] **Weekly**: Check Azure cost reports
- [ ] **Monthly**: Update Python dependencies
- [ ] **Monthly**: Update Terraform provider versions
- [ ] **Quarterly**: Review and optimize resource SKUs
- [ ] **Quarterly**: Security audit (Key Vault access, RBAC)

### Updates & Upgrades

- [ ] Test Terraform changes in dev environment first
- [ ] Use GitLab CI/CD for all infrastructure changes
- [ ] Document any manual changes immediately
- [ ] Keep `terraform.tfstate` backed up (if using local state)

---

## 🗑️ Cleanup Checklist

### When Tearing Down

- [ ] Export any important data from Storage Account
- [ ] Save final Application Insights logs
- [ ] Document lessons learned
- [ ] Run teardown:
  - **GitLab**: Trigger `terraform_destroy` job
  - **Local**: `terraform destroy`
- [ ] Verify all resources deleted in Azure Portal
- [ ] Purge soft-deleted Key Vault (if needed):
  ```bash
  az keyvault purge --name <key-vault-name>
  ```
- [ ] Remove GitLab CI/CD variables (if project is archived)

---

## 🆘 Troubleshooting Reference

### Common Issues

| Issue | Solution |
|-------|----------|
| Terraform init fails | Check Azure CLI authentication: `az login` |
| Storage account name conflict | Change `project_name` in `terraform.tfvars` |
| Key Vault already exists | Purge soft-deleted vault: `az keyvault purge` |
| Function App cold start | Consider Premium plan or keep-warm strategy |
| Pipeline fails on deploy | Verify GitLab CI/CD variables are set correctly |
| Model upload fails | Check service principal has Storage Blob Contributor role |

### Getting Help

- [ ] Check GitLab pipeline logs
- [ ] Review Azure Activity Log in Portal
- [ ] Check Application Insights for runtime errors
- [ ] Search project documentation
- [ ] Open GitLab issue with error details

---

## ✨ Success Criteria

Deployment is successful when:

- ✅ All Terraform resources created without errors
- ✅ Function App health endpoint returns 200 OK
- ✅ ML model successfully uploaded to Blob Storage
- ✅ Prediction endpoint returns valid responses
- ✅ Application Insights collecting telemetry
- ✅ All tests pass (unit tests, infrastructure tests)
- ✅ GitLab CI/CD pipeline completes successfully
- ✅ Zero security vulnerabilities detected
- ✅ Documentation reviewed and understood
- ✅ Team members can access and use the system

---

## 🎉 Congratulations!

If you've completed this checklist, your FluxOps ML pipeline is fully deployed and operational!

**Next Steps**:
- Customize the ML model for your use case
- Add more Function App endpoints
- Set up production environment
- Implement monitoring dashboards
- Train your team on the system

---

**Checklist Version**: 1.0  
**Last Updated**: November 2025  
**Maintained By**: MLOps Team
