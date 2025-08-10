# 🤖 Agentic AI Infrastructure Variables

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "awstoazure"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "lambda_timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 300
}

variable "lambda_memory_size" {
  description = "Lambda function memory size in MB"
  type        = number
  default     = 512
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

variable "approval_timeout_seconds" {
  description = "Timeout for operation approval in seconds"
  type        = number
  default     = 300
}

variable "enable_approval_gates" {
  description = "Enable approval gates for production operations"
  type        = bool
  default     = true
}

variable "enable_cost_optimization" {
  description = "Enable cost optimization features"
  type        = bool
  default     = true
}

variable "enable_auto_scaling" {
  description = "Enable auto-scaling features"
  type        = bool
  default     = true
}

variable "enable_monitoring" {
  description = "Enable comprehensive monitoring"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default = {
    Owner       = "DevOps Team"
    CostCenter  = "Engineering"
    Project     = "Agentic-AI"
    Purpose     = "Autonomous Operations"
  }
}
