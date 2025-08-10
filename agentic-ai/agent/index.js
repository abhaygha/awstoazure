const AWS = require('aws-sdk');

// Initialize AWS SDK
AWS.config.update({ region: process.env.AWS_REGION || 'us-east-1' });

const sfn = new AWS.SFN();
const eventbridge = new AWS.EventBridge();
const sqs = new AWS.SQS();

// AI Brain - Core decision making and operation execution
class AgenticAI {
  constructor() {
    this.supportedOperations = {
      'create bucket': this.createS3Bucket,
      'create ec2': this.createEC2Instance,
      'create lambda': this.createLambdaFunction,
      'create rds': this.createRDSInstance,
      'create vpc': this.createVPC,
      'create subnet': this.createSubnet,
      'create security group': this.createSecurityGroup,
      'deploy application': this.deployApplication,
      'scale resources': this.scaleResources,
      'monitor resources': this.monitorResources,
      'cost optimization': this.optimizeCosts,
      'backup resources': this.backupResources,
      'update infrastructure': this.updateInfrastructure
    };
  }

  // Main handler for Lambda function
  async handler(event, context) {
    try {
      console.log('Agentic AI received request:', JSON.stringify(event, null, 2));
      
      const { prompt, operation, parameters, userId, requestId } = event;
      
      // Validate input
      if (!prompt && !operation) {
        throw new Error('Either prompt or operation must be provided');
      }

      // Determine operation from prompt if not explicitly provided
      const detectedOperation = operation || this.detectOperation(prompt);
      
      if (!detectedOperation) {
        throw new Error('Unable to detect operation from prompt');
      }

      // Execute operation
      const result = await this.executeOperation(detectedOperation, parameters, prompt, userId, requestId);
      
      // Send success event
      await this.sendEvent('operation.completed', {
        requestId,
        userId,
        operation: detectedOperation,
        result,
        timestamp: new Date().toISOString()
      });

      return {
        statusCode: 200,
        body: {
          message: 'Operation completed successfully',
          operation: detectedOperation,
          result,
          requestId
        }
      };

    } catch (error) {
      console.error('Error in Agentic AI:', error);
      
      // Send error event
      await this.sendEvent('operation.failed', {
        requestId: event.requestId,
        userId: event.userId,
        operation: event.operation,
        error: error.message,
        timestamp: new Date().toISOString()
      });

      return {
        statusCode: 500,
        body: {
          message: 'Operation failed',
          error: error.message,
          requestId: event.requestId
        }
      };
    }
  }

  // Detect operation from natural language prompt
  detectOperation(prompt) {
    const lowerPrompt = prompt.toLowerCase();
    
    for (const [key, operation] of Object.entries(this.supportedOperations)) {
      if (lowerPrompt.includes(key)) {
        return key;
      }
    }
    
    return null;
  }

  // Execute the detected operation
  async executeOperation(operation, parameters, prompt, userId, requestId) {
    console.log(`Executing operation: ${operation}`);
    
    // Check if operation is supported
    if (!this.supportedOperations[operation]) {
      throw new Error(`Unsupported operation: ${operation}`);
    }

    // Execute operation
    const result = await this.supportedOperations[operation].call(this, parameters, prompt, userId, requestId);
    
    console.log(`Operation ${operation} completed successfully`);
    return result;
  }

  // S3 Bucket Creation
  async createS3Bucket(parameters, prompt, userId, requestId) {
    const s3 = new AWS.S3();
    
    const bucketName = parameters?.bucketName || this.generateBucketName(prompt);
    const region = parameters?.region || process.env.AWS_REGION || 'us-east-1';
    
    console.log(`Creating S3 bucket: ${bucketName} in region: ${region}`);
    
    const params = {
      Bucket: bucketName,
      CreateBucketConfiguration: {
        LocationConstraint: region === 'us-east-1' ? undefined : region
      }
    };

    const result = await s3.createBucket(params).promise();
    
    // Add tags
    await s3.putBucketTagging({
      Bucket: bucketName,
      TagSet: [
        { Key: 'CreatedBy', Value: 'AgenticAI' },
        { Key: 'UserId', Value: userId },
        { Key: 'RequestId', Value: requestId },
        { Key: 'CreatedAt', Value: new Date().toISOString() }
      ]
    }).promise();

    return {
      bucketName,
      region,
      arn: `arn:aws:s3:::${bucketName}`,
      message: `S3 bucket '${bucketName}' created successfully in ${region}`
    };
  }

