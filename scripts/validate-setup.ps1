#!/usr/bin/env pwsh
# FluxOps Setup Validation Script
# Checks prerequisites and validates configuration

Write-Host "🚀 FluxOps Setup Validation" -ForegroundColor Cyan
Write-Host "=" * 50 -ForegroundColor Cyan
Write-Host ""

$errors = 0
$warnings = 0

# Function to check command exists
function Test-Command {
    param($command)
    try {
        if (Get-Command $command -ErrorAction Stop) {
            return $true
        }
    } catch {
        return $false
    }
    return $false
}

# Check Azure CLI
Write-Host "Checking Azure CLI..." -NoNewline
if (Test-Command "az") {
    $azVersion = az version --output tsv 2>$null
    Write-Host " ✅ Installed" -ForegroundColor Green
} else {
    Write-Host " ❌ Not found" -ForegroundColor Red
    Write-Host "  Install: https://aka.ms/InstallAzureCLI" -ForegroundColor Yellow
    $errors++
}

# Check Terraform
Write-Host "Checking Terraform..." -NoNewline
if (Test-Command "terraform") {
    $tfVersion = terraform version | Select-Object -First 1
    Write-Host " ✅ Installed ($tfVersion)" -ForegroundColor Green
} else {
    Write-Host " ❌ Not found" -ForegroundColor Red
    Write-Host "  Install: https://www.terraform.io/downloads" -ForegroundColor Yellow
    $errors++
}

# Check Python
Write-Host "Checking Python..." -NoNewline
if (Test-Command "python") {
    $pyVersion = python --version 2>&1
    if ($pyVersion -match "3\.1[1-9]") {
        Write-Host " ✅ Installed ($pyVersion)" -ForegroundColor Green
    } else {
        Write-Host " ⚠️  Version 3.11+ recommended (found: $pyVersion)" -ForegroundColor Yellow
        $warnings++
    }
} else {
    Write-Host " ❌ Not found" -ForegroundColor Red
    Write-Host "  Install: https://www.python.org/downloads/" -ForegroundColor Yellow
    $errors++
}

# Check Git
Write-Host "Checking Git..." -NoNewline
if (Test-Command "git") {
    $gitVersion = git --version
    Write-Host " ✅ Installed ($gitVersion)" -ForegroundColor Green
} else {
    Write-Host " ❌ Not found" -ForegroundColor Red
    Write-Host "  Install: https://git-scm.com/downloads" -ForegroundColor Yellow
    $errors++
}

Write-Host ""
Write-Host "Checking Azure Authentication..." -ForegroundColor Cyan

# Check Azure login
try {
    $account = az account show 2>$null | ConvertFrom-Json
    if ($account) {
        Write-Host "Azure Account..." -NoNewline
        Write-Host " ✅ Logged in as $($account.user.name)" -ForegroundColor Green
        Write-Host "Subscription..." -NoNewline
        Write-Host " ✅ $($account.name) ($($account.id))" -ForegroundColor Green
    }
} catch {
    Write-Host "Azure Authentication..." -NoNewline
    Write-Host " ⚠️  Not logged in" -ForegroundColor Yellow
    Write-Host "  Run: az login" -ForegroundColor Yellow
    $warnings++
}

Write-Host ""
Write-Host "Checking Terraform Configuration..." -ForegroundColor Cyan

