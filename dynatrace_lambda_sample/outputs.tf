output "function_name" {
  description = "Name of the OneAgent-instrumented sample Lambda."
  value       = aws_lambda_function.sample.function_name
}

output "function_arn" {
  description = "ARN of the OneAgent-instrumented sample Lambda."
  value       = aws_lambda_function.sample.arn
}

output "invoke_arn" {
  description = "Invoke ARN of the OneAgent-instrumented sample Lambda."
  value       = aws_lambda_function.sample.invoke_arn
}