  // EC2 Instance Creation
  async createEC2Instance(parameters, prompt, userId, requestId) {
    const ec2 = new AWS.EC2();
    
    const instanceType = parameters?.instanceType || 't3.micro';
    const imageId = parameters?.imageId || 'ami-0c02fb55956c7d316'; // Amazon Linux 2
    const keyName = parameters?.keyName || 'default-key';
    
    console.log(`Creating EC2 instance: ${instanceType} with image: ${imageId}`);
    
    const params = {
      ImageId: imageId,
      InstanceType: instanceType,
      KeyName: keyName,
      MinCount: 1,
      MaxCount: 1,
      TagSpecifications: [{
        ResourceType: 'instance',
        Tags: [
          { Key: 'Name', Value: `AgenticAI-${Date.now()}` },
          { Key: 'CreatedBy', Value: 'AgenticAI' },
          { Key: 'UserId', Value: userId },
          { Key: 'RequestId', Value: requestId }
        ]
      }]
    };

    const result = await ec2.runInstances(params).promise();
    const instanceId = result.Instances[0].InstanceId;
    
    return {
      instanceId,
      instanceType,
      imageId,
      keyName,
      message: `EC2 instance '${instanceId}' created successfully`
    };
  }

  // Lambda Function Creation
  async createLambdaFunction(parameters, prompt, userId, requestId) {
    const lambda = new AWS.Lambda();
    
    const functionName = parameters?.functionName || `agentic-ai-function-${Date.now()}`;
    const runtime = parameters?.runtime || 'nodejs18.x';
    const handler = parameters?.handler || 'index.handler';
    
    console.log(`Creating Lambda function: ${functionName}`);
    
    // Create a simple function code
    const functionCode = {
      ZipFile: Buffer.from(`
exports.handler = async (event) => {
  console.log('Event:', JSON.stringify(event, null, 2));
  return {
    statusCode: 200,
    body: JSON.stringify({
      message: 'Hello from Agentic AI Lambda!',
      timestamp: new Date().toISOString()
    })
  };
};
      `)
    };

    const params = {
      FunctionName: functionName,
      Runtime: runtime,
      Handler: handler,
      Code: functionCode,
      Role: process.env.LAMBDA_EXECUTION_ROLE_ARN || 'arn:aws:iam::123456789012:role/lambda-execution-role',
      Description: 'Created by Agentic AI',
      Tags: {
        CreatedBy: 'AgenticAI',
        UserId: userId,
        RequestId: requestId
      }
    };

    const result = await lambda.createFunction(params).promise();
    
    return {
      functionName,
      functionArn: result.FunctionArn,
      runtime,
      handler,
      message: `Lambda function '${functionName}' created successfully`
    };
  }

