# Agentic AI Usage Guide

## Overview

The Agentic AI system is designed to autonomously execute AWS operations based on natural language prompts. Instead of providing commands for you to run, it directly performs the operations on your behalf.

## Quick Start

### 1. Deploy the System

```bash
# For Linux/Mac
chmod +x deploy.sh
./deploy.sh

# For Windows
.\deploy.ps1
```

### 2. Test the System

```bash
# Test S3 bucket creation
aws lambda invoke \
  --function-name awstoazure-agentic-ai-agent \
  --payload '{"prompt": "create a bucket for me", "userId": "user123", "requestId": "req001"}' \
  --region us-east-1 \
  response.json
```

## Supported Operations

### Infrastructure Creation

#### S3 Bucket Creation
```json
{
  "prompt": "create a bucket for me",
  "userId": "user123",
  "requestId": "req001"
}
```

**Advanced S3 Creation:**
```json
{
  "prompt": "create a bucket for me",
  "parameters": {
    "bucketName": "my-custom-bucket",
    "region": "us-west-2"
  },
  "userId": "user123",
  "requestId": "req002"
}
```

#### EC2 Instance Creation
```json
{
  "prompt": "create an EC2 instance for me",
  "userId": "user123",
  "requestId": "req003"
}
```

**Advanced EC2 Creation:**
```json
{
  "prompt": "create an EC2 instance for me",
  "parameters": {
    "instanceType": "t3.medium",
    "imageId": "ami-0c02fb55956c7d316",
    "keyName": "my-key-pair"
  },
  "userId": "user123",
  "requestId": "req004"
}
```

#### Lambda Function Creation
```json
{
  "prompt": "create a lambda function",
  "userId": "user123",
  "requestId": "req005"
}
```

**Advanced Lambda Creation:**
```json
{
  "prompt": "create a lambda function",
  "parameters": {
    "functionName": "my-custom-function",
    "runtime": "python3.9",
    "handler": "index.handler"
  },
  "userId": "user123",
  "requestId": "req006"
}
```

#### RDS Instance Creation
```json
{
  "prompt": "create an RDS database",
  "userId": "user123",
  "requestId": "req007"
}
```

**Advanced RDS Creation:**
```json
{
  "prompt": "create an RDS database",
  "parameters": {
    "dbInstanceIdentifier": "my-production-db",
    "dbInstanceClass": "db.t3.small",
    "engine": "postgres",
    "masterUsername": "admin",
    "masterUserPassword": "securepassword123"
  },
  "userId": "user123",
  "requestId": "req008"
}
```

#### VPC Creation
```json
{
  "prompt": "create a VPC",
  "userId": "user123",
  "requestId": "req009"
}
```

**Advanced VPC Creation:**
```json
{
  "prompt": "create a VPC",
  "parameters": {
    "cidrBlock": "172.16.0.0/16",
    "vpcName": "my-production-vpc"
  },
  "userId": "user123",
  "requestId": "req010"
}
```

#### Subnet Creation
```json
{
  "prompt": "create a subnet",
  "parameters": {
    "vpcId": "vpc-12345678"
  },
  "userId": "user123",
  "requestId": "req011"
}
```

**Advanced Subnet Creation:**
```json
{
  "prompt": "create a subnet",
  "parameters": {
    "vpcId": "vpc-12345678",
    "cidrBlock": "172.16.1.0/24",
    "availabilityZone": "us-east-1a"
  },
  "userId": "user123",
  "requestId": "req012"
}
```

#### Security Group Creation
```json
{
  "prompt": "create a security group",
  "parameters": {
    "vpcId": "vpc-12345678"
  },
  "userId": "user123",
  "requestId": "req013"
}
```

**Advanced Security Group Creation:**
```json
{
  "prompt": "create a security group",
  "parameters": {
    "vpcId": "vpc-12345678",
    "groupName": "web-server-sg",
    "description": "Security group for web servers"
  },
  "userId": "user123",
  "requestId": "req014"
}
```

### Application Management

#### Application Deployment
```json
{
  "prompt": "deploy my application",
  "userId": "user123",
  "requestId": "req015"
}
```

