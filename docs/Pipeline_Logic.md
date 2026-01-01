# Pipeline Logic - FluxOps CI/CD

## Overview

This document details the GitLab CI/CD pipeline logic for FluxOps, including stage definitions, workflow orchestration, and operational procedures.

---

## Pipeline Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        VALIDATE STAGE                           │
│  • Terraform format check (fmt -check)                         │
│  • Terraform configuration validation                          │
│  • Triggers: MR, main, develop branches                        │
└────────────────────┬────────────────────────────────────────────┘
                     │ ✓ Pass
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│                         PLAN STAGE                              │
│  • Initialize Terraform backend                                │
│  • Generate execution plan (terraform plan)                    │
│  • Export plan as artifact (tfplan)                            │
│  • Generate JSON plan for analysis                             │
└────────────────────┬────────────────────────────────────────────┘
                     │ ✓ Plan Generated
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│                        DEPLOY STAGE                             │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │  1. Apply Infrastructure (terraform apply)              │  │
│  │     • Creates/updates Azure resources                   │  │
│  │     • Exports outputs as JSON artifact                  │  │
│  │     • Manual approval required for main branch          │  │
│  └──────────────────────┬──────────────────────────────────┘  │
│                         │                                      │
│  ┌──────────────────────┴──────────────────────────────────┐  │
│  │  2. Deploy Function App Code                            │  │
│  │     • Install Python dependencies                       │  │
│  │     • Package as ZIP                                    │  │
│  │     • Deploy to Azure Function                          │  │
│  └──────────────────────┬──────────────────────────────────┘  │
│                         │                                      │
│  ┌──────────────────────┴──────────────────────────────────┐  │
│  │  3. Train & Deploy ML Model                             │  │
│  │     • Run training pipeline                             │  │
│  │     • Upload model to Blob Storage                      │  │
│  │     • Save metrics and logs                             │  │
│  └─────────────────────────────────────────────────────────┘  │
└────────────────────┬────────────────────────────────────────────┘
                     │ ✓ Deployment Complete
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│                          TEST STAGE                             │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │  1. Test Infrastructure                                 │  │
│  │     • Verify Resource Group provisioning               │  │
│  │     • Check Storage Account status                     │  │
│  │     • Validate Key Vault accessibility                 │  │
│  │     • Test Function App health endpoint                │  │
│  └─────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │  2. Test ML Pipeline                                    │  │
│  │     • Run pytest unit tests                            │  │
│  │     • Generate coverage report                         │  │
│  │     • Validate model artifacts                         │  │
│  └─────────────────────────────────────────────────────────┘  │
└────────────────────┬────────────────────────────────────────────┘
                     │ ✓ All Tests Pass
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│                       TEARDOWN STAGE                            │
│  • Manual trigger only (or scheduled)                          │
│  • Destroys all infrastructure (terraform destroy)             │
│  • Cleanup for dev environments on schedule                    │
└─────────────────────────────────────────────────────────────────┘
```

---

## Stage Definitions

### Stage 1: Validate

**Purpose**: Ensure Terraform configuration is syntactically correct and properly formatted

**Jobs**:
- `terraform_validate`

**Actions**:
1. Check Terraform formatting (`terraform fmt -check -recursive`)
2. Validate configuration (`terraform validate`)
3. Fail pipeline if issues found

**Triggers**:
- Merge Request events
- Commits to `main` branch
- Commits to `develop` branch

**Exit Criteria**:
- All Terraform files properly formatted
- No syntax errors in configuration
- All required variables defined

---

### Stage 2: Plan

**Purpose**: Generate Terraform execution plan for review

**Jobs**:
- `terraform_plan`

**Actions**:
1. Initialize Terraform (`terraform init`)
2. Generate plan (`terraform plan -out=tfplan`)
3. Export plan as JSON for analysis
4. Store plan as artifact (1 week retention)

**Triggers**:
- `main` branch
- `develop` branch
- Merge Request events

**Artifacts**:
```yaml
artifacts:
  paths:
    - infra/terraform/tfplan        # Binary plan file
    - infra/terraform/plan.json     # JSON format for parsing
  expire_in: 1 week