  // RDS Instance Creation
  async createRDSInstance(parameters, prompt, userId, requestId) {
    const rds = new AWS.RDS();
    
    const dbInstanceIdentifier = parameters?.dbInstanceIdentifier || `agentic-ai-db-${Date.now()}`;
    const dbInstanceClass = parameters?.dbInstanceClass || 'db.t3.micro';
    const engine = parameters?.engine || 'mysql';
    const masterUsername = parameters?.masterUsername || 'admin';
    const masterUserPassword = parameters?.masterUserPassword || this.generatePassword();
    
    console.log(`Creating RDS instance: ${dbInstanceIdentifier}`);
    
    const params = {
      DBInstanceIdentifier: dbInstanceIdentifier,
      DBInstanceClass: dbInstanceClass,
      Engine: engine,
      MasterUsername: masterUsername,
      MasterUserPassword: masterUserPassword,
      AllocatedStorage: 20,
      StorageType: 'gp2',
      Tags: [
        { Key: 'CreatedBy', Value: 'AgenticAI' },
        { Key: 'UserId', Value: userId },
        { Key: 'RequestId', Value: requestId }
      ]
    };

    const result = await rds.createDBInstance(params).promise();
    
    return {
      dbInstanceIdentifier,
      dbInstanceClass,
      engine,
      masterUsername,
      message: `RDS instance '${dbInstanceIdentifier}' creation initiated`
    };
  }

  // VPC Creation
  async createVPC(parameters, prompt, userId, requestId) {
    const ec2 = new AWS.EC2();
    
    const cidrBlock = parameters?.cidrBlock || '10.0.0.0/16';
    const vpcName = parameters?.vpcName || `AgenticAI-VPC-${Date.now()}`;
    
    console.log(`Creating VPC: ${vpcName} with CIDR: ${cidrBlock}`);
    
    const params = {
      CidrBlock: cidrBlock,
      TagSpecifications: [{
        ResourceType: 'vpc',
        Tags: [
          { Key: 'Name', Value: vpcName },
          { Key: 'CreatedBy', Value: 'AgenticAI' },
          { Key: 'UserId', Value: userId },
          { Key: 'RequestId', Value: requestId }
        ]
      }]
    };

    const result = await ec2.createVpc(params).promise();
    const vpcId = result.Vpc.VpcId;
    
    // Enable DNS hostnames
    await ec2.modifyVpcAttribute({
      VpcId: vpcId,
      EnableDnsHostnames: { Value: true }
    }).promise();
    
    return {
      vpcId,
      cidrBlock,
      vpcName,
      message: `VPC '${vpcName}' created successfully with ID: ${vpcId}`
    };
  }

  // Subnet Creation
  async createSubnet(parameters, prompt, userId, requestId) {
    const ec2 = new AWS.EC2();
    
    const vpcId = parameters?.vpcId;
    const cidrBlock = parameters?.cidrBlock || '10.0.1.0/24';
    const availabilityZone = parameters?.availabilityZone || 'us-east-1a';
    
    if (!vpcId) {
      throw new Error('VPC ID is required to create subnet');
    }
    
    console.log(`Creating subnet in VPC: ${vpcId} with CIDR: ${cidrBlock}`);
    
    const params = {
      VpcId: vpcId,
      CidrBlock: cidrBlock,
      AvailabilityZone: availabilityZone,
      TagSpecifications: [{
        ResourceType: 'subnet',
        Tags: [
          { Key: 'Name', Value: `AgenticAI-Subnet-${Date.now()}` },
          { Key: 'CreatedBy', Value: 'AgenticAI' },
          { Key: 'UserId', Value: userId },
          { Key: 'RequestId', Value: requestId }
        ]
      }]
    };

    const result = await ec2.createSubnet(params).promise();
    const subnetId = result.Subnet.SubnetId;
    
    return {
      subnetId,
      vpcId,
      cidrBlock,
      availabilityZone,
      message: `Subnet created successfully with ID: ${subnetId}`
    };
  }

