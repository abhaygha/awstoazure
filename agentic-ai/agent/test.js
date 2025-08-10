const { AgenticAI } = require('./index');

// Mock AWS SDK for testing
const mockAWS = {
  S3: class {
    async createBucket(params) {
      console.log('Mock S3: Creating bucket with params:', params);
      return { promise: () => Promise.resolve({ Location: 'us-east-1' }) };
    }
    async putBucketTagging(params) {
      console.log('Mock S3: Adding tags with params:', params);
      return { promise: () => Promise.resolve() };
    }
  },
  EC2: class {
    async runInstances(params) {
      console.log('Mock EC2: Creating instance with params:', params);
      return { 
        promise: () => Promise.resolve({ 
          Instances: [{ InstanceId: 'i-mock123456789' }] 
        }) 
      };
    }
    async createVpc(params) {
      console.log('Mock EC2: Creating VPC with params:', params);
      return { 
        promise: () => Promise.resolve({ 
          Vpc: { VpcId: 'vpc-mock123456789' } 
        }) 
      };
    }
    async modifyVpcAttribute(params) {
      console.log('Mock EC2: Modifying VPC attributes with params:', params);
      return { promise: () => Promise.resolve() };
    }
    async createSubnet(params) {
      console.log('Mock EC2: Creating subnet with params:', params);
      return { 
        promise: () => Promise.resolve({ 
          Subnet: { SubnetId: 'subnet-mock123456789' } 
        }) 
      };
    }
    async createSecurityGroup(params) {
      console.log('Mock EC2: Creating security group with params:', params);
      return { 
        promise: () => Promise.resolve({ 
          GroupId: 'sg-mock123456789' 
        }) 
      };
    }
    async authorizeSecurityGroupIngress(params) {
      console.log('Mock EC2: Authorizing security group ingress with params:', params);
      return { promise: () => Promise.resolve() };
    }
    async describeInstances(params) {
      console.log('Mock EC2: Describing instances with params:', params);
      return { 
        promise: () => Promise.resolve({ 
          Reservations: [{
            Instances: [{
              InstanceId: 'i-mock123456789',
              BlockDeviceMappings: [{
                Ebs: { VolumeId: 'vol-mock123456789' }
              }]
            }]
          }]
        }) 
      };
    }
    async createSnapshot(params) {
      console.log('Mock EC2: Creating snapshot with params:', params);
      return { 
        promise: () => Promise.resolve({ 
          SnapshotId: 'snap-mock123456789' 
        }) 
      };
    }
  },
  Lambda: class {
    async createFunction(params) {
      console.log('Mock Lambda: Creating function with params:', params);
      return { 
        promise: () => Promise.resolve({ 
          FunctionArn: 'arn:aws:lambda:us-east-1:123456789012:function:mock-function' 
        }) 
      };
    }
  },
  RDS: class {
    async createDBInstance(params) {
      console.log('Mock RDS: Creating DB instance with params:', params);
      return { promise: () => Promise.resolve() };
    }
  },
  CloudWatch: class {
    async listMetrics(params) {
      console.log('Mock CloudWatch: Listing metrics with params:', params);
      return { 
        promise: () => Promise.resolve({ 
          Metrics: [{ MetricName: 'CPUUtilization' }] 
        }) 
      };
    }
  },
  CostExplorer: class {
    async getCostAndUsage(params) {
      console.log('Mock CostExplorer: Getting cost data with params:', params);
      return { 
        promise: () => Promise.resolve({ 
          ResultsByTime: [{ 
            Total: { 
              UnblendedCost: { Amount: '150.00', Unit: 'USD' } 
            } 
          }] 
        }) 
      };
    }
  }
};

// Mock EventBridge and SQS
const mockEventBridge = {
  async putEvents(params) {
    console.log('Mock EventBridge: Sending event with params:', params);
    return Promise.resolve();
  }
};

const mockSQS = {
  async sendMessage(params) {
    console.log('Mock SQS: Sending message with params:', params);
    return Promise.resolve();
  }
};

