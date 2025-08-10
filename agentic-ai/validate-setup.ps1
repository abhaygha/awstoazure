# 🔍 Agentic AI Setup Validation Script
# This script checks for common issues and validates the setup

param(
    [string]$ProjectName = "awstoazure",
    [string]$Environment = "dev",
    [string]$AwsRegion = "us-east-1"
)

Write-Host "🔍 Validating Agentic AI Setup..." -ForegroundColor Cyan
Write-Host ""

# Check prerequisites
Write-Host "📋 Checking Prerequisites..." -ForegroundColor Yellow

# Check AWS CLI
try {
    $awsVersion = aws --version 2>$null
    if ($awsVersion) {
        Write-Host "   ✅ AWS CLI: $awsVersion" -ForegroundColor Green
    } else {
        Write-Host "   ❌ AWS CLI: Not found" -ForegroundColor Red
        Write-Host "      Install from: https://aws.amazon.com/cli/" -ForegroundColor Gray
    }
} catch {
    Write-Host "   ❌ AWS CLI: Not found" -ForegroundColor Red
}

# Check Terraform
try {
    $terraformVersion = terraform --version 2>$null
    if ($terraformVersion) {
        Write-Host "   ✅ Terraform: $terraformVersion" -ForegroundColor Green
    } else {
        Write-Host "   ❌ Terraform: Not found" -ForegroundColor Red
        Write-Host "      Install from: https://www.terraform.io/downloads" -ForegroundColor Gray
    }
} catch {
    Write-Host "   ❌ Terraform: Not found" -ForegroundColor Red
}

# Check Node.js
try {
    $nodeVersion = node --version 2>$null
    if ($nodeVersion) {
        Write-Host "   ✅ Node.js: $nodeVersion" -ForegroundColor Green
    } else {
        Write-Host "   ❌ Node.js: Not found" -ForegroundColor Red
        Write-Host "      Install from: https://nodejs.org/" -ForegroundColor Gray
    }
} catch {
    Write-Host "   ❌ Node.js: Not found" -ForegroundColor Red
}

Write-Host ""

# Check project structure
Write-Host "📁 Checking Project Structure..." -ForegroundColor Yellow

$requiredFiles = @(
    "agent/index.js",
    "agent/package.json",
    "infrastructure/main.tf",
    "infrastructure/variables.tf",
    "infrastructure/outputs.tf",
    "deploy.ps1",
    "deploy.sh",
    "README.md",
    "USAGE.md"
)

foreach ($file in $requiredFiles) {
    if (Test-Path $file) {
        Write-Host "   ✅ $file" -ForegroundColor Green
    } else {
        Write-Host "   ❌ $file - Missing" -ForegroundColor Red
    }
}

Write-Host ""

# Check agent build
Write-Host "🔨 Checking Agent Build..." -ForegroundColor Yellow

if (Test-Path "agent/dist/agent.zip") {
    Write-Host "   ✅ Lambda package: agent/dist/agent.zip" -ForegroundColor Green
    $fileSize = (Get-Item "agent/dist/agent.zip").Length
    Write-Host "      Size: $([math]::Round($fileSize/1KB, 2)) KB" -ForegroundColor Gray
} else {
    Write-Host "   ⚠️  Lambda package: Not built yet" -ForegroundColor Yellow
    Write-Host "      Run: cd agent && npm run build" -ForegroundColor Gray
}

Write-Host ""

# Check AWS credentials
Write-Host "🔐 Checking AWS Configuration..." -ForegroundColor Yellow

try {
    $awsIdentity = aws sts get-caller-identity 2>$null | ConvertFrom-Json
    if ($awsIdentity) {
        Write-Host "   ✅ AWS Account: $($awsIdentity.Account)" -ForegroundColor Green
        Write-Host "   ✅ AWS User: $($awsIdentity.Arn)" -ForegroundColor Green
        Write-Host "   ✅ AWS Region: $AwsRegion" -ForegroundColor Green
    } else {
        Write-Host "   ❌ AWS credentials: Not configured" -ForegroundColor Red
        Write-Host "      Run: aws configure" -ForegroundColor Gray
    }
} catch {
    Write-Host "   ❌ AWS credentials: Not configured" -ForegroundColor Red
    Write-Host "      Run: aws configure" -ForegroundColor Gray
}

Write-Host ""

# Summary
Write-Host "📊 Validation Summary:" -ForegroundColor Cyan

$totalChecks = 0
$passedChecks = 0

# Count checks (simplified)
$totalChecks = 8  # Prerequisites + Structure + Build + AWS
$passedChecks = 0

if (Get-Command aws -ErrorAction SilentlyContinue) { $passedChecks++ }
if (Get-Command terraform -ErrorAction SilentlyContinue) { $passedChecks++ }
if (Get-Command node -ErrorAction SilentlyContinue) { $passedChecks++ }
if (Test-Path "agent/dist/agent.zip") { $passedChecks++ }
if (Test-Path "infrastructure/main.tf") { $passedChecks++ }
if (Test-Path "agent/index.js") { $passedChecks++ }
if (Test-Path "deploy.ps1") { $passedChecks++ }
if (Test-Path "deploy.sh") { $passedChecks++ }

Write-Host "   Passed: $passedChecks/$totalChecks checks" -ForegroundColor $(if ($passedChecks -eq $totalChecks) { "Green" } else { "Yellow" })

Write-Host ""

if ($passedChecks -eq $totalChecks) {
    Write-Host "🎉 Setup is ready! You can now deploy with:" -ForegroundColor Green
    Write-Host "   .\deploy.ps1 -ProjectName $ProjectName -Environment $Environment -AwsRegion $AwsRegion" -ForegroundColor Cyan
} else {
    Write-Host "⚠️  Some issues found. Please fix them before deployment." -ForegroundColor Yellow
    Write-Host "   Check the ❌ items above for details." -ForegroundColor Gray
}

Write-Host ""