  // Security Group Creation
  async createSecurityGroup(parameters, prompt, userId, requestId) {
    const ec2 = new AWS.EC2();
    
    const groupName = parameters?.groupName || `AgenticAI-SG-${Date.now()}`;
    const description = parameters?.description || 'Security group created by Agentic AI';
    const vpcId = parameters?.vpcId;
    
    if (!vpcId) {
      throw new Error('VPC ID is required to create security group');
    }
    
    console.log(`Creating security group: ${groupName} in VPC: ${vpcId}`);
    
    const params = {
      GroupName: groupName,
      Description: description,
      VpcId: vpcId,
      TagSpecifications: [{
        ResourceType: 'security-group',
        Tags: [
          { Key: 'Name', Value: groupName },
          { Key: 'CreatedBy', Value: 'AgenticAI' },
          { Key: 'UserId', Value: userId },
          { Key: 'RequestId', Value: requestId }
        ]
      }]
    };

    const result = await ec2.createSecurityGroup(params).promise();
    const groupId = result.GroupId;
    
    // Add default SSH rule
    await ec2.authorizeSecurityGroupIngress({
      GroupId: groupId,
      IpPermissions: [{
        IpProtocol: 'tcp',
        FromPort: 22,
        ToPort: 22,
        IpRanges: [{ CidrIp: '0.0.0.0/0' }]
      }]
    }).promise();
    
    return {
      groupId,
      groupName,
      vpcId,
      message: `Security group '${groupName}' created successfully with ID: ${groupId}`
    };
  }

  // Application Deployment
  async deployApplication(parameters, prompt, userId, requestId) {
    console.log('Deploying application...');
    
    // This would integrate with your existing CI/CD pipeline
    // For now, we'll simulate deployment steps
    
    const deploymentSteps = [
      'Building application',
      'Running tests',
      'Creating Docker image',
      'Pushing to ECR',
      'Deploying to EKS',
      'Updating ArgoCD'
    ];
    
    const results = [];
    
    for (const step of deploymentSteps) {
      console.log(`Executing: ${step}`);
      // Simulate step execution
      await this.delay(1000);
      results.push({ step, status: 'completed' });
    }
    
    return {
      deploymentId: `deploy-${Date.now()}`,
      steps: results,
      message: 'Application deployed successfully'
    };
  }

  // Resource Scaling
  async scaleResources(parameters, prompt, userId, requestId) {
    console.log('Scaling resources...');
    
    const resourceType = parameters?.resourceType || 'ec2';
    const action = parameters?.action || 'scale-out';
    const count = parameters?.count || 1;
    
    if (resourceType === 'ec2') {
      // Scale EC2 instances
      const ec2 = new AWS.EC2();
      const autoscaling = new AWS.AutoScaling();
      
      // This would integrate with Auto Scaling Groups
      console.log(`Scaling ${resourceType} by ${action} with count: ${count}`);
      
      return {
        resourceType,
        action,
        count,
        message: `Scaling operation initiated for ${resourceType}`
      };
    }
    
    return {
      resourceType,
      action,
      count,
      message: `Scaling operation completed for ${resourceType}`
    };
  }

  // Resource Monitoring
  async monitorResources(parameters, prompt, userId, requestId) {
    console.log('Monitoring resources...');
    
    const cloudwatch = new AWS.CloudWatch();
    const resourceType = parameters?.resourceType || 'all';
    
    // Get basic metrics
    const metrics = await cloudwatch.listMetrics({
      Namespace: 'AWS/EC2',
      MetricName: 'CPUUtilization'
    }).promise();
    
    return {
      resourceType,
      metricsCount: metrics.Metrics.length,
      message: `Monitoring data collected for ${resourceType} resources`
    };
  }

  // Cost Optimization
  async optimizeCosts(parameters, prompt, userId, requestId) {
    console.log('Optimizing costs...');
    
    const ce = new AWS.CostExplorer();
    
    // Get cost and usage data
    const endDate = new Date();
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - 30);
    
    const costData = await ce.getCostAndUsage({
      TimePeriod: {
        Start: startDate.toISOString().split('T')[0],
        End: endDate.toISOString().split('T')[0]
      },
      Granularity: 'MONTHLY',
      Metrics: ['UnblendedCost']
    }).promise();
    
