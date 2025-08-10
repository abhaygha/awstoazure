# 🚨 Agentic AI Troubleshooting Guide

## Common Issues and Solutions

### 1. 🔍 **Validation Issues**

#### **Run the validation script first:**
```powershell
.\validate-setup.ps1
```

This will identify exactly what's wrong with your setup.

### 2. 🚫 **"Red Flags" - What They Mean**

#### **Terraform Provider Errors**
- **Error**: `Missing required provider`
- **Cause**: Terraform hasn't been initialized
- **Solution**: Run `terraform init` in the infrastructure folder

#### **Missing Build Files**
- **Error**: `Lambda package: Not built yet`
- **Cause**: The agent hasn't been built
- **Solution**: Run `cd agent-python && python deploy.py`

#### **Permission Issues**
- **Error**: `Access denied` or `Permission denied`
- **Cause**: Scripts not executable or insufficient permissions
- **Solution**: Use PowerShell for Windows, ensure AWS credentials are configured

### 3. 🛠 **Step-by-Step Fix Process**

#### **Step 1: Check Prerequisites**
```powershell
# Check if tools are installed
aws --version
terraform --version
python3 --version 2>/dev/null || python --version
```

#### **Step 2: Fix Missing Tools**
- **AWS CLI**: Download from https://aws.amazon.com/cli/
- **Terraform**: Download from https://www.terraform.io/downloads
- **Python**: Download from https://python.org/downloads/

#### **Step 3: Configure AWS**
```powershell
aws configure
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Enter your default region (e.g., us-east-1)
# Enter your output format (json)
```

#### **Step 4: Build the Agent**
```powershell
cd agent-python
pip install -r requirements.txt
python deploy.py
cd ..
```

#### **Step 5: Initialize Terraform**
```powershell
cd infrastructure
terraform init
cd ..
```

### 4. 🚨 **Specific Error Messages**

#### **"No such file or directory"**
- **Cause**: File paths are incorrect
- **Solution**: Ensure you're in the right directory (`agentic-ai` folder)

#### **"Command not found"**
- **Cause**: Tool not installed or not in PATH
- **Solution**: Install the missing tool or add to PATH

#### **"Access denied"**
- **Cause**: Insufficient permissions
- **Solution**: Run as administrator or check file permissions

#### **"Invalid credentials"**
- **Cause**: AWS credentials not configured or expired
- **Solution**: Run `aws configure` or check IAM permissions

### 5. 🔧 **Quick Fix Commands**

#### **Reset Everything:**
```powershell
# Clean build artifacts
Remove-Item -Recurse -Force agent-python/agent.zip -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force agent-python/__pycache__ -ErrorAction SilentlyContinue

# Rebuild
cd agent-python
pip install -r requirements.txt
python deploy.py
cd ..

# Reinitialize Terraform
cd infrastructure
terraform init
cd ..
```

#### **Test Individual Components:**
```powershell
# Test AWS
aws sts get-caller-identity

# Test Terraform
terraform version

# Test Python
python3 --version 2>/dev/null || python --version

# Test build
cd agent-python && python deploy.py && cd ..
```

### 6. 📞 **When to Get Help**

#### **Contact Support If:**
- Validation script shows 0/8 checks passed
- You get cryptic error messages
- Terraform fails with provider issues
- AWS operations fail with permission errors

#### **Before Contacting Support:**
1. Run `.\validate-setup.ps1`
2. Note the exact error messages
3. Check if you're in the right directory
4. Verify AWS credentials are working

### 7. 🎯 **Success Indicators**

#### **You're Ready When:**
- ✅ All 8 validation checks pass
- ✅ AWS credentials are configured
- ✅ Lambda package is built (`agent-python/agent.zip` exists)
- ✅ Terraform can initialize
- ✅ No red error messages

#### **Next Step:**
```powershell
.\deploy.ps1
```

## 🆘 **Still Having Issues?**

1. **Run the validation script**: `.\validate-setup.ps1`
2. **Check this troubleshooting guide**
3. **Look at the specific error message**
4. **Ensure you're in the `agentic-ai` directory**
5. **Verify all prerequisites are installed**

Remember: Most "red flags" are just missing setup steps, not actual problems! 🚀
