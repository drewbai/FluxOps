# FluxOps Quick Start Guide

## Prerequisites Checklist

- [ ] Azure account with active subscription
- [ ] Azure CLI installed (`az --version`)
- [ ] Terraform installed (`terraform --version` >= 1.5.0)
- [ ] Python 3.12+ installed (`python --version`)
- [ ] Git installed
- [ ] GitHub account (for CI/CD)
- [ ] Node.js and npm (for Azurite local storage emulator)

---

## 🚀 Quick Setup (5 minutes)

### Step 1: Clone Repository

```bash
git clone <your-repo-url>
cd FluxOps
```

### Step 2: Azure Authentication

```bash
# Login to Azure
az login

# Set your subscription
az account set --subscription "<your-subscription-id>"

# Create service principal for Terraform
az ad sp create-for-rbac --name "fluxops-sp" \
  --role="Contributor" \
  --scopes="/subscriptions/<your-subscription-id>" \
  --sdk-auth

# Save the output - you'll need these for GitLab CI/CD variables
```

### Step 3: Configure GitHub Secrets

Navigate to: **GitHub Repository → Settings → Secrets and variables → Actions**

Add these repository secrets:

```
ARM_CLIENT_ID          = <appId from step 2>
ARM_CLIENT_SECRET      = <password from step 2>
ARM_TENANT_ID          = <tenant from step 2>
ARM_SUBSCRIPTION_ID    = <your-subscription-id>
```

### Step 4: Customize Configuration

Edit `infra/terraform/terraform.tfvars`:

```hcl
project_name = "fluxops"        # Change to your project name
environment  = "dev"             # dev, staging, or prod
location     = "eastus"          # Your preferred Azure region

tags = {
  Owner      = "Your Name"
  CostCenter = "Your Department"
}
```

### Step 5: Local Testing (Optional)

```bash
cd infra/terraform

# Initialize Terraform
terraform init

# Preview changes
terraform plan

# Apply infrastructure (local test)
terraform apply

# Test ML pipeline
cd ../../src/ml_pipeline
pip install -r requirements.txt
python train_model.py
pytest tests/ -v

# Cleanup
cd ../../infra/terraform
terraform destroy
```

### Step 6: Deploy via GitHub Actions or Local Scripts

**Option A: Using GitHub Actions (Recommended for CI/CD)**

```bash
# Commit and push to trigger pipeline
git add .
git commit -m "Initial FluxOps setup"
git push origin main

# Pipeline will automatically:
# ✓ Validate Terraform
# ✓ Generate plan
# ✓ Deploy infrastructure
# ✓ Deploy Function App
# ✓ Train and upload ML model
# ✓ Run tests
```

**Option B: Using Local Scripts (Cost Management)**

```powershell
# Provision all resources
.\scripts\hydrate.ps1 -DeployFunctionApp -UploadModel

# When done, tear down to save costs
.\scripts\dehydrate.ps1

# Bring them back later
.\scripts\hydrate.ps1 -DeployFunctionApp -UploadModel
```

---

## 📊 Verify Deployment

### Check GitHub Actions

1. Go to **Actions** tab in your repository
2. Select the latest workflow run
3. Verify all jobs pass: Validate → Plan → Deploy → Test

### Check Azure Resources

```bash
# List resource groups
az group list --query "[?contains(name, 'fluxops')].name" -o table

# Check Function App
az functionapp list --query "[?contains(name, 'fluxops')].{Name:name, State:state}" -o table

# Test health endpoint
FUNC_NAME=$(az functionapp list --query "[?contains(name, 'fluxops')].name" -o tsv)
curl https://${FUNC_NAME}.azurewebsites.net/api/health
```

### Expected Output

```json
{
  "status": "healthy",
  "service": "FluxOps ML Pipeline",
  "version": "1.0.0"
}
```

---

## 🧪 Test ML Prediction

```bash
# Get Function App name
FUNC_NAME=$(az functionapp list --query "[?contains(name, 'fluxops')].name" -o tsv)

# Get function key
FUNC_KEY=$(az functionapp keys list --name $FUNC_NAME --resource-group <rg-name> --query "functionKeys.default" -o tsv)

# Make prediction
curl -X POST "https://${FUNC_NAME}.azurewebsites.net/api/predict?code=${FUNC_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "features": [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0]
  }'
```

### Expected Response

```json
{
  "prediction": 1,
  "probability": {
    "class_0": 0.23,
    "class_1": 0.77
  },
  "confidence": 0.77
}
```

---

## 📈 Monitor Your Deployment

### Application Insights

1. Go to **Azure Portal**
2. Navigate to your Function App
3. Click **Application Insights**
4. View:
   - Live Metrics
   - Failures
   - Performance
   - Usage

### Sample Query (Logs)

```kusto
requests
| where timestamp > ago(1h)
| summarize count() by name, resultCode
| render barchart
```

---

## 🗑️ Cleanup

### Via GitLab (Recommended)

1. Go to **CI/CD → Pipelines**
2. Click **Manual Actions**
3. Select **terraform_destroy**
4. Confirm destruction

### Via Command Line

```bash
cd infra/terraform
terraform destroy -auto-approve
```

---

## 🆘 Troubleshooting

### Issue: Terraform Init Fails

```bash
# Check Azure CLI login
az account show

# Re-authenticate
az login
az account set --subscription "<your-subscription-id>"
```

### Issue: Function App Not Responding

```bash
# Check Function App logs
az functionapp log tail --name $FUNC_NAME --resource-group $RG_NAME

# Restart Function App
az functionapp restart --name $FUNC_NAME --resource-group $RG_NAME
```

### Issue: Pipeline Fails on Deploy

Check GitLab CI/CD variables are set correctly:
- `ARM_CLIENT_ID`
- `ARM_CLIENT_SECRET`
- `ARM_TENANT_ID`
- `ARM_SUBSCRIPTION_ID`

---

## 📚 Next Steps

- [ ] Review [IaC Design Documentation](./docs/IaC_Design.md)
- [ ] Study [Pipeline Logic](./docs/Pipeline_Logic.md)
- [ ] Read [Case Study](./docs/Case_Study.md)
- [ ] Customize ML model in `src/ml_pipeline/train_model.py`
- [ ] Add more Function App endpoints
- [ ] Set up production environment
- [ ] Configure monitoring alerts

---

## 🤝 Get Help

- **Issues**: Open issue in GitLab
- **Discussions**: Check project wiki
- **Documentation**: See `docs/` folder
- **Azure Support**: [Azure Portal Support](https://portal.azure.com/#blade/Microsoft_Azure_Support/HelpAndSupportBlade)

---

**Happy Building! 🚀**