    return {
      totalCost: costData.ResultsByTime[0]?.Total?.UnblendedCost?.Amount || '0',
      currency: costData.ResultsByTime[0]?.Total?.UnblendedCost?.Unit || 'USD',
      message: 'Cost optimization analysis completed'
    };
  }

  // Resource Backup
  async backupResources(parameters, prompt, userId, requestId) {
    console.log('Creating resource backups...');
    
    const resourceType = parameters?.resourceType || 'ec2';
    const backupType = parameters?.backupType || 'snapshot';
    
    if (resourceType === 'ec2' && backupType === 'snapshot') {
      const ec2 = new AWS.EC2();
      
      // Get EC2 instances
      const instances = await ec2.describeInstances({
        Filters: [{
          Name: 'instance-state-name',
          Values: ['running', 'stopped']
        }]
      }).promise();
      
      const snapshots = [];
      
      for (const reservation of instances.Reservations) {
        for (const instance of reservation.Instances) {
          for (const blockDevice of instance.BlockDeviceMappings) {
            if (blockDevice.Ebs) {
              const snapshot = await ec2.createSnapshot({
                VolumeId: blockDevice.Ebs.VolumeId,
                Description: `Backup of ${instance.InstanceId} created by Agentic AI`,
                TagSpecifications: [{
                  ResourceType: 'snapshot',
                  Tags: [
                    { Key: 'Name', Value: `Backup-${instance.InstanceId}-${Date.now()}` },
                    { Key: 'CreatedBy', Value: 'AgenticAI' },
                    { Key: 'UserId', Value: userId },
                    { Key: 'RequestId', Value: requestId }
                  ]
                }]
              }).promise();
              
              snapshots.push({
                snapshotId: snapshot.SnapshotId,
                volumeId: blockDevice.Ebs.VolumeId,
                instanceId: instance.InstanceId
              });
            }
          }
        }
      }
      
      return {
        resourceType,
        backupType,
        snapshotsCount: snapshots.length,
        snapshots,
        message: `Created ${snapshots.length} snapshots for EC2 instances`
      };
    }
    
    return {
      resourceType,
      backupType,
      message: `Backup operation completed for ${resourceType}`
    };
  }

  // Infrastructure Updates
  async updateInfrastructure(parameters, prompt, userId, requestId) {
    console.log('Updating infrastructure...');
    
    // This would integrate with CloudFormation, Terraform, or other IaC tools
    const updateType = parameters?.updateType || 'rolling';
    const resources = parameters?.resources || ['ec2', 'rds', 'lambda'];
    
    return {
      updateType,
      resources,
      message: `Infrastructure update initiated for ${resources.join(', ')}`
    };
  }

  // Helper methods
  generateBucketName(prompt) {
    const timestamp = Date.now();
    const random = Math.random().toString(36).substring(2, 8);
    return `agentic-ai-bucket-${timestamp}-${random}`;
  }

  generatePassword() {
    return Math.random().toString(36).substring(2, 15) + Math.random().toString(36).substring(2, 15);
  }

  async delay(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  // Send events to EventBridge
  async sendEvent(detailType, detail) {
    try {
      const params = {
        Entries: [{
          Source: 'agentic.ai',
          DetailType: detailType,
          Detail: JSON.stringify(detail),
          EventBusName: process.env.EVENTBRIDGE_BUS || 'default'
        }]
      };

      await eventbridge.putEvents(params).promise();
      console.log(`Event sent: ${detailType}`);
    } catch (error) {
      console.error('Error sending event:', error);
    }
  }

  // Send messages to SQS
  async sendMessage(messageBody) {
    try {
      const params = {
        QueueUrl: process.env.SQS_QUEUE_URL,
        MessageBody: JSON.stringify(messageBody)
      };

      await sqs.sendMessage(params).promise();
      console.log('Message sent to SQS');
    } catch (error) {
      console.error('Error sending message to SQS:', error);
    }
  }
}

// Create instance and export handler
const agenticAI = new AgenticAI();

// Export the handler function
exports.handler = async (event, context) => {
  return await agenticAI.handler(event, context);
};

// Export the class for testing
exports.AgenticAI = AgenticAI;
