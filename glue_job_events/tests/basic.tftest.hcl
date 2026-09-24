mock_provider "aws" {}

variables {
  name                            = "cc-prelive"
  dynatrace_environment_url       = "https://example.live.dynatrace.com"
  dynatrace_api_token_secret_name = "dynatrace/events-token"
  dynatrace_api_token_json_key    = "DYNATRACE_API_TOKEN"
  job_names                       = ["daily-etl"]
  lambda_zip_output_path          = "./lambda-artifacts/test-glue-events.zip"
}

run "plan_creates_filtered_start_and_terminal_rules" {
  command = plan

  assert {
    condition     = jsondecode(aws_cloudwatch_event_rule.terminal_states.event_pattern).detail.jobName == ["daily-etl"]
    error_message = "The terminal-state rule must filter configured Glue job names."
  }

  assert {
    condition     = jsondecode(aws_cloudwatch_event_rule.start_requests[0].event_pattern).detail.eventName == ["StartJobRun"]
    error_message = "The start rule must capture StartJobRun through CloudTrail."
  }

  assert {
    condition     = aws_lambda_function.handler.environment[0].variables.TOKEN_SECRET_ARN != ""
    error_message = "The Lambda must receive the secret ARN rather than a token value."
  }

  assert {
    condition     = aws_sqs_queue.dead_letter.sqs_managed_sse_enabled
    error_message = "The EventBridge dead-letter queue must be encrypted."
  }

  assert {
    condition     = length(aws_lambda_function.handler.dead_letter_config) == 1
    error_message = "Lambda asynchronous failures must use the encrypted dead-letter queue."
  }
}

run "start_capture_can_be_disabled" {
  command = plan

  variables {
    capture_start_requests = false
  }

  assert {
    condition     = length(aws_cloudwatch_event_rule.start_requests) == 0
    error_message = "No CloudTrail start rule should be created when start capture is disabled."
  }
}
