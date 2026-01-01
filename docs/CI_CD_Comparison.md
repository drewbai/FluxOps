# CI/CD Platform Comparison: GitLab vs GitHub Actions

FluxOps supports both **GitLab CI/CD** and **GitHub Actions** for automation. This document compares the two implementations and provides guidance on choosing between them.

---

## Quick Comparison

| Feature | GitLab CI/CD | GitHub Actions |
|---------|--------------|----------------|
| **Configuration File** | `.gitlab-ci.yml` | `.github/workflows/fluxops-pipeline.yml` |
| **Pipeline Stages** | 5 (validate, plan, deploy, test, teardown) | 8 Jobs (validate, plan, deploy-infra, deploy-func, deploy-ml, test-infra, test-ml, destroy) |
| **Free Tier** | 400 CI/CD minutes/month | 2,000 minutes/month (public repos unlimited) |
| **Approval Gates** | Built-in with environments | Built-in with environments |
| **Artifacts** | 30 days default | 90 days default |
| **Caching** | Built-in cache directive | actions/cache |
| **Secrets Management** | CI/CD Variables | Repository/Environment Secrets |
| **Ease of Use** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Integration** | GitLab ecosystem | GitHub ecosystem |

---

## Setup Instructions

### GitLab CI/CD Setup

#### 1. Repository Setup
```bash
# Push to GitLab
git remote add gitlab git@gitlab.com:username/fluxops.git
git push gitlab main
```

#### 2. Configure CI/CD Variables
Navigate to: **Settings → CI/CD → Variables**

Add these variables (mark as **Protected** and **Masked**):
```
ARM_CLIENT_ID          = <azure-sp-client-id>
ARM_CLIENT_SECRET      = <azure-sp-secret>
ARM_TENANT_ID          = <azure-tenant-id>
ARM_SUBSCRIPTION_ID    = <azure-subscription-id>
AZURE_SUBSCRIPTION_ID  = <azure-subscription-id>
```

#### 3. Trigger Pipeline
```bash
git push gitlab main
```

Navigate to: **CI/CD → Pipelines** to monitor

---

### GitHub Actions Setup

#### 1. Repository Setup
```bash
# Push to GitHub
git remote add origin git@github.com:username/fluxops.git
git push origin main
```

#### 2. Configure Secrets
Navigate to: **Settings → Secrets and variables → Actions**

Add these secrets:
```
ARM_CLIENT_ID          = <azure-sp-client-id>
ARM_CLIENT_SECRET      = <azure-sp-secret>
ARM_TENANT_ID          = <azure-tenant-id>
ARM_SUBSCRIPTION_ID    = <azure-subscription-id>
```

#### 3. Configure Environments (Optional but Recommended)
Navigate to: **Settings → Environments**

Create environments:
- **main** - Production environment (with required reviewers)
- **develop** - Development environment (auto-deploy)

#### 4. Trigger Workflow
```bash
git push origin main
```

Navigate to: **Actions** tab to monitor

---

## Pipeline Comparison

### GitLab CI/CD Pipeline

```yaml
stages:
  - validate      # Terraform syntax checks
  - plan          # Generate plan
  - deploy        # Apply infra + deploy code + train model
  - test          # Validate deployment
  - teardown      # Destroy (manual)
```

**Key Features**:
- ✅ Unified deploy stage (runs 3 jobs sequentially)
- ✅ Built-in cache for Terraform providers
- ✅ Environment stop actions
- ✅ Manual approvals with `when: manual`
- ✅ Scheduled cleanup support

**Configuration**: `.gitlab-ci.yml`

---

### GitHub Actions Pipeline

```yaml
jobs:
  - validate              # Terraform syntax checks
  - plan                  # Generate plan
  - deploy-infrastructure # Apply Terraform
  - deploy-function-app   # Deploy Function code
  - deploy-ml-model       # Train and upload model
  - test-infrastructure   # Validate resources
  - test-ml-pipeline      # Run pytest
  - destroy              # Destroy (workflow_dispatch)
```

**Key Features**:
- ✅ Separate jobs for each deployment component
- ✅ Better parallelization (test jobs run independently)
- ✅ Built-in artifact handling
- ✅ PR commenting for test coverage
- ✅ Manual workflow dispatch for destroy

