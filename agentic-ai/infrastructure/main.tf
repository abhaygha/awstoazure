# 🤖 Agentic AI Infrastructure for AWS Operations
# This creates the autonomous AI system that can perform AWS operations

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "Agentic-AI"
      Environment = var.environment
      ManagedBy   = "Terraform"
      Purpose     = "Autonomous AWS Operations"
    }
  }
}

# 🧠 Core AI Agent Lambda Function
resource "aws_lambda_function" "agentic_ai_agent" {
  filename         = "../agent/dist/agent.zip"
  function_name    = "${var.project_name}-agentic-ai-agent"
  role            = aws_iam_role.lambda_execution_role.arn
  handler         = "index.handler"
  runtime         = "nodejs18.x"
  timeout         = 300
  memory_size     = 512

  environment {
    variables = {
      ENVIRONMENT        = var.environment
      PROJECT_NAME       = var.project_name
      EVENTBRIDGE_BUS   = aws_cloudwatch_event_bus.agentic_ai_events.name
      SQS_QUEUE_URL     = aws_sqs_queue.command_queue.url
      LOG_GROUP_NAME    = aws_cloudwatch_log_group.agentic_ai_logs.name
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_logs,
    aws_cloudwatch_log_group.agentic_ai_logs
  ]
}

# 🔄 EventBridge for orchestrating operations
resource "aws_cloudwatch_event_bus" "agentic_ai_events" {
  name = "${var.project_name}-agentic-ai-events"
}

# 📨 SQS Queue for command processing
resource "aws_sqs_queue" "command_queue" {
  name                      = "${var.project_name}-agentic-ai-commands"
  delay_seconds             = 0
  max_message_size          = 262144
  message_retention_seconds = 1209600
  receive_wait_time_seconds = 20
  visibility_timeout_seconds = 60

  tags = {
    Purpose = "AI Command Processing"
  }
}

# 🚀 Step Functions for complex workflows
resource "aws_sfn_state_machine" "agentic_ai_workflow" {
  name     = "${var.project_name}-agentic-ai-workflow"
  role_arn = aws_iam_role.step_functions_role.arn

  definition = jsonencode({
    Comment = "Agentic AI Autonomous Operations Workflow"
    StartAt = "ProcessCommand"
    
    States = {
      "ProcessCommand" = {
        Type = "Pass"
        Result = {
          message = "Command processed by Agentic AI"
          timestamp = "$$.State.EnteredTime"
        }
        Next = "Success"
      }
      
             "Success" = {
         Type = "Succeed"
         Comment = "Operation completed successfully"
       }
     }
   })
}

# 📊 CloudWatch Logs for monitoring
resource "aws_cloudwatch_log_group" "agentic_ai_logs" {
  name              = "/aws/lambda/${var.project_name}-agentic-ai-agent"
  retention_in_days = 30
}

# 🔐 IAM Role for Lambda execution
resource "aws_iam_role" "lambda_execution_role" {
  name = "${var.project_name}-agentic-ai-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# 🔐 IAM Role for Step Functions
resource "aws_iam_role" "step_functions_role" {
  name = "${var.project_name}-agentic-ai-stepfunctions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "states.amazonaws.com"
        }
      }
    ]
  })
}

# 📋 IAM Policies
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Custom policy for AI agent operations
resource "aws_iam_policy" "agentic_ai_operations" {
  name        = "${var.project_name}-agentic-ai-operations"
  description = "Policy for Agentic AI to perform AWS operations"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:*",
          "ec2:*",
          "ecs:*",
          "ecr:*",
          "lambda:*",
          "s3:*",
          "iam:*",
          "cloudwatch:*",
          "logs:*",
          "events:*",
          "sqs:*",
          "states:*",
          "autoscaling:*",
          "elasticloadbalancing:*",
          "rds:*",
          "dynamodb:*",
          "sns:*",
          "secretsmanager:*",
          "ssm:*",
          "cloudformation:*"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_operations" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.agentic_ai_operations.arn
}

