#!/bin/bash

# Agentic AI Deployment Script
# This script sets up and deploys the complete Agentic AI system on AWS

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="awstoazure"
ENVIRONMENT="dev"
AWS_REGION="us-east-1"

echo -e "${BLUE}🚀 Starting Agentic AI Deployment...${NC}"

# Check prerequisites
echo -e "${YELLOW}📋 Checking prerequisites...${NC}"

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo -e "${RED}❌ AWS CLI is not installed. Please install it first.${NC}"
    exit 1
fi

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}❌ Terraform is not installed. Please install it first.${NC}"
    exit 1
fi

# Check if Python is installed
if ! command -v python3 &> /dev/null && ! command -v python &> /dev/null; then
    echo -e "${RED}❌ Python is not installed. Please install it first.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ All prerequisites are met!${NC}"

# Check AWS credentials
echo -e "${YELLOW}🔐 Checking AWS credentials...${NC}"
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}❌ AWS credentials not configured. Please run 'aws configure' first.${NC}"
    exit 1
fi

AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo -e "${GREEN}✅ AWS credentials verified. Account ID: ${AWS_ACCOUNT_ID}${NC}"

# Build the Lambda function
echo -e "${YELLOW}🔨 Building Lambda function...${NC}"
cd agent-python
python3 deploy.py 2>/dev/null || python deploy.py
cd ..

# Initialize Terraform
echo -e "${YELLOW}🏗️  Initializing Terraform...${NC}"
cd infrastructure
terraform init

# Plan Terraform deployment
echo -e "${YELLOW}📋 Planning Terraform deployment...${NC}"
terraform plan -var="project_name=${PROJECT_NAME}" -var="environment=${ENVIRONMENT}" -var="aws_region=${AWS_REGION}"

# Confirm deployment
echo -e "${YELLOW}⚠️  Do you want to proceed with the deployment? (y/N)${NC}"
read -r response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo -e "${BLUE}🚀 Deploying infrastructure...${NC}"
    terraform apply -var="project_name=${PROJECT_NAME}" -var="environment=${ENVIRONMENT}" -var="aws_region=${AWS_REGION}" -auto-approve
    
    # Get outputs
    LAMBDA_FUNCTION_ARN=$(terraform output -raw lambda_function_arn)
    STEP_FUNCTION_ARN=$(terraform output -raw step_function_arn)
    EVENTBRIDGE_BUS=$(terraform output -raw eventbridge_bus_name)
    SQS_QUEUE_URL=$(terraform output -raw sqs_queue_url)
    
    echo -e "${GREEN}✅ Infrastructure deployed successfully!${NC}"
    echo -e "${BLUE}📊 Deployment Summary:${NC}"
    echo -e "   Lambda Function ARN: ${LAMBDA_FUNCTION_ARN}"
    echo -e "   Step Function ARN: ${STEP_FUNCTION_ARN}"
    echo -e "   EventBridge Bus: ${EVENTBRIDGE_BUS}"
    echo -e "   SQS Queue URL: ${SQS_QUEUE_URL}"
    
    # Update Lambda function code
    echo -e "${YELLOW}📦 Updating Lambda function code...${NC}"
    aws lambda update-function-code \
        --function-name "${PROJECT_NAME}-agentic-ai-agent" \
        --zip-file fileb://agent-python/agent.zip \
        --region "${AWS_REGION}"
    
    echo -e "${GREEN}✅ Lambda function code updated!${NC}"
    
    # Test the system
    echo -e "${YELLOW}🧪 Testing the Agentic AI system...${NC}"
    
    # Test S3 bucket creation
    echo -e "${BLUE}   Testing S3 bucket creation...${NC}"
    aws lambda invoke \
        --function-name "${PROJECT_NAME}-agentic-ai-agent" \
        --payload '{"prompt": "create a bucket for me", "userId": "test-user", "requestId": "test-001"}' \
        --region "${AWS_REGION}" \
        response.json
    
    if [ -f response.json ]; then
        echo -e "${GREEN}   ✅ S3 bucket creation test completed${NC}"
        cat response.json
        rm response.json
    fi
    
    echo -e "${GREEN}🎉 Agentic AI deployment completed successfully!${NC}"
    echo -e "${BLUE}📚 Next steps:${NC}"
    echo -e "   1. Test the system with different prompts"
    echo -e "   2. Monitor CloudWatch logs for operation details"
    echo -e "   3. Set up additional IAM permissions if needed"
    echo -e "   4. Configure monitoring and alerting"
    
else
    echo -e "${YELLOW}❌ Deployment cancelled.${NC}"
    exit 0
fi

cd ..