#### Resource Scaling
```json
{
  "prompt": "scale my resources",
  "userId": "user123",
  "requestId": "req016"
}
```

**Advanced Scaling:**
```json
{
  "prompt": "scale my resources",
  "parameters": {
    "resourceType": "ec2",
    "action": "scale-out",
    "count": 3
  },
  "userId": "user123",
  "requestId": "req017"
}
```

### Monitoring and Optimization

#### Resource Monitoring
```json
{
  "prompt": "monitor my resources",
  "userId": "user123",
  "requestId": "req018"
}
```

**Advanced Monitoring:**
```json
{
  "prompt": "monitor my resources",
  "parameters": {
    "resourceType": "ec2"
  },
  "userId": "user123",
  "requestId": "req019"
}
```

#### Cost Optimization
```json
{
  "prompt": "optimize my costs",
  "userId": "user123",
  "requestId": "req020"
}
```

#### Resource Backup
```json
{
  "prompt": "backup my resources",
  "userId": "user123",
  "requestId": "req021"
}
```

**Advanced Backup:**
```json
{
  "prompt": "backup my resources",
  "parameters": {
    "resourceType": "ec2",
    "backupType": "snapshot"
  },
  "userId": "user123",
  "requestId": "req022"
}
```

#### Infrastructure Updates
```json
{
  "prompt": "update my infrastructure",
  "userId": "user123",
  "requestId": "req023"
}
```

**Advanced Updates:**
```json
{
  "prompt": "update my infrastructure",
  "parameters": {
    "updateType": "rolling",
    "resources": ["ec2", "rds"]
  },
  "userId": "user123",
  "requestId": "req024"
}
```

## Integration Examples

### 1. CI/CD Pipeline Integration

Add this to your GitHub Actions workflow:

```yaml
- name: Deploy with Agentic AI
  run: |
    aws lambda invoke \
      --function-name awstoazure-agentic-ai-agent \
      --payload '{"prompt": "deploy my application", "userId": "${{ github.actor }}", "requestId": "${{ github.run_id }}"}' \
      --region us-east-1 \
      response.json
```

### 2. Slack Integration

```python
import requests
import json

def deploy_with_agentic_ai(prompt, user_id):
    payload = {
        "prompt": prompt,
        "userId": user_id,
        "requestId": f"slack-{int(time.time())}"
    }
    
    response = requests.post(
        "https://your-api-gateway-url/agentic-ai",
        json=payload
    )
    
    return response.json()
```

### 3. AWS CLI Integration

```bash
# Create a function to simplify calls
function agentic-ai() {
    local prompt="$1"
    local user_id="${2:-$(whoami)}"
    local request_id="cli-$(date +%s)"
    
    aws lambda invoke \
        --function-name awstoazure-agentic-ai-agent \
        --payload "{\"prompt\": \"$prompt\", \"userId\": \"$user_id\", \"requestId\": \"$request_id\"}" \
        --region us-east-1 \
        response.json
    
    cat response.json
    rm response.json
}

# Usage
agentic-ai "create a bucket for me"
agentic-ai "scale my EC2 instances" "admin"
```

## Monitoring and Logging

### CloudWatch Logs

All operations are logged to CloudWatch with detailed information:

```bash
# View logs for the Lambda function
aws logs tail /aws/lambda/awstoazure-agentic-ai-agent --follow

# Filter logs by operation
aws logs filter-log-events \
    --log-group-name /aws/lambda/awstoazure-agentic-ai-agent \
    --filter-pattern "create bucket"
```

### EventBridge Events

Monitor operations through EventBridge:

```bash
# List events
aws events list-rules --name-prefix "agentic-ai"

# Get event details
aws events describe-rule --name "agentic-ai-operation-completed"
```

### CloudWatch Dashboard

Access the monitoring dashboard:
1. Go to AWS CloudWatch Console
2. Navigate to Dashboards
3. Find "Agentic AI Monitoring Dashboard"

## Security Features

### IAM Permissions

