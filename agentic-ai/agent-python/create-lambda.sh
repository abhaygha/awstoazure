#!/bin/bash

# Script to create Agentic AI Lambda function using AWS CLI

set -e

echo "🚀 Creating Agentic AI Lambda Function..."

# Configuration
FUNCTION_NAME="agentic-ai-agent"
RUNTIME="python3.11"
HANDLER="lambda_function.lambda_handler"
TIMEOUT=300
MEMORY_SIZE=512
REGION="us-east-1"

echo "📋 Configuration:"
echo "  Function Name: $FUNCTION_NAME"
echo "  Runtime: $RUNTIME"
echo "  Handler: $HANDLER"
echo "  Timeout: ${TIMEOUT}s"
echo "  Memory: ${MEMORY_SIZE}MB"
echo "  Region: $REGION"
echo ""

# Step 1: Create IAM Role
echo "🔐 Step 1: Creating IAM Role..."
ROLE_NAME="agentic-ai-lambda-role"

# Create trust policy for Lambda
cat > trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

# Create the role
aws iam create-role \
  --role-name $ROLE_NAME \
  --assume-role-policy-document file://trust-policy.json \
  --description "Role for Agentic AI Lambda function"

# Attach basic Lambda execution policy
aws iam attach-role-policy \
  --role-name $ROLE_NAME \
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

# Create custom policy for AWS operations
cat > lambda-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
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
      ],
      "Resource": "*"
    }
  ]
}
EOF

# Attach custom policy
aws iam put-role-policy \
  --role-name $ROLE_NAME \
  --policy-name AgenticAIOperations \
  --policy-document file://lambda-policy.json

echo "✅ IAM Role created: $ROLE_NAME"

# Step 2: Wait for role to propagate
echo "⏳ Waiting for IAM role to propagate..."
sleep 10

# Step 3: Get role ARN
ROLE_ARN=$(aws iam get-role --role-name $ROLE_NAME --query 'Role.Arn' --output text)
echo "📋 Role ARN: $ROLE_ARN"

# Step 4: Create Lambda function
echo "🔧 Step 2: Creating Lambda Function..."

# Check if agent.zip exists
if [ ! -f "../agent-python/dist/agent.zip" ]; then
    echo "❌ Error: agent.zip not found. Please run deploy.py first."
    exit 1
fi

# Create the Lambda function
aws lambda create-function \
  --function-name $FUNCTION_NAME \
  --runtime $RUNTIME \
  --role $ROLE_ARN \
  --handler $HANDLER \
  --zip-file fileb://../agent-python/dist/agent.zip \
  --timeout $TIMEOUT \
  --memory-size $MEMORY_SIZE \
  --description "Agentic AI - Autonomous AWS Operations Agent" \
  --region $REGION

echo "✅ Lambda function created: $FUNCTION_NAME"

# Step 5: Configure environment variables
echo "🔧 Step 3: Configuring Environment Variables..."

aws lambda update-function-configuration \
  --function-name $FUNCTION_NAME \
  --environment Variables='{
    "ENVIRONMENT": "dev",
    "PROJECT_NAME": "agentic-ai",
    "LOG_LEVEL": "INFO"
  }' \
  --region $REGION

echo "✅ Environment variables configured"

# Step 6: Test the function
echo "🧪 Step 4: Testing the function..."

# Create test payload
cat > test-payload.json << EOF
{
  "prompt": "Create an S3 bucket",
  "userId": "test-user",
  "requestId": "test-123"
}
EOF

# Test invocation
echo "📤 Invoking Lambda function..."
aws lambda invoke \
  --function-name $FUNCTION_NAME \
  --payload file://test-payload.json \
  --region $REGION \
  response.json

echo "📥 Response received:"
cat response.json | python3 -m json.tool

# Cleanup temporary files
rm -f trust-policy.json lambda-policy.json test-payload.json response.json

echo ""
echo "🎉 Agentic AI Lambda Function Created Successfully!"
echo ""
echo "📋 Function Details:"
echo "  Name: $FUNCTION_NAME"
echo "  ARN: arn:aws:lambda:${REGION}:$(aws sts get-caller-identity --query Account --output text):function:${FUNCTION_NAME}"
echo "  Role: $ROLE_NAME"
echo ""
echo "🚀 Ready to receive JSON payloads!"
echo ""
echo "💡 Test with:"
echo "  aws lambda invoke --function-name $FUNCTION_NAME --payload '{\"prompt\": \"Create an S3 bucket\"}' response.json"
