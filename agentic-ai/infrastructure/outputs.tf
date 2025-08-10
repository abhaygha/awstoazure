# 🤖 Agentic AI Infrastructure Outputs

output "lambda_function_arn" {
  description = "ARN of the Agentic AI Lambda function"
  value       = aws_lambda_function.agentic_ai_agent.arn
}

output "lambda_function_name" {
  description = "Name of the Agentic AI Lambda function"
  value       = aws_lambda_function.agentic_ai_agent.function_name
}

output "step_function_arn" {
  description = "ARN of the Agentic AI Step Function workflow"
  value       = aws_sfn_state_machine.agentic_ai_workflow.arn
}

output "step_function_name" {
  description = "Name of the Agentic AI Step Function workflow"
  value       = aws_sfn_state_machine.agentic_ai_workflow.name
}

output "eventbridge_bus_name" {
  description = "Name of the Agentic AI EventBridge bus"
  value       = aws_cloudwatch_event_bus.agentic_ai_events.name
}

output "sqs_queue_url" {
  description = "URL of the Agentic AI command queue"
  value       = aws_sqs_queue.command_queue.url
}

output "cloudwatch_dashboard_name" {
  description = "Name of the Agentic AI CloudWatch dashboard"
  value       = aws_cloudwatch_dashboard.agentic_ai_dashboard.dashboard_name
}

output "invoke_command" {
  description = "Command to invoke the Agentic AI agent"
  value       = "aws lambda invoke --function-name ${aws_lambda_function.agentic_ai_agent.function_name} --payload '{\"prompt\": \"Your command here\"}' response.json"
}

output "step_function_start_command" {
  description = "Command to start the Agentic AI workflow"
  value       = "aws stepfunctions start-execution --state-machine-arn ${aws_sfn_state_machine.agentic_ai_workflow.arn} --input '{\"prompt\": \"Your command here\"}'"
}

output "monitoring_dashboard_url" {
  description = "URL to access the CloudWatch monitoring dashboard"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.agentic_ai_dashboard.dashboard_name}"
}