The system uses least-privilege IAM roles. Ensure your AWS credentials have the necessary permissions:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "lambda:InvokeFunction",
                "s3:CreateBucket",
                "s3:PutBucketTagging",
                "ec2:RunInstances",
                "ec2:CreateVpc",
                "ec2:CreateSubnet",
                "ec2:CreateSecurityGroup",
                "rds:CreateDBInstance",
                "lambda:CreateFunction",
                "cloudwatch:ListMetrics",
                "ce:GetCostAndUsage"
            ],
            "Resource": "*"
        }
    ]
}
```

### Resource Tagging

All resources created by the system are automatically tagged with:
- `CreatedBy: AgenticAI`
- `UserId: [your-user-id]`
- `RequestId: [unique-request-id]`
- `CreatedAt: [timestamp]`

## Error Handling

### Common Errors and Solutions

#### 1. Insufficient IAM Permissions
```
Error: User: arn:aws:iam::123456789012:user/username is not authorized to perform: s3:CreateBucket
```
**Solution:** Update IAM policies to include necessary permissions.

#### 2. Resource Already Exists
```
Error: The requested bucket name is not available
```
**Solution:** The system automatically generates unique names, but you can specify custom names in parameters.

#### 3. VPC Dependency Issues
```
Error: VPC ID is required to create subnet
```
**Solution:** Always provide VPC ID when creating subnets or security groups.

### Retry Logic

The system includes automatic retry logic for transient failures:
- Network timeouts: 3 retries with exponential backoff
- Rate limiting: 5 retries with increasing delays
- Service unavailability: 2 retries with 30-second intervals

## Cost Optimization

### Resource Sizing

The system automatically selects cost-effective resource types:
- EC2: t3.micro (free tier eligible)
- RDS: db.t3.micro (free tier eligible)
- Lambda: 128MB memory (minimal cost)

### Monitoring and Alerts

Set up CloudWatch alarms for cost monitoring:

```bash
# Create cost alarm
aws cloudwatch put-metric-alarm \
    --alarm-name "AgenticAI-Cost-Alert" \
    --alarm-description "Alert when costs exceed threshold" \
    --metric-name "UnblendedCost" \
    --namespace "AWS/CloudWatch" \
    --statistic "Sum" \
    --period 86400 \
    --evaluation-periods 1 \
    --threshold 100 \
    --comparison-operator "GreaterThanThreshold"
```

## Best Practices

### 1. Use Descriptive Prompts
```json
// Good
{"prompt": "create a production database with high availability"}

// Avoid
{"prompt": "make db"}
```

### 2. Include User Context
```json
{
  "prompt": "create a bucket for my web application",
  "userId": "web-team-admin",
  "requestId": "web-app-deploy-001"
}
```

### 3. Monitor Resource Usage
- Regularly check CloudWatch metrics
- Set up cost alerts
- Review resource tags for cleanup

### 4. Test in Development
- Use the test script before production deployment
- Test with minimal permissions first
- Validate resource creation in dev environment

## Troubleshooting

### Debug Mode

Enable detailed logging:

```bash
# Set log level
aws lambda update-function-configuration \
    --function-name awstoazure-agentic-ai-agent \
    --environment Variables='{"LOG_LEVEL":"DEBUG"}'
```

### Common Issues

1. **Function not responding**: Check CloudWatch logs for errors
2. **Resources not created**: Verify IAM permissions
3. **Slow response**: Check Lambda cold start and memory allocation
4. **Cost spikes**: Review resource creation patterns

## Support

For issues and questions:
1. Check CloudWatch logs first
2. Review IAM permissions
3. Test with the provided test script
4. Check AWS service status
5. Review this documentation

## Next Steps

1. **Deploy the system** using the provided scripts
2. **Test basic operations** with S3 bucket creation
3. **Integrate with your workflows** (CI/CD, Slack, etc.)
4. **Set up monitoring** and alerts
5. **Customize operations** for your specific needs
6. **Scale up** by adding more operation types

---

**Remember**: The Agentic AI system is designed to be autonomous but safe. It always tags resources and logs operations for audit purposes. Start with simple operations and gradually expand to more complex workflows.