```

**Exit Criteria**:
- Plan generated successfully
- No Terraform errors
- Artifacts uploaded

---

### Stage 3: Deploy

**Purpose**: Apply infrastructure changes and deploy application code

#### Job 3.1: `terraform_apply`

**Actions**:
1. Initialize Terraform with backend
2. Apply saved plan (`terraform apply tfplan`)
3. Export outputs as JSON artifact
4. Store outputs for downstream jobs

**Approval Requirements**:
- **main branch**: Manual approval required
- **develop branch**: Auto-approve

**Artifacts**:
```yaml
artifacts:
  paths:
    - infra/terraform/terraform_outputs.json
  expire_in: 1 month
```

**Environment**:
- Creates environment named after branch (`main` or `develop`)
- Sets up environment stop action (`terraform_destroy`)

---

#### Job 3.2: `deploy_function_app`

**Actions**:
1. Authenticate to Azure CLI
2. Install Python dependencies to `.python_packages/`
3. Create deployment ZIP
4. Deploy to Function App using `az functionapp deployment`

**Dependencies**:
- Requires `terraform_apply` completion
- Uses outputs from `terraform_outputs.json`

**Deployment Command**:
```bash
az functionapp deployment source config-zip \
  --resource-group $RESOURCE_GROUP \
  --name $FUNCTION_APP_NAME \
  --src function_app.zip
```

---

#### Job 3.3: `deploy_ml_model`

**Actions**:
1. Install ML dependencies (scikit-learn, pandas, numpy)
2. Run model training (`python train_model.py`)
3. Authenticate to Azure using Service Principal
4. Upload model to Blob Storage (`models/model_v1.pkl`)
5. Upload logs and metrics

**Artifacts**:
```yaml
artifacts:
  paths:
    - src/ml_pipeline/models/      # Trained models
    - src/ml_pipeline/logs/        # Training logs
  expire_in: 1 week
```

**Model Upload Process**:
```python
from azure.storage.blob import BlobServiceClient
from azure.identity import ClientSecretCredential

# Authenticate
credential = ClientSecretCredential(
    tenant_id=TENANT_ID,
    client_id=CLIENT_ID,
    client_secret=CLIENT_SECRET
)

# Upload model
blob_client.upload_blob(model_data, overwrite=True)
```

---

### Stage 4: Test

**Purpose**: Validate deployed infrastructure and application functionality

#### Job 4.1: `test_infrastructure`

**Actions**:
1. **Resource Group Test**:
   ```bash
   az group show --name $RG_NAME \
     --query "properties.provisioningState"
   # Expected: "Succeeded"
   ```

2. **Storage Account Test**:
   ```bash
   az storage account show --name $SA_NAME \
     --query "provisioningState"
   # Expected: "Succeeded"
   ```

3. **Key Vault Test**:
   ```bash
   az keyvault show --name $KV_NAME \
     --query "properties.provisioningState"
   # Expected: "Succeeded"
   ```

4. **Function App Test**:
   ```bash
   az functionapp show --name $FUNC_NAME \
     --query "state"
   # Expected: "Running"
   ```

5. **HTTP Endpoint Test**:
   ```bash
   curl -s -o /dev/null -w "%{http_code}" \
     https://$FUNC_NAME.azurewebsites.net/api/health
   # Expected: 200 or 401
   ```

**Exit Criteria**:
- All resources in "Succeeded" state
- Function App is running
- Health endpoint responds

---

#### Job 4.2: `test_ml_pipeline`

**Actions**:
1. Install test dependencies (pytest, pytest-cov)
2. Run unit tests (`pytest tests/ -v`)
3. Generate coverage report (HTML + Cobertura)
4. Validate coverage threshold (optional)

**Test Categories**:
- Data generation tests
- Model training tests
- Model evaluation tests
- Inference tests
- Model persistence tests

**Coverage Report**:
```yaml
artifacts:
  paths:
    - src/ml_pipeline/htmlcov/
  reports:
    coverage_report:
      coverage_format: cobertura
      path: src/ml_pipeline/coverage.xml
