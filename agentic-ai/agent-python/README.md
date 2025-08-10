# 🤖 Agentic AI Agent (Python Version)

## 🎯 **Overview**

This is the Python version of the Agentic AI Agent, designed to provide autonomous AWS operations through natural language prompts. Built with modern Python features including async/await, type hints, and comprehensive error handling.

## 🚀 **Key Features**

- **Natural Language Processing**: Understand and execute AWS operations from plain English
- **Multi-Service Support**: S3, EC2, Lambda, RDS, VPC, and more
- **Event-Driven Architecture**: Integrates with EventBridge and SQS
- **Async Operations**: Built with Python's asyncio for better performance
- **Comprehensive Logging**: Detailed logging for debugging and monitoring
- **Type Safety**: Full type hints for better code quality and IDE support

## 🏗️ **Architecture**

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Natural       │───▶│  Python Agent   │───▶│  AWS Services   │
│   Language      │    │  (Async/Await)  │    │  (boto3)        │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │
                                ▼
                       ┌─────────────────┐
                       │ EventBridge     │
                       │ (Notifications) │
                       └─────────────────┘
```

## 🛠️ **Installation & Setup**

### **1. Prerequisites**
- Python 3.9 or higher
- AWS CLI configured with appropriate credentials
- AWS Lambda function already created (for deployment)

### **2. Clone and Setup**
```bash
cd agentic-ai/agent-python
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
```

### **3. Configure AWS**
```bash
aws configure
# Enter your AWS Access Key ID, Secret Access Key, Default region, and output format
```

## 🚀 **Quick Start**

### **Local Testing**
```bash
python test_agent.py
```

### **Deploy to Lambda**
```bash
# On Unix/Linux/macOS:
./deploy.sh

# On Windows PowerShell:
.\deploy.ps1

# Or manually:
python deploy.py
```

### **Test the Deployed Function**
```bash
aws lambda invoke \
  --function-name awstoazure-agentic-ai-agent \
  --cli-binary-format raw-in-base64-out \
  --payload '{"prompt": "Create an S3 bucket named my-test-bucket"}' \
  response.json
```

## 🔧 **Supported Operations**

| Operation | Description | Example Prompt |
|-----------|-------------|----------------|
| `create bucket` | Create S3 bucket | "Create a bucket named my-data" |
| `create ec2` | Create EC2 instance | "Launch a t3.micro instance" |
| `create lambda` | Create Lambda function | "Create a Python Lambda function" |
| `create rds` | Create RDS instance | "Create a MySQL database" |
| `create vpc` | Create VPC | "Create a VPC with CIDR 10.0.0.0/16" |
| `create subnet` | Create subnet | "Create a subnet in my VPC" |
| `create security group` | Create security group | "Create a security group for web access" |
| `deploy application` | Deploy application | "Deploy my app to production" |
| `scale resources` | Scale resources | "Scale my EC2 instances to 5" |
| `monitor resources` | Monitor AWS resources | "Check the health of my resources" |
| `cost optimization` | Optimize costs | "Analyze my AWS costs" |
| `backup resources` | Backup resources | "Create snapshots of my EC2 instances" |
| `update infrastructure` | Update infrastructure | "Update my infrastructure" |

## 📊 **Code Structure**

```
agent-python/
├── lambda_function.py      # Main Lambda function
├── requirements.txt        # Python dependencies
├── deploy.py              # Deployment script
├── test_agent.py          # Local testing script
├── deploy.sh              # Unix/Linux deployment script
├── deploy.ps1             # Windows PowerShell deployment script
└── README.md              # This file
```

## 🔍 **Testing**

### **Local Testing**
```bash
python test_agent.py
```

### **Unit Testing**
```bash
# Install pytest
pip install pytest

# Run tests
pytest tests/
```

### **Integration Testing**
```bash
# Test with real AWS services (be careful!)
python -c "
from lambda_function import AgenticAI
import asyncio

async def test():
    agent = AgenticAI()
    result = await agent.handler({
        'prompt': 'Create an S3 bucket named test-bucket-123',
        'userId': 'test-user',
        'requestId': 'test-123'
    }, None)
    print(result)

