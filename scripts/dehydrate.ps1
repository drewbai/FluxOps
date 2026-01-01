#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Tear down FluxOps Azure resources to save costs

.DESCRIPTION
    Destroys all Azure infrastructure created by Terraform.
    Use this when you want to stop incurring Azure charges.

.EXAMPLE
    .\scripts\teardown.ps1
    
.EXAMPLE
    .\scripts\teardown.ps1 -AutoApprove
#>

param(
    [switch]$AutoApprove
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "FluxOps Resource Teardown" -ForegroundColor Cyan
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
    # Check if Terraform is initialized
    if (-not (Test-Path ".terraform")) {
        Write-Host "Terraform not initialized. Running 'terraform init'..." -ForegroundColor Yellow
        terraform init
        if ($LASTEXITCODE -ne 0) {
            throw "Terraform init failed"
        }
    }

    Write-Host ""
    Write-Host "WARNING: This will destroy ALL FluxOps Azure resources!" -ForegroundColor Red
    Write-Host ""
    
    if (-not $AutoApprove) {
        $confirmation = Read-Host "Are you sure you want to proceed? (yes/no)"
        if ($confirmation -ne "yes") {
            Write-Host "Teardown cancelled." -ForegroundColor Yellow
            exit 0
        }
    }

    Write-Host ""
    Write-Host "Running Terraform destroy..." -ForegroundColor Yellow
    
    if ($AutoApprove) {
        terraform destroy -auto-approve
    } else {
        terraform destroy
    }

    if ($LASTEXITCODE -ne 0) {
        throw "Terraform destroy failed"
    }

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "✓ Resources torn down successfully!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "To recreate resources later, run: .\scripts\provision.ps1" -ForegroundColor Cyan

} catch {
    Write-Host ""
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
} finally {
    Pop-Location
}
