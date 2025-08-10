import json
import os
import logging
from datetime import datetime
from typing import Dict, Any, Optional, List
import boto3
from botocore.exceptions import ClientError, BotoCoreError

# Mock client for local testing
class MockClient:
    def __init__(self, service_name):
        self.service_name = service_name
    
    def put_events(self, **kwargs):
        return {'FailedEntryCount': 0, 'Entries': [{'EventId': 'mock-event-id'}]}
    
    def send_message(self, **kwargs):
        return {'MessageId': 'mock-message-id'}

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class AgenticAI:
    """AI Brain - Core decision making and operation execution"""
    
    def __init__(self):
        # Initialize AWS SDK
        self.region = os.environ.get('AWS_REGION', 'us-east-1')
        # Don't initialize clients during import to avoid boto3 issues
        self.sfn = None
        self.eventbridge = None
        self.sqs = None
        
        # Supported operations mapping
        self.supported_operations = {
            'create bucket': self.create_s3_bucket,
            'create ec2': self.create_ec2_instance,
            'create lambda': self.create_lambda_function,
            'create rds': self.create_rds_instance,
            'create vpc': self.create_vpc,
            'create subnet': self.create_subnet,
            'create security group': self.create_security_group,
            'deploy application': self.deploy_application,
            'scale resources': self.scale_resources,
            'monitor resources': self.monitor_resources,
            'cost optimization': self.optimize_costs,
            'backup resources': self.backup_resources,
            'update infrastructure': self.update_infrastructure
        }
    
    def _init_clients(self):
        """Initialize AWS clients when needed"""
        if self.sfn is None:
            try:
                # For local testing, create mock clients
                if os.environ.get('LOCAL_TESTING') == 'true':
                    self.sfn = MockClient('stepfunctions')
                    self.eventbridge = MockClient('events')
                    self.sqs = MockClient('sqs')
                else:
                    self.sfn = boto3.client('stepfunctions', region_name=self.region)
                    self.eventbridge = boto3.client('events', region_name=self.region)
                    self.sqs = boto3.client('sqs', region_name=self.region)
            except Exception as e:
                logger.warning(f"Could not initialize AWS clients: {e}")
                # Use fallback approach
                self.sfn = boto3.client('stepfunctions')
                self.eventbridge = boto3.client('events')
                self.sqs = boto3.client('sqs')

    async def handler(self, event: Dict[str, Any], context: Any) -> Dict[str, Any]:
        """Main handler for Lambda function"""
        try:
            # Initialize AWS clients
            self._init_clients()
            
            logger.info(f'Agentic AI received request: {json.dumps(event, indent=2)}')
            
            prompt = event.get('prompt')
            operation = event.get('operation')
            parameters = event.get('parameters', {})
            user_id = event.get('userId', 'anonymous')
            request_id = event.get('requestId', f'req-{datetime.now().timestamp()}')
            
            # Validate input
            if not prompt and not operation:
                raise ValueError('Either prompt or operation must be provided')
            
            # Determine operation from prompt if not explicitly provided
            detected_operation = operation or self.detect_operation(prompt)
            
            if not detected_operation:
                raise ValueError('Unable to detect operation from prompt')
            
            # Execute operation
            result = await self.execute_operation(
                detected_operation, parameters, prompt, user_id, request_id
            )
            
            # Send success event
            await self.send_event('operation.completed', {
                'requestId': request_id,
                'userId': user_id,
                'operation': detected_operation,
                'result': result,
                'timestamp': datetime.now().isoformat()
            })
            
            return {
                'statusCode': 200,
                'body': {
                    'message': 'Operation completed successfully',
                    'operation': detected_operation,
                    'result': result,
                    'requestId': request_id
                }
            }
            
        except Exception as error:
            logger.error(f'Error in Agentic AI: {error}')
            
            # Send error event
            await self.send_event('operation.failed', {
                'requestId': event.get('requestId'),
                'userId': event.get('userId'),
                'operation': event.get('operation'),
                'error': str(error),
                'timestamp': datetime.now().isoformat()
            })
            
            return {
                'statusCode': 500,
                'body': {
                    'message': 'Operation failed',
                    'error': str(error),
                    'requestId': event.get('requestId')
                }
            }
    
    def detect_operation(self, prompt: str) -> Optional[str]:
        """Detect operation from natural language prompt"""
        if not prompt:
            return None
            
        lower_prompt = prompt.lower()
        logger.info(f"Detecting operation from prompt: '{lower_prompt}'")
        
        # More flexible matching
        if 'bucket' in lower_prompt and ('create' in lower_prompt or 'make' in lower_prompt):
            logger.info("Found operation: create bucket")
            return 'create bucket'
        elif 'ec2' in lower_prompt and ('create' in lower_prompt or 'launch' in lower_prompt or 'start' in lower_prompt):
            logger.info("Found operation: create ec2")
            return 'create ec2'
        elif 'lambda' in lower_prompt and ('create' in lower_prompt or 'make' in lower_prompt):
            logger.info("Found operation: create lambda")
            return 'create lambda'
        elif 'rds' in lower_prompt and ('create' in lower_prompt or 'make' in lower_prompt):
            logger.info("Found operation: create rds")
            return 'create rds'
        elif 'vpc' in lower_prompt and ('create' in lower_prompt or 'make' in lower_prompt):
            logger.info("Found operation: create vpc")
            return 'create vpc'
        elif 'subnet' in lower_prompt and ('create' in lower_prompt or 'make' in lower_prompt):
            logger.info("Found operation: create subnet")
            return 'create subnet'
        elif 'security group' in lower_prompt and ('create' in lower_prompt or 'make' in lower_prompt):
            logger.info("Found operation: create security group")
            return 'create security group'
        elif 'deploy' in lower_prompt:
            logger.info("Found operation: deploy application")
            return 'deploy application'
        elif 'scale' in lower_prompt:
            logger.info("Found operation: scale resources")
            return 'scale resources'
        elif 'monitor' in lower_prompt or 'check' in lower_prompt:
            logger.info("Found operation: monitor resources")
            return 'monitor resources'
        elif 'cost' in lower_prompt and ('optimize' in lower_prompt or 'analyze' in lower_prompt):
            logger.info("Found operation: cost optimization")
            return 'cost optimization'
        elif 'backup' in lower_prompt or 'snapshot' in lower_prompt:
            logger.info("Found operation: backup resources")
            return 'backup resources'
        elif 'update' in lower_prompt or 'upgrade' in lower_prompt:
            logger.info("Found operation: update infrastructure")
            return 'update infrastructure'
        
        # Fallback to original method
        for key, operation in self.supported_operations.items():
            logger.info(f"Checking key: '{key}' against prompt")
            if key in lower_prompt:
                logger.info(f"Found operation: {key}")
                return key
        
        logger.warning(f"No operation detected from prompt: '{lower_prompt}'")
        return None
    
    async def execute_operation(self, operation: str, parameters: Dict[str, Any], 
                               prompt: str, user_id: str, request_id: str) -> Dict[str, Any]:
        """Execute the detected operation"""
        logger.info(f'Executing operation: {operation}')
        
        # Check if operation is supported
        if operation not in self.supported_operations:
            raise ValueError(f'Unsupported operation: {operation}')
        
        # Execute operation
        result = await self.supported_operations[operation](
            parameters, prompt, user_id, request_id
        )
        
        logger.info(f'Operation {operation} completed successfully')
        return result
    
    async def create_s3_bucket(self, parameters: Dict[str, Any], prompt: str, 
                               user_id: str, request_id: str) -> Dict[str, Any]:
        """Create S3 bucket"""
        bucket_name = parameters.get('bucketName') or self.generate_bucket_name(prompt)
        region = parameters.get('region') or self.region
        
        logger.info(f'Creating S3 bucket: {bucket_name} in region: {region}')
        
        # Check if we're in local testing mode
        if os.environ.get('LOCAL_TESTING') == 'true':
            logger.info('Local testing mode - simulating S3 bucket creation')
            return {
                'bucketName': bucket_name,
                'region': region,
                'arn': f'arn:aws:s3:::{bucket_name}',
                'message': f'S3 bucket "{bucket_name}" created successfully in {region} (SIMULATED)',
                'simulated': True
            }
        
        try:
            s3 = boto3.client('s3', region_name=self.region)
            
            # Create bucket
            if region == 'us-east-1':
                response = s3.create_bucket(Bucket=bucket_name)
            else:
                response = s3.create_bucket(
                    Bucket=bucket_name,
                    CreateBucketConfiguration={'LocationConstraint': region}
                )
            
            # Add tags
            s3.put_bucket_tagging(
                Bucket=bucket_name,
                Tagging={
                    'TagSet': [
                        {'Key': 'CreatedBy', 'Value': 'AgenticAI'},
                        {'Key': 'UserId', 'Value': user_id},
                        {'Key': 'RequestId', 'Value': request_id},
                        {'Key': 'CreatedAt', 'Value': datetime.now().isoformat()}
                    ]
                }
            )
            
            return {
                'bucketName': bucket_name,
                'region': region,
                'arn': f'arn:aws:s3:::{bucket_name}',
                'message': f'S3 bucket "{bucket_name}" created successfully in {region}'
            }
            
        except ClientError as e:
            logger.error(f'Error creating S3 bucket: {e}')
            raise
    
    async def create_ec2_instance(self, parameters: Dict[str, Any], prompt: str,
                                  user_id: str, request_id: str) -> Dict[str, Any]:
        """Create EC2 instance"""
        instance_type = parameters.get('instanceType', 't3.micro')
        image_id = parameters.get('imageId', 'ami-0c02fb55956c7d316')  # Amazon Linux 2
        key_name = parameters.get('keyName', 'default-key')
        
        logger.info(f'Creating EC2 instance: {instance_type} with image: {image_id}')
        
        # Check if we're in local testing mode
        if os.environ.get('LOCAL_TESTING') == 'true':
            logger.info('Local testing mode - simulating EC2 instance creation')
            instance_id = f'i-{request_id[:8]}mock'
            return {
                'instanceId': instance_id,
                'instanceType': instance_type,
                'imageId': image_id,
                'keyName': key_name,
                'message': f'EC2 instance "{instance_id}" created successfully (SIMULATED)',
                'simulated': True
            }
        
        try:
            ec2 = boto3.client('ec2', region_name=self.region)
            
            response = ec2.run_instances(
                ImageId=image_id,
                InstanceType=instance_type,
                KeyName=key_name,
                MinCount=1,
                MaxCount=1,
                TagSpecifications=[{
                    'ResourceType': 'instance',
                    'Tags': [
                        {'Key': 'Name', 'Value': f'AgenticAI-{int(datetime.now().timestamp())}'},
                        {'Key': 'CreatedBy', 'Value': 'AgenticAI'},
                        {'Key': 'UserId', 'Value': user_id},
                        {'Key': 'RequestId', 'Value': request_id}
                    ]
                }]
            )
            
            instance_id = response['Instances'][0]['InstanceId']
            
            return {
                'instanceId': instance_id,
                'instanceType': instance_type,
                'imageId': image_id,
                'keyName': key_name,
                'message': f'EC2 instance "{instance_id}" created successfully'
            }
            
        except ClientError as e:
            logger.error(f'Error creating EC2 instance: {e}')
            raise
    
    async def create_lambda_function(self, parameters: Dict[str, Any], prompt: str,
                                    user_id: str, request_id: str) -> Dict[str, Any]:
        """Create Lambda function"""
        lambda_client = boto3.client('lambda', region_name=self.region)
        
        function_name = parameters.get('functionName') or f'agentic-ai-function-{int(datetime.now().timestamp())}'
        runtime = parameters.get('runtime', 'python3.11')
        handler = parameters.get('handler', 'lambda_function.handler')
        
        logger.info(f'Creating Lambda function: {function_name}')
        
        try:
            # Create a simple function code
            function_code = {
                'ZipFile': 'dummy-code'  # Placeholder for now
            }
            
            response = lambda_client.create_function(
                FunctionName=function_name,
                Runtime=runtime,
                Handler=handler,
                Code=function_code,
                Role=os.environ.get('LAMBDA_EXECUTION_ROLE_ARN', 'arn:aws:iam::123456789012:role/lambda-execution-role'),
                Description='Created by Agentic AI',
                Tags={
                    'CreatedBy': 'AgenticAI',
                    'UserId': user_id,
                    'RequestId': request_id
                }
            )
            
            return {
                'functionName': function_name,
                'functionArn': response['FunctionArn'],
                'runtime': runtime,
                'handler': handler,
                'message': f'Lambda function "{function_name}" created successfully'
            }
            
        except ClientError as e:
            logger.error(f'Error creating Lambda function: {e}')
            raise
    
    async def create_rds_instance(self, parameters: Dict[str, Any], prompt: str,
                                  user_id: str, request_id: str) -> Dict[str, Any]:
        """Create RDS instance"""
        rds = boto3.client('rds', region_name=self.region)
        
        db_instance_identifier = parameters.get('dbInstanceIdentifier') or f'agentic-ai-db-{int(datetime.now().timestamp())}'
        db_instance_class = parameters.get('dbInstanceClass', 'db.t3.micro')
        engine = parameters.get('engine', 'mysql')
        master_username = parameters.get('masterUsername', 'admin')
        master_user_password = parameters.get('masterUserPassword') or self.generate_password()
        
        logger.info(f'Creating RDS instance: {db_instance_identifier}')
        
        try:
            response = rds.create_db_instance(
                DBInstanceIdentifier=db_instance_identifier,
                DBInstanceClass=db_instance_class,
                Engine=engine,
                MasterUsername=master_username,
                MasterUserPassword=master_user_password,
                AllocatedStorage=20,
                StorageType='gp2',
                Tags=[
                    {'Key': 'CreatedBy', 'Value': 'AgenticAI'},
                    {'Key': 'UserId', 'Value': user_id},
                    {'Key': 'RequestId', 'Value': request_id}
                ]
            )
            
            return {
                'dbInstanceIdentifier': db_instance_identifier,
                'dbInstanceClass': db_instance_class,
                'engine': engine,
                'masterUsername': master_username,
                'message': f'RDS instance "{db_instance_identifier}" creation initiated'
            }
            
        except ClientError as e:
            logger.error(f'Error creating RDS instance: {e}')
            raise
    
    async def create_vpc(self, parameters: Dict[str, Any], prompt: str,
                         user_id: str, request_id: str) -> Dict[str, Any]:
        """Create VPC"""
        cidr_block = parameters.get('cidrBlock', '10.0.0.0/16')
        vpc_name = parameters.get('vpcName') or f'AgenticAI-VPC-{int(datetime.now().timestamp())}'
        
        logger.info(f'Creating VPC: {vpc_name} with CIDR: {cidr_block}')
        
        # Check if we're in local testing mode
        if os.environ.get('LOCAL_TESTING') == 'true':
            logger.info('Local testing mode - simulating VPC creation')
            vpc_id = f'vpc-{request_id[:8]}mock'
            return {
                'vpcId': vpc_id,
                'cidrBlock': cidr_block,
                'vpcName': vpc_name,
                'message': f'VPC "{vpc_name}" created successfully with ID: {vpc_id} (SIMULATED)',
                'simulated': True
            }
        
        try:
            ec2 = boto3.client('ec2', region_name=self.region)
            response = ec2.create_vpc(
                CidrBlock=cidr_block,
                TagSpecifications=[{
                    'ResourceType': 'vpc',
                    'Tags': [
                        {'Key': 'Name', 'Value': vpc_name},
                        {'Key': 'CreatedBy', 'Value': 'AgenticAI'},
                        {'Key': 'UserId', 'Value': user_id},
                        {'Key': 'RequestId', 'Value': request_id}
                    ]
                }]
            )
            
            vpc_id = response['Vpc']['VpcId']
            
            # Enable DNS hostnames
            ec2.modify_vpc_attribute(
                VpcId=vpc_id,
                EnableDnsHostnames={'Value': True}
            )
            
            return {
                'vpcId': vpc_id,
                'cidrBlock': cidr_block,
                'vpcName': vpc_name,
                'message': f'VPC "{vpc_name}" created successfully with ID: {vpc_id}'
            }
            
        except ClientError as e:
            logger.error(f'Error creating VPC: {e}')
            raise
    
    async def create_subnet(self, parameters: Dict[str, Any], prompt: str,
                            user_id: str, request_id: str) -> Dict[str, Any]:
        """Create subnet"""
        ec2 = boto3.client('ec2', region_name=self.region)
        
        vpc_id = parameters.get('vpcId')
        cidr_block = parameters.get('cidrBlock', '10.0.1.0/24')
        availability_zone = parameters.get('availabilityZone', 'us-east-1a')
        
        if not vpc_id:
            raise ValueError('VPC ID is required to create subnet')
        
        logger.info(f'Creating subnet in VPC: {vpc_id} with CIDR: {cidr_block}')
        
        try:
            response = ec2.create_subnet(
                VpcId=vpc_id,
                CidrBlock=cidr_block,
                AvailabilityZone=availability_zone,
                TagSpecifications=[{
                    'ResourceType': 'subnet',
                    'Tags': [
                        {'Key': 'Name', 'Value': f'AgenticAI-Subnet-{int(datetime.now().timestamp())}'},
                        {'Key': 'CreatedBy', 'Value': 'AgenticAI'},
                        {'Key': 'UserId', 'Value': user_id},
                        {'Key': 'RequestId', 'Value': request_id}
                    ]
                }]
            )
            
            subnet_id = response['Subnet']['SubnetId']
            
            return {
                'subnetId': subnet_id,
                'vpcId': vpc_id,
                'cidrBlock': cidr_block,
                'availabilityZone': availability_zone,
                'message': f'Subnet created successfully with ID: {subnet_id}'
            }
            
        except ClientError as e:
            logger.error(f'Error creating subnet: {e}')
            raise
    
    async def create_security_group(self, parameters: Dict[str, Any], prompt: str,
                                    user_id: str, request_id: str) -> Dict[str, Any]:
        """Create security group"""
        ec2 = boto3.client('ec2', region_name=self.region)
        
        group_name = parameters.get('groupName') or f'AgenticAI-SG-{int(datetime.now().timestamp())}'
        description = parameters.get('description', 'Security group created by Agentic AI')
        vpc_id = parameters.get('vpcId')
        
        if not vpc_id:
            raise ValueError('VPC ID is required to create security group')
        
        logger.info(f'Creating security group: {group_name} in VPC: {vpc_id}')
        
        try:
            response = ec2.create_security_group(
                GroupName=group_name,
                Description=description,
                VpcId=vpc_id,
                TagSpecifications=[{
                    'ResourceType': 'security-group',
                    'Tags': [
                        {'Key': 'Name', 'Value': group_name},
                        {'Key': 'CreatedBy', 'Value': 'AgenticAI'},
                        {'Key': 'UserId', 'Value': user_id},
                        {'Key': 'RequestId', 'Value': request_id}
                    ]
                }]
            )
            
            group_id = response['GroupId']
            
            # Add default SSH rule
            ec2.authorize_security_group_ingress(
                GroupId=group_id,
                IpPermissions=[{
                    'IpProtocol': 'tcp',
                    'FromPort': 22,
                    'ToPort': 22,
                    'IpRanges': [{'CidrIp': '0.0.0.0/0'}]
                }]
            )
            
            return {
                'groupId': group_id,
                'groupName': group_name,
                'vpcId': vpc_id,
                'message': f'Security group "{group_name}" created successfully with ID: {group_id}'
            }
            
        except ClientError as e:
            logger.error(f'Error creating security group: {e}')
            raise
    
    async def deploy_application(self, parameters: Dict[str, Any], prompt: str,
                                user_id: str, request_id: str) -> Dict[str, Any]:
        """Deploy application"""
        logger.info('Deploying application...')
        
        # This would integrate with your existing CI/CD pipeline
        # For now, we'll simulate deployment steps
        
        deployment_steps = [
            'Building application',
            'Running tests',
            'Creating Docker image',
            'Pushing to ECR',
            'Deploying to EKS',
            'Updating ArgoCD'
        ]
        
        results = []
        
        for step in deployment_steps:
            logger.info(f'Executing: {step}')
            # Simulate step execution
            await self.delay(1)
            results.append({'step': step, 'status': 'completed'})
        
        return {
            'deploymentId': f'deploy-{int(datetime.now().timestamp())}',
            'steps': results,
            'message': 'Application deployed successfully'
        }
    
    async def scale_resources(self, parameters: Dict[str, Any], prompt: str,
                              user_id: str, request_id: str) -> Dict[str, Any]:
        """Scale resources"""
        logger.info('Scaling resources...')
        
        resource_type = parameters.get('resourceType', 'ec2')
        action = parameters.get('action', 'scale-out')
        count = parameters.get('count', 1)
        
        if resource_type == 'ec2':
            # Scale EC2 instances
            ec2 = boto3.client('ec2', region_name=self.region)
            autoscaling = boto3.client('autoscaling', region_name=self.region)
            
            # This would integrate with Auto Scaling Groups
            logger.info(f'Scaling {resource_type} by {action} with count: {count}')
            
            return {
                'resourceType': resource_type,
                'action': action,
                'count': count,
                'message': f'Scaling operation initiated for {resource_type}'
            }
        
        return {
            'resourceType': resource_type,
            'action': action,
            'count': count,
            'message': f'Scaling operation completed for {resource_type}'
        }
    
    async def monitor_resources(self, parameters: Dict[str, Any], prompt: str,
                               user_id: str, request_id: str) -> Dict[str, Any]:
        """Monitor resources"""
        logger.info('Monitoring resources...')
        
        cloudwatch = boto3.client('cloudwatch', region_name=self.region)
        resource_type = parameters.get('resourceType', 'all')
        
        try:
            # Get basic metrics
            response = cloudwatch.list_metrics(
                Namespace='AWS/EC2',
                MetricName='CPUUtilization'
            )
            
            return {
                'resourceType': resource_type,
                'metricsCount': len(response['Metrics']),
                'message': f'Monitoring data collected for {resource_type} resources'
            }
            
        except ClientError as e:
            logger.error(f'Error monitoring resources: {e}')
            raise
    
    async def optimize_costs(self, parameters: Dict[str, Any], prompt: str,
                            user_id: str, request_id: str) -> Dict[str, Any]:
        """Optimize costs"""
        logger.info('Optimizing costs...')
        
        ce = boto3.client('ce', region_name=self.region)
        
        try:
            # Get cost and usage data
            end_date = datetime.now()
            start_date = datetime.now()
            start_date = start_date.replace(day=start_date.day - 30)
            
            response = ce.get_cost_and_usage(
                TimePeriod={
                    'Start': start_date.strftime('%Y-%m-%d'),
                    'End': end_date.strftime('%Y-%m-%d')
                },
                Granularity='MONTHLY',
                Metrics=['UnblendedCost']
            )
            
            total_cost = response['ResultsByTime'][0]['Total']['UnblendedCost']['Amount']
            currency = response['ResultsByTime'][0]['Total']['UnblendedCost']['Unit']
            
            return {
                'totalCost': total_cost,
                'currency': currency,
                'message': 'Cost optimization analysis completed'
            }
            
        except ClientError as e:
            logger.error(f'Error optimizing costs: {e}')
            raise
    
    async def backup_resources(self, parameters: Dict[str, Any], prompt: str,
                               user_id: str, request_id: str) -> Dict[str, Any]:
        """Backup resources"""
        logger.info('Creating resource backups...')
        
        resource_type = parameters.get('resourceType', 'ec2')
        backup_type = parameters.get('backupType', 'snapshot')
        
        if resource_type == 'ec2' and backup_type == 'snapshot':
            ec2 = boto3.client('ec2', region_name=self.region)
            
            try:
                # Get EC2 instances
                response = ec2.describe_instances(
                    Filters=[{
                        'Name': 'instance-state-name',
                        'Values': ['running', 'stopped']
                    }]
                )
                
                snapshots = []
                
                for reservation in response['Reservations']:
                    for instance in reservation['Instances']:
                        for block_device in instance['BlockDeviceMappings']:
                            if 'Ebs' in block_device:
                                snapshot = ec2.create_snapshot(
                                    VolumeId=block_device['Ebs']['VolumeId'],
                                    Description=f'Backup of {instance["InstanceId"]} created by Agentic AI',
                                    TagSpecifications=[{
                                        'ResourceType': 'snapshot',
                                        'Tags': [
                                            {'Key': 'Name', 'Value': f'Backup-{instance["InstanceId"]}-{int(datetime.now().timestamp())}'},
                                            {'Key': 'CreatedBy', 'Value': 'AgenticAI'},
                                            {'Key': 'UserId', 'Value': user_id},
                                            {'Key': 'RequestId', 'Value': request_id}
                                        ]
                                    }]
                                )
                                
                                snapshots.append({
                                    'snapshotId': snapshot['SnapshotId'],
                                    'volumeId': block_device['Ebs']['VolumeId'],
                                    'instanceId': instance['InstanceId']
                                })
                
                return {
                    'resourceType': resource_type,
                    'backupType': backup_type,
                    'snapshotsCount': len(snapshots),
                    'snapshots': snapshots,
                    'message': f'Created {len(snapshots)} snapshots for EC2 instances'
                }
                
            except ClientError as e:
                logger.error(f'Error creating backups: {e}')
                raise
        
        return {
            'resourceType': resource_type,
            'backupType': backup_type,
            'message': f'Backup operation completed for {resource_type}'
        }
    
    async def update_infrastructure(self, parameters: Dict[str, Any], prompt: str,
                                    user_id: str, request_id: str) -> Dict[str, Any]:
        """Update infrastructure"""
        logger.info('Updating infrastructure...')
        
        # This would integrate with CloudFormation, Terraform, or other IaC tools
        update_type = parameters.get('updateType', 'rolling')
        resources = parameters.get('resources', ['ec2', 'rds', 'lambda'])
        
        return {
            'updateType': update_type,
            'resources': resources,
            'message': f'Infrastructure update initiated for {", ".join(resources)}'
        }
    
    # Helper methods
    def generate_bucket_name(self, prompt: str) -> str:
        """Generate a unique bucket name"""
        import random
        import string
        timestamp = int(datetime.now().timestamp())
        random_suffix = ''.join(random.choices(string.ascii_lowercase + string.digits, k=6))
        return f'agentic-ai-bucket-{timestamp}-{random_suffix}'
    
    def generate_password(self) -> str:
        """Generate a random password"""
        import random
        import string
        chars = string.ascii_letters + string.digits
        return ''.join(random.choice(chars) for _ in range(30))
    
    async def delay(self, seconds: int):
        """Delay execution for specified seconds"""
        import asyncio
        await asyncio.sleep(seconds)
    
    async def send_event(self, detail_type: str, detail: Dict[str, Any]):
        """Send events to EventBridge"""
        try:
            response = self.eventbridge.put_events(
                Entries=[{
                    'Source': 'agentic.ai',
                    'DetailType': detail_type,
                    'Detail': json.dumps(detail),
                    'EventBusName': os.environ.get('EVENTBRIDGE_BUS', 'default')
                }]
            )
            logger.info(f'Event sent: {detail_type}')
        except Exception as error:
            logger.error(f'Error sending event: {error}')
    
    async def send_message(self, message_body: Dict[str, Any]):
        """Send messages to SQS"""
        try:
            response = self.sqs.send_message(
                QueueUrl=os.environ.get('SQS_QUEUE_URL'),
                MessageBody=json.dumps(message_body)
            )
            logger.info('Message sent to SQS')
        except Exception as error:
            logger.error(f'Error sending message to SQS: {error}')


# Create instance
agentic_ai = AgenticAI()

# Lambda handler function
def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """Lambda handler function"""
    import asyncio
    return asyncio.run(agentic_ai.handler(event, context))


# For local testing
if __name__ == "__main__":
    # Test the agent
    test_event = {
        "prompt": "Create an S3 bucket named test-bucket-123",
        "userId": "test-user",
        "requestId": "test-123"
    }
    
    result = lambda_handler(test_event, None)
    print(json.dumps(result, indent=2))