```

**Exit Criteria**:
- All tests pass
- Coverage meets threshold (e.g., > 80%)
- No critical issues detected

---

### Stage 5: Teardown

**Purpose**: Destroy infrastructure and clean up resources

#### Job 5.1: `terraform_destroy`

**Actions**:
1. Initialize Terraform
2. Destroy all resources (`terraform destroy -auto-approve`)
3. Verify cleanup completion

**Triggers**:
- **Manual only** for `main` and `develop` branches
- Prevents accidental destruction

**Use Cases**:
- End of sprint cleanup
- Cost optimization
- Environment refresh

---

#### Job 5.2: `scheduled_cleanup`

**Actions**:
- Automatically destroys `develop` environment on schedule
- Runs via GitLab Pipeline Schedules

**Schedule Example**:
```yaml
rules:
  - if: '$CI_PIPELINE_SOURCE == "schedule" && $CI_COMMIT_BRANCH == "develop"'
```

**Typical Schedule**: Daily at midnight, weekends only, etc.

---

## Workflow Scenarios

### Scenario 1: Feature Development

```
Developer → Create Feature Branch
    ↓
Commit Changes
    ↓
Open Merge Request
    ↓
Pipeline Runs: VALIDATE → PLAN → TEST (unit tests)
    ↓
Code Review & Approval
    ↓
Merge to develop branch
    ↓
Pipeline Runs: VALIDATE → PLAN → DEPLOY (auto) → TEST
    ↓
Develop Environment Updated
```

---

### Scenario 2: Production Release

```
develop branch (stable)
    ↓
Create Release Branch
    ↓
Merge to main branch
    ↓
Pipeline Runs: VALIDATE → PLAN → DEPLOY (MANUAL GATE) → TEST
    ↓
Engineer Reviews Plan
    ↓
Manual Approval to Deploy
    ↓
Production Deployment
    ↓
Smoke Tests & Monitoring
```

---

### Scenario 3: Hotfix

```
Production Issue Detected
    ↓
Create Hotfix Branch from main
    ↓
Fix Issue & Test Locally
    ↓
Open Emergency MR
    ↓
Fast-Track Review
    ↓
Merge to main
    ↓
Manual Deploy to Production
    ↓
Verify Fix & Monitor
    ↓
Backport to develop
```

---

## Environment Management

### Environment Variables

Set in **GitLab → Settings → CI/CD → Variables**:

| Variable | Type | Protected | Masked | Description |
|----------|------|-----------|--------|-------------|
| `ARM_CLIENT_ID` | Variable | ✓ | ✓ | Azure SP Client ID |
| `ARM_CLIENT_SECRET` | Variable | ✓ | ✓ | Azure SP Secret |
| `ARM_TENANT_ID` | Variable | ✓ | ✓ | Azure Tenant ID |
| `ARM_SUBSCRIPTION_ID` | Variable | ✓ | ✗ | Azure Subscription |
| `AZURE_SUBSCRIPTION_ID` | Variable | ✓ | ✗ | Same as above |

---

### Cache Configuration

```yaml
cache:
  key: "${CI_COMMIT_REF_SLUG}"
  paths:
    - infra/terraform/.terraform
```

**Benefits**:
- Faster pipeline execution
- Reduced provider plugin downloads
- Per-branch isolation

---

## Error Handling & Rollback

### Handling Failed Deployments

**If `terraform_apply` fails**:
1. Review error logs in GitLab job output
2. Check Azure Activity Log for resource-level errors
3. Fix Terraform code or Azure permissions
4. Re-run pipeline

**If `deploy_function_app` fails**:
1. Verify Function App is running (`az functionapp show`)
2. Check deployment logs (`az functionapp log tail`)
3. Validate ZIP package contents
4. Retry deployment job

**If `deploy_ml_model` fails**:
1. Check model training logs
2. Verify Storage Account access
3. Validate service principal permissions
4. Re-run training job

---

### Rollback Procedures

#### Option 1: Git Revert

```bash
# Revert to previous commit
git revert <commit-hash>
git push origin main