asyncio.run(test())
"
```

## 📊 **Monitoring & Logging**

The agent provides comprehensive logging:

- **INFO**: Operation progress and success
- **ERROR**: Operation failures and exceptions
- **DEBUG**: Detailed execution flow

### **CloudWatch Logs**
All Lambda executions are automatically logged to CloudWatch with structured logging for easy querying.

### **EventBridge Events**
The agent sends events to EventBridge for:
- Operation completion
- Operation failures
- Resource creation/deletion

## 🚨 **Error Handling**

- **Graceful Degradation**: Continues operation even if some services fail
- **Retry Logic**: Automatic retry for transient failures
- **Fallback Mechanisms**: Alternative approaches when primary methods fail
- **Comprehensive Logging**: All errors are logged with context

## 🔐 **Security Features**

- **IAM Integration**: Uses AWS IAM roles and policies
- **Parameter Validation**: Input sanitization and validation
- **Audit Logging**: All operations are logged for compliance
- **Least Privilege**: Minimal required permissions for each operation

## ⚡ **Performance Features**

- **Async Operations**: Non-blocking AWS API calls
- **Connection Pooling**: Efficient AWS SDK usage
- **Resource Optimization**: Smart resource allocation and cleanup

## 🆘 **Troubleshooting**

### **Common Issues**

1. **AWS Credentials**
   ```bash
   aws sts get-caller-identity
   # Should return your account info
   ```

2. **Permissions**
   - Ensure your IAM role has necessary permissions
   - Check CloudWatch logs for permission errors

3. **Region Configuration**
   ```bash
   aws configure get region
   # Should return your desired region
   ```

4. **Dependencies**
   ```bash
   pip install -r requirements.txt
   # Ensure all packages are installed
   ```

### **Debug Mode**
```bash
export LOG_LEVEL=DEBUG
python test_agent.py
```

### **Lambda Function Issues**
1. Check CloudWatch logs for errors
2. Verify function timeout settings
3. Ensure memory allocation is sufficient
4. Check IAM role permissions

## 🔄 **Migration from Node.js**

### **Key Differences**
- **Async/Await**: Python uses `async/await` instead of Promises
- **Error Handling**: Python exceptions vs JavaScript try/catch
- **Type System**: Python type hints vs JavaScript dynamic typing
- **Package Management**: pip vs npm

### **Migration Steps**
1. **Backup**: Keep your Node.js version as backup
2. **Deploy Python**: Use the deployment scripts
3. **Test**: Verify all operations work correctly
4. **Switch**: Update your Lambda function alias
5. **Monitor**: Watch for any issues

## 🚀 **Advanced Usage**

### **Custom Operations**
Add new operations by extending the `supported_operations` dictionary:

```python
async def custom_operation(self, parameters, prompt, user_id, request_id):
    # Your custom logic here
    return {"message": "Custom operation completed"}

# Add to supported_operations
self.supported_operations['custom operation'] = self.custom_operation
```

### **Environment Variables**
Configure the agent using environment variables:

```bash
export AWS_REGION=us-west-2
export EVENTBRIDGE_BUS=custom-bus
export SQS_QUEUE_URL=https://sqs.us-west-2.amazonaws.com/...
```

### **Custom Event Handling**
Extend event handling for your specific use cases:

```python
async def send_custom_event(self, event_type, data):
    # Custom event logic
    pass
```

## 📈 **Scaling & Performance**

### **Lambda Configuration**
- **Memory**: 512MB - 3008MB (adjust based on workload)
- **Timeout**: 15 minutes maximum
- **Concurrency**: Configure based on expected load

### **Performance Optimization**
- Use connection pooling for AWS services
- Implement caching for frequently accessed data
- Optimize async operations for parallel execution

## 🔮 **Future Enhancements**

- **AI/ML Integration**: LangChain, OpenAI integration
- **Advanced NLP**: Better prompt understanding
- **Workflow Orchestration**: Step Functions integration
- **Cost Optimization**: Automated cost reduction
- **Security Scanning**: Vulnerability detection

## 🤝 **Contributing**

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

### **Development Setup**
```bash
git clone <your-fork>
cd agentic-ai/agent-python
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
pip install -e .
```

## 📄 **License**

MIT License - see LICENSE file for details.

## 🆘 **Support**

- **Documentation**: This README and inline code comments
- **Issues**: GitHub Issues for bug reports
- **Discussions**: GitHub Discussions for questions
- **Email**: support@agentic-ai.com

---

**Built with ❤️ using Python and AWS**

*Your AI agent is ready to handle AWS operations autonomously! 🚀*