**Configuration**: `.github/workflows/fluxops-pipeline.yml`

---

## Feature-by-Feature Comparison

### 1. Approval Gates

#### GitLab
```yaml
terraform_apply:
  stage: deploy
  rules:
    - if: '$CI_COMMIT_BRANCH == "main"'
      when: manual      # Requires manual approval
```

#### GitHub Actions
```yaml
deploy-infrastructure:
  needs: plan
  environment:
    name: main        # Environment with required reviewers
```

**Winner**: Both are equivalent, GitHub's environment protection is slightly more flexible

---

### 2. Artifact Management

#### GitLab
```yaml
artifacts:
  paths:
    - infra/terraform/tfplan
  expire_in: 1 week
```

#### GitHub Actions
```yaml
- uses: actions/upload-artifact@v4
  with:
    name: terraform-plan
    path: infra/terraform/tfplan
    retention-days: 7
```

**Winner**: GitHub Actions - More intuitive API, better artifact downloads

---

### 3. Secrets Management

#### GitLab
- Repository-level CI/CD variables
- Group-level variables (shared across projects)
- Protected/Masked flags
- File-type secrets

#### GitHub Actions
- Repository secrets
- Environment secrets
- Organization secrets
- Encrypted secrets in repo (not recommended)

**Winner**: GitLab - More granular control with group-level sharing

---

### 4. Caching

#### GitLab
```yaml
cache:
  key: "${CI_COMMIT_REF_SLUG}"
  paths:
    - infra/terraform/.terraform
```

#### GitHub Actions
```yaml
- uses: actions/cache@v4
  with:
    path: infra/terraform/.terraform
    key: terraform-${{ hashFiles('**/*.tf') }}
```

**Winner**: GitHub Actions - More sophisticated caching with hash keys

---

### 5. Testing & Coverage

#### GitLab
```yaml
test_ml_pipeline:
  script:
    - pytest tests/ --cov=. --cov-report=html
  artifacts:
    paths:
      - htmlcov/
```

#### GitHub Actions
```yaml
- run: pytest tests/ --cov=. --cov-report=xml
- uses: py-cov-action/python-coverage-comment-action@v3
  with:
    GITHUB_TOKEN: ${{ github.token }}
```

**Winner**: GitHub Actions - Native PR comments, better marketplace actions

---

### 6. Manual Triggers

#### GitLab
- Manual jobs in pipeline
- Scheduled pipelines
- Pipeline trigger tokens
- Web UI trigger

#### GitHub Actions
```yaml
on:
  workflow_dispatch:
    inputs:
      destroy:
        description: 'Destroy infrastructure'
        required: false
```

**Winner**: GitHub Actions - More flexible inputs, better UI

---

### 7. Cost (Free Tier)

#### GitLab
- **SaaS Free**: 400 CI/CD minutes/month
- **Self-hosted**: Unlimited (requires runners)
- Shared runners on gitlab.com

#### GitHub Actions
- **Public repos**: Unlimited minutes
- **Private repos**: 2,000 minutes/month
- **Self-hosted**: Unlimited (requires runners)

**Winner**: GitHub Actions - 5x more free minutes for private repos

---

## Migration Guide

### GitLab → GitHub Actions

1. **Copy repository**:
   ```bash
   git remote add github git@github.com:username/fluxops.git
   git push github main
   ```

2. **Migrate secrets**:
   - Export GitLab CI/CD variables
   - Import to GitHub Secrets (Settings → Secrets)

3. **Test workflow**:
   ```bash
   git commit --allow-empty -m "Test GitHub Actions"
   git push github main
   ```

4. **Monitor**: Check **Actions** tab

---

### GitHub Actions → GitLab

1. **Copy repository**:
   ```bash
   git remote add gitlab git@gitlab.com:username/fluxops.git
   git push gitlab main
   ```

2. **Migrate secrets**:
   - Export GitHub Secrets (manual process)
   - Import to GitLab CI/CD variables

3. **Test pipeline**:
   ```bash
   git commit --allow-empty -m "Test GitLab CI/CD"
   git push gitlab main
   ```

4. **Monitor**: Check **CI/CD → Pipelines**

---

## Recommendations

### Choose GitLab CI/CD if:

- ✅ You prefer all-in-one platform (code + CI/CD + issues)
- ✅ You need group-level variable sharing
- ✅ You're already using GitLab for version control
- ✅ You want simpler YAML syntax
- ✅ You need built-in container registry integration

### Choose GitHub Actions if:

- ✅ You're using GitHub for version control
- ✅ You want access to GitHub Marketplace actions
- ✅ You need more free CI/CD minutes
- ✅ You want better PR integration (comments, checks)
- ✅ You prefer granular job separation
- ✅ You need workflow reusability across repos

---

## Dual Setup (Recommended for Learning)

Keep both configurations to compare:

```
FluxOps/
├── .gitlab-ci.yml                    # GitLab pipeline
└── .github/
    └── workflows/
        └── fluxops-pipeline.yml      # GitHub Actions pipeline
```

**Benefits**:
- Learn both platforms
- Compare execution times
- Redundancy for critical projects
- Team flexibility

**Considerations**:
- Keep both in sync when changing infrastructure
- Use different environments (e.g., GitHub → dev, GitLab → prod)
- Monitor costs if using both

---

## Performance Comparison

Based on typical execution times:

| Stage | GitLab CI/CD | GitHub Actions |
|-------|--------------|----------------|
| **Validate** | ~1 min | ~1 min |
| **Plan** | ~3 min | ~3 min |
| **Deploy Infrastructure** | ~8 min | ~8 min |
| **Deploy Function** | ~2 min | ~2 min |
| **Deploy ML Model** | ~3 min | ~3 min |
| **Test Infrastructure** | ~2 min | ~2 min |
| **Test ML Pipeline** | ~1 min | ~1 min |
| **Total** | ~20 min | ~20 min |

**Note**: GitHub Actions may be slightly faster due to better parallelization of test jobs.

---

## Troubleshooting

### Common GitLab Issues

**Issue**: Pipeline stuck in "Pending"  
**Solution**: Check runner availability or use shared runners

**Issue**: "403 Forbidden" on artifact download  
**Solution**: Check artifact expiration and permissions

**Issue**: Manual job not appearing  
**Solution**: Verify `rules` and `when: manual` syntax

---

### Common GitHub Actions Issues

**Issue**: Workflow not triggering  
**Solution**: Check branch protection rules and workflow syntax

**Issue**: "Resource not accessible by integration"  
**Solution**: Check repository permissions and secrets

**Issue**: Environment not found  
**Solution**: Create environment in Settings → Environments

---

## Best Practices

### For Both Platforms

1. **Use Environments**: Separate dev/staging/prod
2. **Protect Secrets**: Never commit credentials
3. **Cache Dependencies**: Terraform providers, Python packages
4. **Tag Deployments**: Use Git tags for releases
5. **Monitor Costs**: Review CI/CD minutes usage
6. **Document Changes**: Update docs when modifying pipelines

### GitLab-Specific

- Use `rules` instead of `only/except` (deprecated)
- Leverage `.pre` and `.post` stages for setup/cleanup
- Use `extends` for DRY pipeline code

### GitHub Actions-Specific

- Use GitHub Marketplace actions when possible
- Leverage `matrix` for multi-version testing
- Use `workflow_call` for reusable workflows

---

## Additional Resources

### GitLab CI/CD
- [GitLab CI/CD Documentation](https://docs.gitlab.com/ee/ci/)
- [GitLab CI/CD Examples](https://docs.gitlab.com/ee/ci/examples/)
- [GitLab CI/CD Variables](https://docs.gitlab.com/ee/ci/variables/)

### GitHub Actions
- [GitHub Actions Documentation](https://docs.github.com/actions)
- [GitHub Actions Marketplace](https://github.com/marketplace?type=actions)
- [Workflow Syntax](https://docs.github.com/actions/reference/workflow-syntax-for-github-actions)

---

## Conclusion

Both **GitLab CI/CD** and **GitHub Actions** are excellent choices for FluxOps. Your choice should primarily depend on:

1. **Your existing platform** (GitLab vs GitHub)
2. **Team familiarity** with the platform
3. **Cost considerations** (free minutes)
4. **Specific features** needed for your workflow

For most users, **stick with the platform you're already using for version control** to keep everything in one place.

---

**Document Version**: 1.0  
**Last Updated**: November 2025  
**Author**: MLOps Team