# Pipeline will deploy previous version
```

#### Option 2: Manual Terraform Rollback

```bash
# Checkout previous working commit
git checkout <stable-commit>

# Apply previous configuration
cd infra/terraform
terraform apply
```

#### Option 3: Emergency Teardown

```bash
# Trigger teardown job manually
# Navigate to: Pipelines → Select Pipeline → Manual Actions → terraform_destroy

# Redeploy from stable branch
```

---

## Monitoring & Observability

### Pipeline Metrics

Track in GitLab:
- **Success rate**: % of successful pipelines
- **Duration**: Time to complete each stage
- **Failure frequency**: Jobs that fail most often
- **Manual intervention**: How often approvals are needed

### Application Metrics

Monitor in Azure Application Insights:
- **Deployment frequency**: How often code is deployed
- **Lead time**: Commit to production time
- **MTTR**: Mean time to recovery
- **Change failure rate**: % of deployments causing issues

---

## Best Practices

### 1. Pipeline Efficiency

- ✅ Use cache for Terraform providers
- ✅ Parallelize independent jobs
- ✅ Limit artifact retention periods
- ✅ Use slim Docker images

### 2. Security

- ✅ Protect sensitive variables
- ✅ Use masked variables for secrets
- ✅ Limit protected branch access
- ✅ Regular credential rotation

### 3. Reliability

- ✅ Implement retry logic for transient failures
- ✅ Add timeout limits to prevent hanging jobs
- ✅ Use manual gates for production
- ✅ Maintain rollback procedures

### 4. Observability

- ✅ Log all deployments to Application Insights
- ✅ Tag deployments with commit SHA
- ✅ Send notifications to team chat
- ✅ Create deployment dashboards

---

## Troubleshooting Guide

### Issue: Terraform Init Fails

**Symptoms**: `terraform init` exits with backend error

**Solutions**:
1. Check backend configuration in `main.tf`
2. Verify storage account exists
3. Check service principal permissions
4. Review state lock issues

---

### Issue: Function App Deployment Hangs

**Symptoms**: `az functionapp deployment` times out

**Solutions**:
1. Check Function App status: `az functionapp show`
2. Restart Function App: `az functionapp restart`
3. Verify ZIP package size (< 1GB)
4. Check SCM endpoint availability

---

### Issue: Tests Fail After Deployment

**Symptoms**: Infrastructure tests pass, but app tests fail

**Solutions**:
1. Check Application Insights for errors
2. Review Function App logs: `az functionapp log tail`
3. Verify environment variables are set
4. Test endpoints manually with `curl`

---

### Issue: Model Upload Fails

**Symptoms**: `deploy_ml_model` job fails with authentication error

**Solutions**:
1. Verify service principal credentials
2. Check Storage Account firewall rules
3. Validate RBAC permissions (Storage Blob Data Contributor)
4. Test authentication locally

---

## Future Enhancements

### Planned Improvements

- [ ] **Blue-Green Deployments**: Zero-downtime releases
- [ ] **Canary Releases**: Gradual rollout with traffic splitting
- [ ] **Automated Rollback**: Auto-revert on test failures
- [ ] **Multi-Region**: Deploy to multiple Azure regions
- [ ] **Performance Tests**: Load testing in pipeline
- [ ] **Security Scanning**: SAST/DAST integration
- [ ] **Notification Integration**: Slack/Teams alerts
- [ ] **Cost Estimation**: Terraform cost analysis

---

## References

- [GitLab CI/CD Best Practices](https://docs.gitlab.com/ee/ci/pipelines/pipeline_efficiency.html)
- [Terraform Workflow](https://www.terraform.io/guides/core-workflow.html)
- [Azure DevOps Integration](https://docs.microsoft.com/azure/devops/)

---

**Document Version**: 1.0  
**Last Updated**: November 2025  
**Author**: MLOps Team
