output "lambda_function_name" {
  description = "Name of the Lambda that forwards Glue events."
  value       = aws_lambda_function.handler.function_name
}

output "lambda_role_arn" {
  description = "Lambda execution role ARN, for secrets with a restrictive resource policy."
  value       = aws_iam_role.handler.arn
}

output "terminal_event_rule_name" {
  description = "Name of the Glue terminal-state EventBridge rule."
  value       = aws_cloudwatch_event_rule.terminal_states.name
}

output "start_event_rule_name" {
  description = "Name of the StartJobRun EventBridge rule, when enabled."
  value       = try(aws_cloudwatch_event_rule.start_requests[0].name, null)
}

output "dead_letter_queue_url" {
  description = "URL of the EventBridge target dead-letter queue."
  value       = aws_sqs_queue.dead_letter.url
}
