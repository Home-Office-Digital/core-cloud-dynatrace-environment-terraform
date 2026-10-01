output "api_destination_arn" {
  description = "ARN of the EventBridge API destination for Dynatrace."
  value       = aws_cloudwatch_event_api_destination.dynatrace.arn
}

output "api_destination_connection_arn" {
  description = "ARN of the EventBridge connection used by the API destination."
  value       = aws_cloudwatch_event_connection.dynatrace.arn
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
