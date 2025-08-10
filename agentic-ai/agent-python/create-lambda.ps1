# PowerShell script to create Agentic AI Lambda function using AWS CLI

param(
    [string]$FunctionName = "agentic-ai-agent",
    [string]$Runtime = "python3.11",
    [string]$Handler = "lambda_function.lambda_handler",
    [int]$Timeout = 300,
    [int]$MemorySize = 512,
    [string]$Region = "us-east-1"
)

Write-Host "🚀 Creating Agentic AI Lambda Function..." -ForegroundColor Green

Write-Host "📋 Configuration:" -ForegroundColor Yellow
Write-Host "  Function Name: $FunctionName" -ForegroundColor White
Write-Host "  Runtime: $Runtime" -ForegroundColor White
Write-Host "  Handler: $Handler" -ForegroundColor White
Write-Host "  Timeout: ${Timeout}s" -ForegroundColor White
Write-Host "  Memory: ${MemorySize}MB" -ForegroundColor White
Write-Host "  Region: $Region" -ForegroundColor White
Write-Host ""

# Step 1: Create IAM Role
Write-Host "🔐 Step 1: Creating IAM Role..." -ForegroundColor Yellow
$RoleName = "agentic-ai-lambda-role"

# Create trust policy for Lambda
$TrustPolicy = @{
    Version = "2012-10-17"
    Statement = @(
        @{
            Effect = "Allow"
            Principal = @{
                Service = "lambda.amazonaws.com"
            }
            Action = "sts:AssumeRole"
        }
    )
} | ConvertTo-Json -Depth 10

# Create the role
try {
    aws iam create-role `
        --role-name $RoleName `
        --assume-role-policy-document "$TrustPolicy" `
        --description "Role for Agentic AI Lambda function"
    Write-Host "✅ IAM Role created: $RoleName" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Role might already exist, continuing..." -ForegroundColor Yellow
}

# Attach basic Lambda execution policy
aws iam attach-role-policy `
    --role-name $RoleName `
    --policy-arn "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"

# Create custom policy for AWS operations
$LambdaPolicy = @{
    Version = "2012-10-17"
    Statement = @(
        @{
            Effect = "Allow"
            Action = @(
                "s3:CreateBucket",
                "s3:DeleteBucket",
                "s3:PutBucketTagging",
                "s3:GetBucketTagging",
                "ec2:RunInstances",
                "ec2:TerminateInstances",
                "ec2:CreateTags",
                "ec2:DescribeInstances",
                "lambda:CreateFunction",
                "lambda:DeleteFunction",
                "lambda:UpdateFunctionCode",
                "rds:CreateDBInstance",
                "rds:DeleteDBInstance",
                "rds:DescribeDBInstances",
                "ec2:CreateVpc",
                "ec2:DeleteVpc",
                "ec2:CreateSubnet",
                "ec2:DeleteSubnet",
                "ec2:CreateSecurityGroup",
                "ec2:DeleteSecurityGroup",
                "events:PutEvents",
                "sqs:SendMessage",
                "sqs:ReceiveMessage",
                "sqs:DeleteMessage",
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            )
            Resource = "*"
        }
    )
} | ConvertTo-Json -Depth 10

# Attach custom policy
aws iam put-role-policy `
    --role-name $RoleName `
    --policy-name "AgenticAIOperations" `
    --policy-document "$LambdaPolicy"

# Step 2: Wait for role to propagate
Write-Host "⏳ Waiting for IAM role to propagate..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# Step 3: Get role ARN
$RoleArn = aws iam get-role --role-name $RoleName --query 'Role.Arn' --output text
Write-Host "📋 Role ARN: $RoleArn" -ForegroundColor Cyan

# Step 4: Create Lambda function
Write-Host "🔧 Step 2: Creating Lambda Function..." -ForegroundColor Yellow

# Check if agent.zip exists
$AgentZipPath = "..\agent-python\dist\agent.zip"
if (-not (Test-Path $AgentZipPath)) {
    Write-Host "❌ Error: agent.zip not found. Please run deploy.py first." -ForegroundColor Red
    exit 1
}

# Create the Lambda function
try {
    aws lambda create-function `
        --function-name $FunctionName `
        --runtime $Runtime `
        --role $RoleArn `
        --handler $Handler `
        --zip-file "fileb://$AgentZipPath" `
        --timeout $Timeout `
        --memory-size $MemorySize `
        --description "Agentic AI - Autonomous AWS Operations Agent" `
        --region $Region
    
    Write-Host "✅ Lambda function created: $FunctionName" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Function might already exist, continuing..." -ForegroundColor Yellow
}

# Step 5: Configure environment variables
Write-Host "🔧 Step 3: Configuring Environment Variables..." -ForegroundColor Yellow

$EnvironmentVars = @{
    ENVIRONMENT = "dev"
    PROJECT_NAME = "agentic-ai"
    LOG_LEVEL = "INFO"
} | ConvertTo-Json

aws lambda update-function-configuration `
    --function-name $FunctionName `
    --environment "Variables=$EnvironmentVars" `
    --region $Region

Write-Host "✅ Environment variables configured" -ForegroundColor Green

# Step 6: Test the function
Write-Host "🧪 Step 4: Testing the function..." -ForegroundColor Yellow

# Create test payload
$TestPayload = @{
    prompt = "Create an S3 bucket"
    userId = "test-user"
    requestId = "test-123"
} | ConvertTo-Json

# Test invocation
Write-Host "📤 Invoking Lambda function..." -ForegroundColor Yellow
aws lambda invoke `
    --function-name $FunctionName `
    --payload "$TestPayload" `
    --region $Region `
    "response.json"

Write-Host "📥 Response received:" -ForegroundColor Green
Get-Content "response.json" | ConvertFrom-Json | ConvertTo-Json -Depth 10

# Cleanup temporary files
Remove-Item "response.json" -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "🎉 Agentic AI Lambda Function Created Successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Function Details:" -ForegroundColor Yellow
Write-Host "  Name: $FunctionName" -ForegroundColor White
Write-Host "  ARN: arn:aws:lambda:${Region}:$(aws sts get-caller-identity --query Account --output text):function:${FunctionName}" -ForegroundColor White
Write-Host "  Role: $RoleName" -ForegroundColor White
Write-Host ""
Write-Host "🚀 Ready to receive JSON payloads!" -ForegroundColor Green
Write-Host ""
Write-Host "💡 Test with:" -ForegroundColor Yellow
Write-Host "  aws lambda invoke --function-name $FunctionName --payload '{\"prompt\": \"Create an S3 bucket\"}' response.json" -ForegroundColor White