# Check if terraform directory exists
if (Test-Path "infra/terraform/main.tf") {
    Write-Host "Terraform files..." -NoNewline
    Write-Host " ✅ Found" -ForegroundColor Green
    
    # Check terraform.tfvars
    if (Test-Path "infra/terraform/terraform.tfvars") {
        Write-Host "terraform.tfvars..." -NoNewline
        Write-Host " ✅ Found" -ForegroundColor Green
    } else {
        Write-Host "terraform.tfvars..." -NoNewline
        Write-Host " ⚠️  Not found" -ForegroundColor Yellow
        Write-Host "  Consider creating from terraform.tfvars.example" -ForegroundColor Yellow
        $warnings++
    }
    
    # Try Terraform init (dry run)
    Push-Location "infra/terraform"
    Write-Host "Terraform validation..." -NoNewline
    try {
        $initOutput = terraform init -backend=false 2>&1
        $validateOutput = terraform validate 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host " ✅ Valid" -ForegroundColor Green
        } else {
            Write-Host " ❌ Invalid" -ForegroundColor Red
            Write-Host "  Run 'terraform validate' for details" -ForegroundColor Yellow
            $errors++
        }
    } catch {
        Write-Host " ⚠️  Could not validate" -ForegroundColor Yellow
        $warnings++
    }
    Pop-Location
} else {
    Write-Host "Terraform files..." -NoNewline
    Write-Host " ❌ Not found" -ForegroundColor Red
    $errors++
}

Write-Host ""
Write-Host "Checking Python Environment..." -ForegroundColor Cyan

# Check ML pipeline requirements
if (Test-Path "src/ml_pipeline/requirements.txt") {
    Write-Host "ML Pipeline requirements..." -NoNewline
    Write-Host " ✅ Found" -ForegroundColor Green
    
    # Check if virtual environment exists
    if (Test-Path ".venv") {
        Write-Host "Virtual environment..." -NoNewline
        Write-Host " ✅ Found (.venv)" -ForegroundColor Green
    } else {
        Write-Host "Virtual environment..." -NoNewline
        Write-Host " ⚠️  Not found" -ForegroundColor Yellow
        Write-Host "  Run: python -m venv .venv" -ForegroundColor Yellow
        $warnings++
    }
} else {
    Write-Host "ML Pipeline requirements..." -NoNewline
    Write-Host " ⚠️  Not found" -ForegroundColor Yellow
    $warnings++
}

# Check Function App requirements
if (Test-Path "src/function_app/requirements.txt") {
    Write-Host "Function App requirements..." -NoNewline
    Write-Host " ✅ Found" -ForegroundColor Green
} else {
    Write-Host "Function App requirements..." -NoNewline
    Write-Host " ⚠️  Not found" -ForegroundColor Yellow
    $warnings++
}

Write-Host ""
Write-Host "Checking Documentation..." -ForegroundColor Cyan

$docs = @("README.md", "QUICKSTART.md", "docs/IaC_Design.md", "docs/Pipeline_Logic.md", "docs/Case_Study.md")
foreach ($doc in $docs) {
    $docName = Split-Path $doc -Leaf
    Write-Host "$docName..." -NoNewline
    if (Test-Path $doc) {
        Write-Host " ✅ Found" -ForegroundColor Green
    } else {
        Write-Host " ⚠️  Missing" -ForegroundColor Yellow
        $warnings++
    }
}

Write-Host ""
Write-Host "=" * 50 -ForegroundColor Cyan
Write-Host "Validation Summary" -ForegroundColor Cyan
Write-Host "=" * 50 -ForegroundColor Cyan

if ($errors -eq 0 -and $warnings -eq 0) {
    Write-Host "✅ All checks passed! Ready to deploy." -ForegroundColor Green
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Cyan
    Write-Host "1. Review configuration in infra/terraform/terraform.tfvars"
    Write-Host "2. Run: cd infra/terraform && terraform init"
    Write-Host "3. Run: terraform plan"
    Write-Host "4. Run: terraform apply"
    Write-Host ""
    Write-Host "Or push to GitLab to trigger CI/CD pipeline"
    exit 0
} elseif ($errors -eq 0) {
    Write-Host "⚠️  $warnings warning(s) found. Review and proceed." -ForegroundColor Yellow
    exit 0
} else {
    Write-Host "❌ $errors error(s) and $warnings warning(s) found." -ForegroundColor Red
    Write-Host "Please fix errors before proceeding." -ForegroundColor Red
    exit 1
}
