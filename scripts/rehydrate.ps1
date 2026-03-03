#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Rehydrate minimal FluxOps compute for active testing

.DESCRIPTION
    Recreates the Function App compute layer (App Service Plan + Function App)
    and restores the Key Vault access policy, using Terraform. Preserves
    existing Storage, Key Vault, and Application Insights. Defaults to
    the low-cost Consumption SKU (Y1) unless overridden.

.PARAMETER AutoApprove
    Skips interactive confirmations for Terraform apply operations.

.PARAMETER Sku
    App Service Plan SKU to use for the Function App. Defaults to 'Y1' (Consumption).
    Other examples: 'B1' (Basic), 'P1v3' (Premium).

.PARAMETER DeployFunctionApp
    Also deploy the Function App code after compute is provisioned.

.PARAMETER SetStorageHotTier
    If specified, reverts the Storage account default access tier to Hot.

.EXAMPLE
    pwsh -File scripts/rehydrate.ps1

.EXAMPLE
    pwsh -File scripts/rehydrate.ps1 -Sku Y1 -AutoApprove -DeployFunctionApp
#>

param(
    [switch]$AutoApprove,
    [string]$Sku = 'Y1',
    [switch]$DeployFunctionApp,
    [switch]$SetStorageHotTier
)

$ErrorActionPreference = 'Stop'

Write-Host '========================================' -ForegroundColor Cyan
Write-Host 'FluxOps Rehydrate (Compute Only)' -ForegroundColor Cyan
Write-Host '========================================' -ForegroundColor Cyan
Write-Host ''

# Check prerequisites
if (-not (Get-Command terraform -ErrorAction SilentlyContinue)) {
    Write-Host 'ERROR: Terraform is not installed or not in PATH' -ForegroundColor Red
    exit 1
}
if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    Write-Host 'ERROR: Azure CLI is not installed or not in PATH' -ForegroundColor Red
    exit 1
}

Write-Host 'Checking Azure authentication...' -ForegroundColor Yellow
$account = az account show 2>$null | ConvertFrom-Json
if (-not $account) {
    Write-Host "ERROR: Not logged into Azure. Run 'az login' first." -ForegroundColor Red
    exit 1
}
Write-Host "✓ Logged in as: $($account.user.name)" -ForegroundColor Green
Write-Host "✓ Subscription: $($account.name) ($($account.id))" -ForegroundColor Green
Write-Host ''

try {
    # Navigate to Terraform directory
    $terraformDir = Join-Path $PSScriptRoot '..' 'infra' 'terraform'
    if (-not (Test-Path $terraformDir)) {
        Write-Host "ERROR: Terraform directory not found at $terraformDir" -ForegroundColor Red
        exit 1
    }
    Push-Location $terraformDir

    Write-Host 'Initializing Terraform...' -ForegroundColor Yellow
    terraform init
    if ($LASTEXITCODE -ne 0) { throw 'Terraform init failed' }

    Write-Host "Using Function App SKU: $Sku" -ForegroundColor Yellow
    Write-Host ''

    if (-not $AutoApprove) {
        Write-Host 'This will create compute resources:' -ForegroundColor Yellow
        Write-Host ' - App Service Plan' -ForegroundColor Yellow
        Write-Host ' - Linux Function App' -ForegroundColor Yellow
        Write-Host ' - Key Vault access policy for Function App' -ForegroundColor Yellow
        $confirmation = Read-Host 'Proceed? (yes/no)'
        if ($confirmation -ne 'yes') {
            Write-Host 'Rehydrate cancelled.' -ForegroundColor Yellow
            Pop-Location
            exit 0
        }
    }

    # Create App Service Plan first (targeted)
    Write-Host 'Creating App Service Plan...' -ForegroundColor Yellow
    if ($AutoApprove) {
        terraform apply -target=module.function_app.azurerm_service_plan.main -var "function_app_sku=$Sku" -auto-approve
    } else {
        terraform apply -target=module.function_app.azurerm_service_plan.main -var "function_app_sku=$Sku"
    }
    if ($LASTEXITCODE -ne 0) { throw 'Terraform apply (service plan) failed' }

    # Create Function App (targeted)
    Write-Host 'Creating Linux Function App...' -ForegroundColor Yellow
    if ($AutoApprove) {
        terraform apply -target=module.function_app.azurerm_linux_function_app.main -var "function_app_sku=$Sku" -auto-approve
    } else {
        terraform apply -target=module.function_app.azurerm_linux_function_app.main -var "function_app_sku=$Sku"
    }
    if ($LASTEXITCODE -ne 0) { throw 'Terraform apply (function app) failed' }

    # Restore Key Vault access policy (not in a module)
    Write-Host 'Restoring Key Vault access policy for Function App...' -ForegroundColor Yellow
    if ($AutoApprove) {
        terraform apply -target=azurerm_key_vault_access_policy.function_app -auto-approve
    } else {
        terraform apply -target=azurerm_key_vault_access_policy.function_app
    }
    # If this resource does not exist yet, a full apply will cover it later

    # Get outputs
    Write-Host ''
    $outputs = terraform output -json | ConvertFrom-Json
    $funcName = $outputs.function_app_name.value
    $rgName = $outputs.resource_group_name.value
    $saName = $outputs.storage_account_name.value
    Write-Host '========================================' -ForegroundColor Green
    Write-Host "✓ Compute rehydrated! Function App: $funcName" -ForegroundColor Green
    Write-Host '========================================' -ForegroundColor Green
    Write-Host ''
    
    # Optionally revert Storage default tier to Hot
    if ($SetStorageHotTier) {
        Write-Host "Reverting Storage account default access tier to Hot..." -ForegroundColor Yellow
        $sa = az storage account show -g $rgName -n $saName 2>$null | ConvertFrom-Json
        if (-not $sa) {
            Write-Host "WARNING: Could not fetch storage account details. Skipping tier update." -ForegroundColor Yellow
        } else {
            $kind = $sa.kind
            if ($kind -in @('StorageV2','BlobStorage')) {
                az storage account update -g $rgName -n $saName --access-tier Hot | Out-Null
                Write-Host "✓ Storage default access tier set to Hot." -ForegroundColor Green
            } else {
                Write-Host "WARNING: Storage account kind '$kind' does not support account-level access tiers. Skipping." -ForegroundColor Yellow
            }
        }
    }

    Pop-Location

    # Optional: deploy Function App code
    if ($DeployFunctionApp) {
        Write-Host 'Deploying Function App code...' -ForegroundColor Yellow
        $functionAppDir = Join-Path $PSScriptRoot '..' 'src' 'function_app'
        Push-Location $functionAppDir
        try {
            if (-not (Get-Command func -ErrorAction SilentlyContinue)) {
                Write-Host 'ERROR: Azure Functions Core Tools (func) not found in PATH.' -ForegroundColor Red
                throw 'Missing func tool'
            }
            func azure functionapp publish $funcName --python
            if ($LASTEXITCODE -ne 0) { throw 'Function App deployment failed' }
            Write-Host '✓ Function App deployed successfully!' -ForegroundColor Green
        } finally {
            Pop-Location
        }
    }

    Write-Host ''
    Write-Host 'Next steps:' -ForegroundColor Cyan
    Write-Host '  - Test your endpoints or functions' -ForegroundColor White
    Write-Host "  - When done, run: pwsh -File scripts/dehydrate.ps1 -AutoApprove" -ForegroundColor White

} catch {
    Write-Host ''
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    try { if (Get-Location) { Pop-Location } } catch {}
    exit 1
}
