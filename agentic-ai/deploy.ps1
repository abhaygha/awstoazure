# Agentic AI Deployment Script for Windows
# This script sets up and deploys the complete Agentic AI system on AWS

param(
    [string]$ProjectName = "awstoazure",
    [string]$Environment = "dev",
    [string]$AwsRegion = "us-east-1"
)

# Error handling
$ErrorActionPreference = "Stop"

# Colors for output
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

Write-ColorOutput "🚀 Starting Agentic AI Deployment..." "Blue"

# Check prerequisites
Write-ColorOutput "📋 Checking prerequisites..." "Yellow"

# Check if AWS CLI is installed
try {
    $null = Get-Command aws -ErrorAction Stop
    Write-ColorOutput "✅ AWS CLI is installed" "Green"
} catch {
    Write-ColorOutput "❌ AWS CLI is not installed. Please install it first." "Red"
    exit 1
}

# Check if Terraform is installed
try {
    $null = Get-Command terraform -ErrorAction Stop
    Write-ColorOutput "✅ Terraform is installed" "Green"
} catch {
    Write-ColorOutput "❌ Terraform is not installed. Please install it first." "Red"
    exit 1
}

# Check if Python is installed
try {
    $null = Get-Command python3 -ErrorAction Stop
    Write-ColorOutput "✅ Python3 is installed" "Green"
} catch {
    try {
        $null = Get-Command python -ErrorAction Stop
        Write-ColorOutput "✅ Python is installed" "Green"
    } catch {
        Write-ColorOutput "❌ Python is not installed. Please install it first." "Red"
        exit 1
    }
}

Write-ColorOutput "✅ All prerequisites are met!" "Green"

# Check AWS credentials
Write-ColorOutput "🔐 Checking AWS credentials..." "Yellow"
try {
    $callerIdentity = aws sts get-caller-identity | ConvertFrom-Json
    $awsAccountId = $callerIdentity.Account
    Write-ColorOutput "✅ AWS credentials verified. Account ID: $awsAccountId" "Green"
} catch {
    Write-ColorOutput "❌ AWS credentials not configured. Please run 'aws configure' first." "Red"
    exit 1
}

# Build the Lambda function
Write-ColorOutput "🔨 Building Lambda function..." "Yellow"
Set-Location agent-python
try {
    python3 deploy.py
} catch {
    python deploy.py
}
Set-Location ..

# Initialize Terraform
Write-ColorOutput "🏗️  Initializing Terraform..." "Yellow"
Set-Location infrastructure
terraform init

# Plan Terraform deployment
Write-ColorOutput "📋 Planning Terraform deployment..." "Yellow"
terraform plan -var="project_name=$ProjectName" -var="environment=$Environment" -var="aws_region=$AwsRegion"

# Confirm deployment
Write-ColorOutput "⚠️  Do you want to proceed with the deployment? (y/N)" "Yellow"
$response = Read-Host
if ($response -match "^[yY][eE]?[sS]?$") {
    Write-ColorOutput "🚀 Deploying infrastructure..." "Blue"
    terraform apply -var="project_name=$ProjectName" -var="environment=$Environment" -var="aws_region=$AwsRegion" -auto-approve
    
    # Get outputs
    $lambdaFunctionArn = terraform output -raw lambda_function_arn
    $stepFunctionArn = terraform output -raw step_function_arn
    $eventbridgeBus = terraform output -raw eventbridge_bus_name
    $sqsQueueUrl = terraform output -raw sqs_queue_url
    
    Write-ColorOutput "✅ Infrastructure deployed successfully!" "Green"
    Write-ColorOutput "📊 Deployment Summary:" "Blue"
    Write-ColorOutput "   Lambda Function ARN: $lambdaFunctionArn" "White"
    Write-ColorOutput "   Step Function ARN: $stepFunctionArn" "White"
    Write-ColorOutput "   EventBridge Bus: $eventbridgeBus" "White"
    Write-ColorOutput "   SQS Queue URL: $sqsQueueUrl" "White"
    
    # Update Lambda function code
    Write-ColorOutput "📦 Updating Lambda function code..." "Yellow"
    aws lambda update-function-code `
        --function-name "$ProjectName-agentic-ai-agent" `
        --zip-file fileb://agent-python/agent.zip `
        --region "$AwsRegion"
    
    Write-ColorOutput "✅ Lambda function code updated!" "Green"
    
    # Test the system
    Write-ColorOutput "🧪 Testing the Agentic AI system..." "Yellow"
    
    # Test S3 bucket creation
    Write-ColorOutput "   Testing S3 bucket creation..." "Blue"
    $testPayload = @{
        prompt = "create a bucket for me"
        userId = "test-user"
        requestId = "test-001"
    } | ConvertTo-Json -Compress
    
    aws lambda invoke `
        --function-name "$ProjectName-agentic-ai-agent" `
        --payload $testPayload `
        --region "$AwsRegion" `
        response.json
    
    if (Test-Path response.json) {
        Write-ColorOutput "   ✅ S3 bucket creation test completed" "Green"
        Get-Content response.json
        Remove-Item response.json
    }
    
    Write-ColorOutput "🎉 Agentic AI deployment completed successfully!" "Green"
    Write-ColorOutput "📚 Next steps:" "Blue"
    Write-ColorOutput "   1. Test the system with different prompts" "White"
    Write-ColorOutput "   2. Monitor CloudWatch logs for operation details" "White"
    Write-ColorOutput "   3. Set up additional IAM permissions if needed" "White"
    Write-ColorOutput "   4. Configure monitoring and alerting" "White"
    
} else {
    Write-ColorOutput "❌ Deployment cancelled." "Yellow"
    exit 0
}

Set-Location ..
