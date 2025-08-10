#!/usr/bin/env python3
"""
Test script to invoke the Agentic AI Lambda function
"""

import json
import boto3
import uuid
from datetime import datetime

def invoke_agentic_ai(prompt, parameters=None, user_id="test-user"):
    """
    Invoke the Agentic AI Lambda function
    
    Args:
        prompt (str): Natural language request
        parameters (dict): Optional specific parameters
        user_id (str): User identifier
    
    Returns:
        dict: Lambda response
    """
    
    # Create Lambda client
    lambda_client = boto3.client('lambda', region_name='us-east-1')
    
    # Prepare payload
    payload = {
        "prompt": prompt,
        "userId": user_id,
        "requestId": f"req-{uuid.uuid4().hex[:8]}",
        "timestamp": datetime.now().isoformat()
    }
    
    if parameters:
        payload["parameters"] = parameters
    
    print(f"🎯 Invoking Agentic AI with payload:")
    print(json.dumps(payload, indent=2))
    print()
    
    try:
        # Invoke Lambda function
        response = lambda_client.invoke(
            FunctionName='agentic-ai-agent',
            InvocationType='RequestResponse',
            Payload=json.dumps(payload)
        )
        
        # Parse response
        response_payload = json.loads(response['Payload'].read())
        
        print(f"✅ Response received:")
        print(json.dumps(response_payload, indent=2))
        
        return response_payload
        
    except Exception as e:
        print(f"❌ Error invoking Lambda: {e}")
        return None

def main():
    """Test different scenarios"""
    
    print("🚀 Agentic AI Test Suite")
    print("=" * 50)
    
    # Test 1: Simple S3 bucket creation
    print("\n📦 Test 1: Create S3 bucket with prompt only")
    invoke_agentic_ai("Create an S3 bucket")
    
    # Test 2: S3 bucket with specific parameters
    print("\n📦 Test 2: Create S3 bucket with specific parameters")
    invoke_agentic_ai(
        "Create an S3 bucket",
        parameters={
            "bucketName": "my-test-bucket-123",
            "region": "us-east-1"
        }
    )
    
    # Test 3: EC2 instance creation
    print("\n🖥️ Test 3: Create EC2 instance")
    invoke_agentic_ai(
        "Create an EC2 instance",
        parameters={
            "instanceType": "t3.micro",
            "imageId": "ami-0c02fb55956c7d316"
        }
    )
    
    # Test 4: VPC creation
    print("\n🌐 Test 4: Create VPC")
    invoke_agentic_ai(
        "Create a VPC",
        parameters={
            "cidrBlock": "10.0.0.0/16",
            "region": "us-east-1"
        }
    )

if __name__ == "__main__":
    main()
