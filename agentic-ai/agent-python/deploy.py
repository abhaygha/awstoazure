#!/usr/bin/env python3
"""
Deployment script for Agentic AI Lambda function
"""

import os
import sys
import zipfile
import shutil
import boto3
from pathlib import Path

def create_deployment_package():
    """Create deployment package"""
    print("Creating deployment package...")
    
    # Create dist directory
    dist_dir = Path("dist")
    if dist_dir.exists():
        shutil.rmtree(dist_dir)
    dist_dir.mkdir()
    
    # Create zip file
    zip_path = dist_dir / "agent.zip"
    
    with zipfile.ZipFile(zip_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
        # Add main files
        zipf.write("lambda_function.py", "lambda_function.py")
        zipf.write("requirements.txt", "requirements.txt")
        
        # Add dependencies
        if os.path.exists("venv"):
            site_packages = Path("venv") / "Lib" / "site-packages"
            if site_packages.exists():
                for root, dirs, files in os.walk(site_packages):
                    for file in files:
                        file_path = Path(root) / file
                        arc_name = file_path.relative_to(site_packages)
                        zipf.write(file_path, arc_name)
    
    print(f"Deployment package created: {zip_path}")
    return zip_path

def deploy_to_lambda(zip_path, function_name="awstoazure-agentic-ai-agent"):
    """Deploy to AWS Lambda"""
    print(f"Deploying to Lambda function: {function_name}")
    
    try:
        lambda_client = boto3.client('lambda')
        
        # Update function code
        with open(zip_path, 'rb') as zip_file:
            response = lambda_client.update_function_code(
                FunctionName=function_name,
                ZipFile=zip_file.read()
            )
        
        print(f"Successfully deployed to {function_name}")
        print(f"Function ARN: {response['FunctionArn']}")
        
    except Exception as e:
        print(f"Error deploying to Lambda: {e}")
        sys.exit(1)

def main():
    """Main deployment function"""
    print("🚀 Deploying Agentic AI Agent (Python)...")
    
    # Check if AWS credentials are configured
    try:
        boto3.client('sts').get_caller_identity()
    except Exception:
        print("❌ AWS credentials not configured. Please run 'aws configure' first.")
        sys.exit(1)
    
    # Create deployment package
    zip_path = create_deployment_package()
    
    # Deploy to Lambda
    deploy_to_lambda(zip_path)
    
    print("✅ Deployment completed successfully!")

if __name__ == "__main__":
    main()
