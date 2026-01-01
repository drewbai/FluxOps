#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Provision FluxOps Azure resources

.DESCRIPTION
    Creates all Azure infrastructure using Terraform.
    Optionally deploys the Function App and uploads the ML model.

.PARAMETER DeployFunctionApp
    Also deploy the Function App code after infrastructure is created

.PARAMETER UploadModel
    Upload the trained ML model to Azure Storage

.PARAMETER AutoApprove
    Skip Terraform apply confirmation

.EXAMPLE
    .\scripts\provision.ps1
    
.EXAMPLE
    .\scripts\provision.ps1 -DeployFunctionApp -UploadModel
    
.EXAMPLE
    .\scripts\provision.ps1 -AutoApprove
#>

param(
    [switch]$DeployFunctionApp,
    [switch]$UploadModel,
    [switch]$AutoApprove
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "FluxOps Resource Provisioning" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if Terraform is installed
if (-not (Get-Command terraform -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: Terraform is not installed or not in PATH" -ForegroundColor Red
    exit 1
}

# Check if Azure CLI is installed
if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: Azure CLI is not installed or not in PATH" -ForegroundColor Red
    exit 1
}

# Check Azure login status
Write-Host "Checking Azure authentication..." -ForegroundColor Yellow
$account = az account show 2>$null | ConvertFrom-Json
if (-not $account) {
    Write-Host "ERROR: Not logged into Azure. Run 'az login' first." -ForegroundColor Red
    exit 1
}

Write-Host "✓ Logged in as: $($account.user.name)" -ForegroundColor Green
Write-Host "✓ Subscription: $($account.name) ($($account.id))" -ForegroundColor Green
Write-Host ""

# Navigate to Terraform directory
$terraformDir = Join-Path $PSScriptRoot ".." "infra" "terraform"
if (-not (Test-Path $terraformDir)) {
    Write-Host "ERROR: Terraform directory not found at $terraformDir" -ForegroundColor Red
    exit 1
}

Push-Location $terraformDir

try {
    # Initialize Terraform
    Write-Host "Initializing Terraform..." -ForegroundColor Yellow
    terraform init
    if ($LASTEXITCODE -ne 0) {
        throw "Terraform init failed"
    }

    # Validate configuration
    Write-Host "Validating Terraform configuration..." -ForegroundColor Yellow
    terraform validate
    if ($LASTEXITCODE -ne 0) {
        throw "Terraform validate failed"
    }

    Write-Host "✓ Configuration is valid" -ForegroundColor Green
    Write-Host ""

    # Plan
    Write-Host "Creating Terraform plan..." -ForegroundColor Yellow
    terraform plan -out=tfplan
    if ($LASTEXITCODE -ne 0) {
        throw "Terraform plan failed"
    }

    Write-Host ""
    if (-not $AutoApprove) {
        $confirmation = Read-Host "Do you want to apply this plan? (yes/no)"
        if ($confirmation -ne "yes") {
            Write-Host "Provisioning cancelled." -ForegroundColor Yellow
            exit 0
        }
    }

    # Apply
    Write-Host ""
    Write-Host "Applying Terraform plan..." -ForegroundColor Yellow
    terraform apply tfplan
    if ($LASTEXITCODE -ne 0) {
        throw "Terraform apply failed"
    }

    # Get outputs
    Write-Host ""
    Write-Host "Getting resource information..." -ForegroundColor Yellow
    $outputs = terraform output -json | ConvertFrom-Json

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "✓ Infrastructure provisioned!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Resource Group: $($outputs.resource_group_name.value)" -ForegroundColor Cyan
    Write-Host "Function App: $($outputs.function_app_name.value)" -ForegroundColor Cyan
    Write-Host "Storage Account: $($outputs.storage_account_name.value)" -ForegroundColor Cyan
    Write-Host ""

    Pop-Location

    # Deploy Function App if requested
    if ($DeployFunctionApp) {
        Write-Host "Deploying Function App..." -ForegroundColor Yellow
        $functionAppDir = Join-Path $PSScriptRoot ".." "src" "function_app"
        Push-Location $functionAppDir
        
        try {
            func azure functionapp publish $outputs.function_app_name.value --python
            if ($LASTEXITCODE -ne 0) {
                throw "Function App deployment failed"
            }
            Write-Host "✓ Function App deployed successfully!" -ForegroundColor Green
        } finally {
            Pop-Location
        }
    }

    # Upload model if requested
    if ($UploadModel) {
        Write-Host ""
        Write-Host "Uploading ML model..." -ForegroundColor Yellow
        
        $modelPath = Join-Path $PSScriptRoot ".." "src" "ml_pipeline" "models" "model.pkl"
        
        if (-not (Test-Path $modelPath)) {
            Write-Host "WARNING: Model file not found at $modelPath" -ForegroundColor Yellow
            Write-Host "Run 'python src/ml_pipeline/train_model.py' first to create the model" -ForegroundColor Yellow
        } else {
            az storage blob upload `
                --account-name $outputs.storage_account_name.value `
                --container-name models `
                --name model_v1.pkl `
                --file $modelPath `
                --auth-mode login `
                --overwrite
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✓ Model uploaded successfully!" -ForegroundColor Green
            } else {
                Write-Host "WARNING: Model upload failed" -ForegroundColor Yellow
            }
        }
    }

    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    if (-not $DeployFunctionApp) {
        Write-Host "  - Deploy function app: func azure functionapp publish $($outputs.function_app_name.value) --python" -ForegroundColor White
    }
    if (-not $UploadModel) {
        Write-Host "  - Upload model: az storage blob upload --account-name $($outputs.storage_account_name.value) --container-name models --name model_v1.pkl --file src/ml_pipeline/models/model.pkl --auth-mode login" -ForegroundColor White
    }
    Write-Host "  - Tear down resources: .\scripts\teardown.ps1" -ForegroundColor White
    Write-Host ""

} catch {
    Write-Host ""
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Pop-Location
    exit 1
}
