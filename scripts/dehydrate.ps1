#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Aggressively dehydrate FluxOps to minimize Azure costs

.DESCRIPTION
    Removes expensive compute (Function App + App Service Plan) and
    reduces Log Analytics retention, while preserving Storage, Key Vault,
    and Application Insights. This keeps the minimum viable footprint.

.EXAMPLE
    .\scripts\dehydrate.ps1
    
.EXAMPLE
    .\scripts\dehydrate.ps1 -AutoApprove -RetentionDays 7
    
.PARAMETER AutoApprove
    Skips interactive confirmations.

.PARAMETER RetentionDays
    Number of days to retain Log Analytics data (default 7).

.PARAMETER SetStorageCoolTier
    If specified, sets the Storage account default access tier to Cool.
#>

param(
    [switch]$AutoApprove,
    [int]$RetentionDays = 7,
    [switch]$SetStorageCoolTier
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "FluxOps Aggressive Dehydration" -ForegroundColor Cyan
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

try {
    # Navigate to Terraform directory
    $terraformDir = Join-Path $PSScriptRoot ".." "infra" "terraform"
    if (-not (Test-Path $terraformDir)) {
        Write-Host "ERROR: Terraform directory not found at $terraformDir" -ForegroundColor Red
        exit 1
    }

    Push-Location $terraformDir

    # Ensure Terraform is initialized
    if (-not (Test-Path ".terraform")) {
        Write-Host "Terraform not initialized. Running 'terraform init'..." -ForegroundColor Yellow
        terraform init
        if ($LASTEXITCODE -ne 0) { throw "Terraform init failed" }
    }

    # Get Terraform outputs to resolve names
    $tfOutputs = terraform output -json 2>$null | ConvertFrom-Json
    $rgName = $tfOutputs.resource_group_name.value
    $funcName = $tfOutputs.function_app_name.value
    $aiName = $tfOutputs.app_insights_name.value
    $saName = $tfOutputs.storage_account_name.value

    Write-Host "Target resource group: $rgName" -ForegroundColor Yellow
    Write-Host "Function App: $funcName" -ForegroundColor Yellow
    Write-Host "App Insights: $aiName" -ForegroundColor Yellow
    Write-Host "Storage Account: $saName" -ForegroundColor Yellow
    Write-Host "Log Analytics retention target: $RetentionDays days" -ForegroundColor Yellow
    if ($SetStorageCoolTier) { Write-Host "Storage tier change: Set default to Cool" -ForegroundColor Yellow }
    Write-Host ""

    if (-not $AutoApprove) {
        Write-Host "This will: " -ForegroundColor Red
        Write-Host " - Delete Function App (compute)" -ForegroundColor Red
        Write-Host " - Delete App Service Plan (compute)" -ForegroundColor Red
        Write-Host " - Reduce Log Analytics retention to $RetentionDays days" -ForegroundColor Red
        Write-Host " - Preserve Storage, Key Vault, and App Insights" -ForegroundColor Red
        if ($SetStorageCoolTier) { Write-Host " - Set Storage default access tier to Cool" -ForegroundColor Red }
        $confirmation = Read-Host "Proceed? (yes/no)"
        if ($confirmation -ne "yes") {
            Write-Host "Dehydration cancelled." -ForegroundColor Yellow
            Pop-Location
            exit 0
        }
    }

    # 1) Remove compute: Function App + App Service Plan via targeted Terraform destroy
    Write-Host "Removing Function App compute via targeted Terraform destroy..." -ForegroundColor Yellow
    if ($AutoApprove) {
        terraform destroy -target="module.function_app.azurerm_linux_function_app.main" -auto-approve
    } else {
        terraform destroy -target="module.function_app.azurerm_linux_function_app.main"
    }
    if ($LASTEXITCODE -ne 0) { throw "Targeted destroy of Function App failed" }

    Write-Host "Removing App Service Plan via targeted Terraform destroy..." -ForegroundColor Yellow
    if ($AutoApprove) {
        terraform destroy -target="module.function_app.azurerm_service_plan.main" -auto-approve
    } else {
        terraform destroy -target="module.function_app.azurerm_service_plan.main"
    }
    if ($LASTEXITCODE -ne 0) { throw "Targeted destroy of App Service Plan failed" }

    # Optional: remove KV access policy tied to the Function App principal to keep KV clean
    Write-Host "Cleaning Key Vault access policy for Function App (optional)..." -ForegroundColor Yellow
    if ($AutoApprove) {
        terraform destroy -target=azurerm_key_vault_access_policy.function_app -auto-approve 2>$null
    } else {
        terraform destroy -target=azurerm_key_vault_access_policy.function_app 2>$null
    }
    # Do not fail if this targeted destroy is not applicable

    # 2) Reduce Log Analytics retention to requested days
    Write-Host "Updating Log Analytics workspace retention to $RetentionDays days..." -ForegroundColor Yellow
    # Resolve App Insights component to find its linked workspaceResourceId
    $ai = az monitor app-insights component show -g $rgName -a $aiName 2>$null | ConvertFrom-Json
    if ($ai -and $ai.workspaceResourceId) {
        $lawId = $ai.workspaceResourceId
        az monitor log-analytics workspace update --ids $lawId --retention-time $RetentionDays | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ Log Analytics retention updated." -ForegroundColor Green
        } else {
            Write-Host "WARNING: Retention $RetentionDays days not allowed for this SKU. Falling back to 30 days." -ForegroundColor Yellow
            az monitor log-analytics workspace update --ids $lawId --retention-time 30 | Out-Null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✓ Log Analytics retention set to 30 days." -ForegroundColor Green
            } else {
                Write-Host "WARNING: Failed to update retention; workspace retains existing setting." -ForegroundColor Yellow
            }
        }
    } else {
        Write-Host "WARNING: Could not resolve workspaceResourceId for App Insights. Skipping retention update." -ForegroundColor Yellow
    }

    # 3) Optionally set Storage account default access tier to Cool
    if ($SetStorageCoolTier) {
        Write-Host "Setting Storage account default access tier to Cool..." -ForegroundColor Yellow
        $sa = az storage account show -g $rgName -n $saName 2>$null | ConvertFrom-Json
        if (-not $sa) {
            Write-Host "WARNING: Could not fetch storage account details. Skipping tier update." -ForegroundColor Yellow
        } else {
            $kind = $sa.kind
            if ($kind -in @('StorageV2','BlobStorage')) {
                az storage account update -g $rgName -n $saName --access-tier Cool | Out-Null
                Write-Host "✓ Storage default access tier set to Cool." -ForegroundColor Green
            } else {
                Write-Host "WARNING: Storage account kind '$kind' does not support account-level access tiers. Skipping." -ForegroundColor Yellow
            }
        }
    }

    Write-Host "" 
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "✓ Dehydration complete: compute removed, telemetry trimmed" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Rehydrate later with your Terraform apply or provisioning script." -ForegroundColor Cyan

} catch {
    Write-Host ""
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
} finally {
    if (Get-Location) { Pop-Location }
}