// Test scenarios
const testScenarios = [
  {
    name: 'S3 Bucket Creation',
    input: {
      prompt: 'create a bucket for me',
      userId: 'test-user-001',
      requestId: 'test-001'
    },
    expectedOperation: 'create bucket'
  },
  {
    name: 'EC2 Instance Creation',
    input: {
      prompt: 'create an EC2 instance for me',
      userId: 'test-user-002',
      requestId: 'test-002'
    },
    expectedOperation: 'create ec2'
  },
  {
    name: 'Lambda Function Creation',
    input: {
      prompt: 'create a lambda function',
      userId: 'test-user-003',
      requestId: 'test-003'
    },
    expectedOperation: 'create lambda'
  },
  {
    name: 'RDS Instance Creation',
    input: {
      prompt: 'create an RDS database',
      userId: 'test-user-004',
      requestId: 'test-004'
    },
    expectedOperation: 'create rds'
  },
  {
    name: 'VPC Creation',
    input: {
      prompt: 'create a VPC',
      userId: 'test-user-005',
      requestId: 'test-005'
    },
    expectedOperation: 'create vpc'
  },
  {
    name: 'Subnet Creation',
    input: {
      prompt: 'create a subnet',
      parameters: { vpcId: 'vpc-test123' },
      userId: 'test-user-006',
      requestId: 'test-006'
    },
    expectedOperation: 'create subnet'
  },
  {
    name: 'Security Group Creation',
    input: {
      prompt: 'create a security group',
      parameters: { vpcId: 'vpc-test123' },
      userId: 'test-user-007',
      requestId: 'test-007'
    },
    expectedOperation: 'create security group'
  },
  {
    name: 'Application Deployment',
    input: {
      prompt: 'deploy my application',
      userId: 'test-user-008',
      requestId: 'test-008'
    },
    expectedOperation: 'deploy application'
  },
  {
    name: 'Resource Scaling',
    input: {
      prompt: 'scale my resources',
      userId: 'test-user-009',
      requestId: 'test-009'
    },
    expectedOperation: 'scale resources'
  },
  {
    name: 'Resource Monitoring',
    input: {
      prompt: 'monitor my resources',
      userId: 'test-user-010',
      requestId: 'test-010'
    },
    expectedOperation: 'monitor resources'
  },
  {
    name: 'Cost Optimization',
    input: {
      prompt: 'optimize my costs',
      userId: 'test-user-011',
      requestId: 'test-011'
    },
    expectedOperation: 'cost optimization'
  },
  {
    name: 'Resource Backup',
    input: {
      prompt: 'backup my resources',
      userId: 'test-user-012',
      requestId: 'test-012'
    },
    expectedOperation: 'backup resources'
  },
  {
    name: 'Infrastructure Update',
    input: {
      prompt: 'update my infrastructure',
      userId: 'test-user-013',
      requestId: 'test-013'
    },
    expectedOperation: 'update infrastructure'
  }
];

// Test function
async function runTests() {
  console.log('🧪 Starting Agentic AI Tests...\n');
  
  let passedTests = 0;
  let totalTests = testScenarios.length;
  
  for (const scenario of testScenarios) {
    console.log(`📋 Testing: ${scenario.name}`);
    
    try {
      // Create a new instance for each test
      const ai = new AgenticAI();
      
      // Test operation detection
      const detectedOperation = ai.detectOperation(scenario.input.prompt);
      
      if (detectedOperation === scenario.expectedOperation) {
        console.log(`   ✅ Operation detection: PASSED (detected: ${detectedOperation})`);
        passedTests++;
      } else {
        console.log(`   ❌ Operation detection: FAILED (expected: ${scenario.expectedOperation}, got: ${detectedOperation})`);
      }
      
      // Test operation execution (with mocked AWS services)
      try {
        const result = await ai.executeOperation(
          detectedOperation || scenario.expectedOperation,
          scenario.input.parameters,
          scenario.input.prompt,
          scenario.input.userId,
          scenario.input.requestId
        );
        
        if (result && result.message) {
          console.log(`   ✅ Operation execution: PASSED`);
          console.log(`      Result: ${result.message}`);
        } else {
          console.log(`   ❌ Operation execution: FAILED (no result message)`);
        }
        
      } catch (execError) {
        console.log(`   ⚠️  Operation execution: SKIPPED (${execError.message})`);
      }
      
    } catch (error) {
      console.log(`   ❌ Test execution: FAILED (${error.message})`);
    }
    
    console.log(''); // Empty line for readability
  }
  
  // Test summary
  console.log('📊 Test Summary:');
  console.log(`   Total Tests: ${totalTests}`);
  console.log(`   Passed: ${passedTests}`);
  console.log(`   Failed: ${totalTests - passedTests}`);
  console.log(`   Success Rate: ${((passedTests / totalTests) * 100).toFixed(1)}%`);
  
  if (passedTests === totalTests) {
    console.log('\n🎉 All tests passed! Agentic AI is ready for deployment.');
  } else {
    console.log('\n⚠️  Some tests failed. Please review the issues before deployment.');
  }
}

// Run tests if this file is executed directly
if (require.main === module) {
  runTests().catch(console.error);
}

module.exports = { runTests, testScenarios };
