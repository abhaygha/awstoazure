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

# Check Python
try {
    $pythonVersion = python3 --version 2>$null
    if ($pythonVersion) {
        Write-Host "   ✅ Python: $pythonVersion" -ForegroundColor Green
    } else {
        $pythonVersion = python --version 2>$null
        if ($pythonVersion) {
            Write-Host "   ✅ Python: $pythonVersion" -ForegroundColor Green
        } else {
            Write-Host "   ❌ Python: Not found" -ForegroundColor Red
            Write-Host "      Install from: https://python.org/downloads/" -ForegroundColor Gray
        }
    }
} catch {
    Write-Host "   ❌ Python: Not found" -ForegroundColor Red
}

Write-Host ""

# Check project structure
Write-Host "📁 Checking Project Structure..." -ForegroundColor Yellow

$requiredFiles = @(
    "agent-python/lambda_function.py",
    "agent-python/requirements.txt",
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

if (Test-Path "agent-python/agent.zip") {
    Write-Host "   ✅ Lambda package: agent-python/agent.zip" -ForegroundColor Green
    $fileSize = (Get-Item "agent-python/agent.zip").Length
    Write-Host "      Size: $([math]::Round($fileSize/1KB, 2)) KB" -ForegroundColor Gray
} else {
    Write-Host "   ⚠️  Lambda package: Not built yet" -ForegroundColor Yellow
    Write-Host "      Run: cd agent-python && python deploy.py" -ForegroundColor Gray
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
if ((Get-Command python3 -ErrorAction SilentlyContinue) -or (Get-Command python -ErrorAction SilentlyContinue)) { $passedChecks++ }
if (Test-Path "agent-python/agent.zip") { $passedChecks++ }
if (Test-Path "infrastructure/main.tf") { $passedChecks++ }
if (Test-Path "agent-python/lambda_function.py") { $passedChecks++ }
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