# Step Functions execution policy (simplified for now)
resource "aws_iam_policy" "step_functions_execution" {
  name        = "${var.project_name}-stepfunctions-execution"
  description = "Policy for Step Functions basic execution"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogDelivery",
          "logs:GetLogDelivery",
          "logs:UpdateLogDelivery",
          "logs:DeleteLogDelivery",
          "logs:ListLogDeliveries",
          "logs:PutLogEvents",
          "logs:PutResourcePolicy",
          "logs:DescribeResourcePolicies",
          "logs:DescribeLogGroups"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "step_functions_execution" {
  role       = aws_iam_role.step_functions_role.name
  policy_arn = aws_iam_policy.step_functions_execution.arn
}

# 🔄 EventBridge rules for different operation types
resource "aws_cloudwatch_event_rule" "eks_operations" {
  name           = "${var.project_name}-eks-operations"
  description    = "Trigger AI agent for EKS operations"
  event_bus_name = aws_cloudwatch_event_bus.agentic_ai_events.name

  event_pattern = jsonencode({
    source      = ["agentic-ai"]
    detail-type = ["eks-operation"]
  })
}

resource "aws_cloudwatch_event_rule" "deployment_operations" {
  name           = "${var.project_name}-deployment-operations"
  description    = "Trigger AI agent for deployment operations"
  event_bus_name = aws_cloudwatch_event_bus.agentic_ai_events.name

  event_pattern = jsonencode({
    source      = ["agentic-ai"]
    detail-type = ["deployment-operation"]
  })
}

resource "aws_cloudwatch_event_rule" "monitoring_operations" {
  name           = "${var.project_name}-monitoring-operations"
  description    = "Trigger AI agent for monitoring operations"
  event_bus_name = aws_cloudwatch_event_bus.agentic_ai_events.name

  event_pattern = jsonencode({
    source      = ["agentic-ai"]
    detail-type = ["monitoring-operation"]
  })
}

# 🎯 EventBridge targets
resource "aws_cloudwatch_event_target" "eks_operations_target" {
  rule           = aws_cloudwatch_event_rule.eks_operations.name
  target_id      = "EKSOperationsTarget"
  event_bus_name = aws_cloudwatch_event_bus.agentic_ai_events.name
  arn            = aws_lambda_function.agentic_ai_agent.arn
}

resource "aws_cloudwatch_event_target" "deployment_operations_target" {
  rule           = aws_cloudwatch_event_rule.deployment_operations.name
  target_id      = "DeploymentOperationsTarget"
  event_bus_name = aws_cloudwatch_event_bus.agentic_ai_events.name
  arn            = aws_lambda_function.agentic_ai_agent.arn
}

resource "aws_cloudwatch_event_target" "monitoring_operations_target" {
  rule           = aws_cloudwatch_event_rule.monitoring_operations.name
  target_id      = "MonitoringOperationsTarget"
  event_bus_name = aws_cloudwatch_event_bus.agentic_ai_events.name
  arn            = aws_lambda_function.agentic_ai_agent.arn
}

# 🔐 Lambda permission for EventBridge
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.agentic_ai_agent.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_bus.agentic_ai_events.arn
}

# 📊 CloudWatch Dashboard for monitoring
resource "aws_cloudwatch_dashboard" "agentic_ai_dashboard" {
  dashboard_name = "${var.project_name}-agentic-ai-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/Lambda", "Invocations", "FunctionName", aws_lambda_function.agentic_ai_agent.function_name],
            [".", "Errors", ".", "."],
            [".", "Duration", ".", "."]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "AI Agent Performance"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/States", "ExecutionsSucceeded", "StateMachineArn", aws_sfn_state_machine.agentic_ai_workflow.arn],
            [".", "ExecutionsFailed", ".", "."],
            [".", "ExecutionTime", ".", "."]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "Workflow Execution Status"
        }
      }
    ]
  })
}
