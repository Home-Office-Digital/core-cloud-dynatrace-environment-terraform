mock_provider "aws" {}

variables {
  name                            = "cc-prelive"
  dynatrace_environment_url       = "https://example.live.dynatrace.com"
  dynatrace_api_token_secret_name = "dynatrace/events-token"
  dynatrace_api_token_json_key    = null
  job_names                       = ["daily-etl"]
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
    condition     = jsondecode(aws_cloudwatch_event_rule.start_requests[0].event_pattern).detail.errorCode == [{ exists = false }]
    error_message = "The start rule must exclude failed StartJobRun API calls."
  }

  assert {
    condition     = aws_cloudwatch_event_api_destination.dynatrace.invocation_endpoint == "https://example.live.dynatrace.com/api/v2/events/ingest"
    error_message = "The API destination must target the Dynatrace Events API."
  }

  assert {
    condition     = aws_sqs_queue.dead_letter.sqs_managed_sse_enabled
    error_message = "The EventBridge dead-letter queue must be encrypted."
  }

  assert {
    condition     = aws_cloudwatch_event_target.terminal_states.target_id == "DynatraceGlueTerminalEvents"
    error_message = "Terminal Glue events must target the Dynatrace API destination directly."
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
