#!/usr/bin/env python3
"""
Test script for Agentic AI Agent
"""

import json
import asyncio
from lambda_function import AgenticAI

async def test_agent():
    """Test the agent with various prompts"""
    agent = AgenticAI()
    
    test_cases = [
        {
            "prompt": "Create an S3 bucket named test-bucket-123",
            "userId": "test-user",
            "requestId": "test-123"
        },
        {
            "prompt": "Create an EC2 instance with t3.micro",
            "userId": "test-user",
            "requestId": "test-124"
        },
        {
            "prompt": "Create a VPC with CIDR 10.0.0.0/16",
            "userId": "test-user",
            "requestId": "test-125"
        }
    ]
    
    print("🤖 Testing Agentic AI Agent (Python)...\n")
    
    for i, test_case in enumerate(test_cases, 1):
        print(f"Test {i}: {test_case['prompt']}")
        print("-" * 50)
        
        try:
            result = await agent.handler(test_case, None)
            print(f"✅ Success: {result['statusCode']}")
            print(f"Operation: {result['body'].get('operation', 'N/A')}")
            print(f"Message: {result['body'].get('message', 'N/A')}")
        except Exception as e:
            print(f"❌ Error: {e}")
        
        print("\n")
    
    print("🎯 Testing completed!")

if __name__ == "__main__":
    asyncio.run(test_agent())
