#!/bin/bash

# 🔍 Agentic AI Setup Validation Script (Bash Version)
# This script checks for common issues and validates the setup

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
NC='\033[0m' # No Color

# Default values
PROJECT_NAME=${1:-"awstoazure"}
ENVIRONMENT=${2:-"dev"}
AWS_REGION=${3:-"us-east-1"}

echo -e "${CYAN}🔍 Validating Agentic AI Setup...${NC}"
echo ""

# Check prerequisites
echo -e "${YELLOW}📋 Checking Prerequisites...${NC}"

# Check AWS CLI
if command -v aws &> /dev/null; then
    AWS_VERSION=$(aws --version 2>/dev/null)
    echo -e "   ${GREEN}✅ AWS CLI: $AWS_VERSION${NC}"
else
    echo -e "   ${RED}❌ AWS CLI: Not found${NC}"
    echo -e "      ${GRAY}Install from: https://aws.amazon.com/cli/${NC}"
fi

# Check Terraform
if command -v terraform &> /dev/null; then
    TERRAFORM_VERSION=$(terraform --version 2>/dev/null | head -n1)
    echo -e "   ${GREEN}✅ Terraform: $TERRAFORM_VERSION${NC}"
else
    echo -e "   ${RED}❌ Terraform: Not found${NC}"
    echo -e "      ${GRAY}Install from: https://www.terraform.io/downloads${NC}"
fi

# Check Node.js
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version 2>/dev/null)
    echo -e "   ${GREEN}✅ Node.js: $NODE_VERSION${NC}"
else
    echo -e "   ${RED}❌ Node.js: Not found${NC}"
    echo -e "      ${GRAY}Install from: https://nodejs.org/${NC}"
fi

echo ""

# Check project structure
echo -e "${YELLOW}📁 Checking Project Structure...${NC}"

required_files=(
    "agent/index.js"
    "agent/package.json"
    "infrastructure/main.tf"
    "infrastructure/variables.tf"
    "infrastructure/outputs.tf"
    "deploy.ps1"
    "deploy.sh"
    "README.md"
    "USAGE.md"
)

for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        echo -e "   ${GREEN}✅ $file${NC}"
    else
        echo -e "   ${RED}❌ $file - Missing${NC}"
    fi
done

echo ""

# Check agent build
echo -e "${YELLOW}🔨 Checking Agent Build...${NC}"

if [ -f "agent/dist/agent.zip" ]; then
    echo -e "   ${GREEN}✅ Lambda package: agent/dist/agent.zip${NC}"
    file_size=$(stat -c%s "agent/dist/agent.zip" 2>/dev/null || stat -f%z "agent/dist/agent.zip" 2>/dev/null || echo "unknown")
    if [ "$file_size" != "unknown" ]; then
        size_kb=$((file_size / 1024))
        echo -e "      ${GRAY}Size: ${size_kb} KB${NC}"
    fi
else
    echo -e "   ${YELLOW}⚠️  Lambda package: Not built yet${NC}"
    echo -e "      ${GRAY}Run: cd agent && npm run build${NC}"
fi

echo ""

# Check AWS credentials
echo -e "${YELLOW}🔐 Checking AWS Configuration...${NC}"

if command -v aws &> /dev/null; then
    if aws sts get-caller-identity &>/dev/null; then
        AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text 2>/dev/null)
        AWS_USER=$(aws sts get-caller-identity --query Arn --output text 2>/dev/null)
        echo -e "   ${GREEN}✅ AWS Account: $AWS_ACCOUNT${NC}"
        echo -e "   ${GREEN}✅ AWS User: $AWS_USER${NC}"
        echo -e "   ${GREEN}✅ AWS Region: $AWS_REGION${NC}"
    else
        echo -e "   ${RED}❌ AWS credentials: Not configured${NC}"
        echo -e "      ${GRAY}Run: aws configure${NC}"
    fi
else
    echo -e "   ${RED}❌ AWS CLI not available${NC}"
fi

echo ""

# Summary
echo -e "${CYAN}📊 Validation Summary:${NC}"

total_checks=8
passed_checks=0

# Count checks
if command -v aws &> /dev/null; then ((passed_checks++)); fi
if command -v terraform &> /dev/null; then ((passed_checks++)); fi
if command -v node &> /dev/null; then ((passed_checks++)); fi
if [ -f "agent/dist/agent.zip" ]; then ((passed_checks++)); fi
if [ -f "infrastructure/main.tf" ]; then ((passed_checks++)); fi
if [ -f "agent/index.js" ]; then ((passed_checks++)); fi
if [ -f "deploy.ps1" ]; then ((passed_checks++)); fi
if [ -f "deploy.sh" ]; then ((passed_checks++)); fi

if [ $passed_checks -eq $total_checks ]; then
    echo -e "   ${GREEN}Passed: $passed_checks/$total_checks checks${NC}"
    echo ""
    echo -e "${GREEN}🎉 Setup is ready! You can now deploy with:${NC}"
    echo -e "   ${CYAN}./deploy.sh $PROJECT_NAME $ENVIRONMENT $AWS_REGION${NC}"
else
    echo -e "   ${YELLOW}Passed: $passed_checks/$total_checks checks${NC}"
    echo ""
    echo -e "${YELLOW}⚠️  Some issues found. Please fix them before deployment.${NC}"
    echo -e "   ${GRAY}Check the ❌ items above for details.${NC}"
fi

echo ""
