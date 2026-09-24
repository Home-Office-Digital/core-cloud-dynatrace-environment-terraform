locals {
  resource_name = substr("${var.name}-glue-events", 0, 64)
  job_filter    = length(var.job_names) > 0 ? { jobName = sort(tolist(var.job_names)) } : {}

  terminal_event_pattern = {
    source      = ["aws.glue"]
    detail-type = ["Glue Job State Change"]
    detail = merge({
      state = sort(tolist(var.terminal_states))
    }, local.job_filter)
  }

  start_event_pattern = {
    source      = ["aws.glue"]
    detail-type = ["AWS API Call via CloudTrail"]
    detail = merge({
      eventSource = ["glue.amazonaws.com"]
      eventName   = ["StartJobRun"]
      }, length(var.job_names) > 0 ? {
      requestParameters = {
        jobName = sort(tolist(var.job_names))
      }
    } : {})
  }
}

data "aws_caller_identity" "current" {}

data "aws_secretsmanager_secret" "dynatrace_api_token" {
  name = var.dynatrace_api_token_secret_name
}

data "archive_file" "handler" {
  type        = "zip"
  output_path = var.lambda_zip_output_path
  source_file = "${path.module}/src/lambda_function.py"
}

resource "aws_cloudwatch_log_group" "handler" {
  name              = "/aws/lambda/${local.resource_name}"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

resource "aws_lambda_function" "handler" {
  #checkov:skip=CKV_AWS_117:The function only calls AWS Secrets Manager and the public Dynatrace API.
  function_name = local.resource_name
  description   = "Forward AWS Glue lifecycle events to Dynatrace"
  role          = aws_iam_role.handler.arn
  runtime       = "python3.12"
  handler       = "lambda_function.lambda_handler"

  filename         = data.archive_file.handler.output_path
  source_code_hash = data.archive_file.handler.output_base64sha256

  timeout                        = 15
  memory_size                    = 128
  reserved_concurrent_executions = 5

  tracing_config {
    mode = "Active"
  }

  dead_letter_config {
    target_arn = aws_sqs_queue.dead_letter.arn
  }

  environment {
    variables = {
      ALERT_STATES              = join(",", sort(tolist(var.alert_states)))
      DYNATRACE_ENVIRONMENT_URL = trimsuffix(var.dynatrace_environment_url, "/")
      EVENT_TIMEOUT_MINUTES     = tostring(var.event_timeout_minutes)
      TOKEN_JSON_KEY            = coalesce(var.dynatrace_api_token_json_key, "")
      TOKEN_SECRET_ARN          = data.aws_secretsmanager_secret.dynatrace_api_token.arn
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.handler,
    aws_iam_role_policy_attachment.basic_execution,
    aws_iam_role_policy_attachment.xray_write
  ]

  tags = var.tags
}

resource "aws_cloudwatch_event_rule" "terminal_states" {
  name          = "${local.resource_name}-terminal"
  description   = "Capture final AWS Glue job states for Dynatrace"
  event_pattern = jsonencode(local.terminal_event_pattern)
  tags          = var.tags
}

resource "aws_cloudwatch_event_rule" "start_requests" {
  count = var.capture_start_requests ? 1 : 0

  name          = "${local.resource_name}-start"
  description   = "Capture AWS Glue StartJobRun calls for Dynatrace"
  event_pattern = jsonencode(local.start_event_pattern)
  tags          = var.tags
}

resource "aws_cloudwatch_event_target" "terminal_states" {
  rule      = aws_cloudwatch_event_rule.terminal_states.name
  target_id = "DynatraceGlueEvents"
  arn       = aws_lambda_function.handler.arn

  retry_policy {
    maximum_event_age_in_seconds = 86400
    maximum_retry_attempts       = 185
  }

  dead_letter_config {
    arn = aws_sqs_queue.dead_letter.arn
  }
}

resource "aws_cloudwatch_event_target" "start_requests" {
  count = var.capture_start_requests ? 1 : 0

  rule      = aws_cloudwatch_event_rule.start_requests[0].name
  target_id = "DynatraceGlueStartEvents"
  arn       = aws_lambda_function.handler.arn

  retry_policy {
    maximum_event_age_in_seconds = 86400
    maximum_retry_attempts       = 185
  }

  dead_letter_config {
    arn = aws_sqs_queue.dead_letter.arn
  }
}

resource "aws_lambda_permission" "terminal_states" {
  statement_id  = "AllowEventBridgeTerminalStates"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.handler.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.terminal_states.arn
}

resource "aws_lambda_permission" "start_requests" {
  count = var.capture_start_requests ? 1 : 0

  statement_id  = "AllowEventBridgeStartRequests"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.handler.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.start_requests[0].arn
}

resource "aws_sqs_queue" "dead_letter" {
  name                       = "${local.resource_name}-dlq"
  message_retention_seconds  = 1209600
  sqs_managed_sse_enabled    = true
  visibility_timeout_seconds = 30
  tags                       = var.tags
}

resource "aws_sqs_queue_policy" "dead_letter" {
  queue_url = aws_sqs_queue.dead_letter.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [{
        Sid       = "AllowTerminalRule"
        Effect    = "Allow"
        Principal = { Service = "events.amazonaws.com" }
        Action    = "sqs:SendMessage"
        Resource  = aws_sqs_queue.dead_letter.arn
        Condition = {
          ArnEquals    = { "aws:SourceArn" = aws_cloudwatch_event_rule.terminal_states.arn }
          StringEquals = { "aws:SourceAccount" = data.aws_caller_identity.current.account_id }
        }
      }],
      var.capture_start_requests ? [{
        Sid       = "AllowStartRule"
        Effect    = "Allow"
        Principal = { Service = "events.amazonaws.com" }
        Action    = "sqs:SendMessage"
        Resource  = aws_sqs_queue.dead_letter.arn
        Condition = {
          ArnEquals    = { "aws:SourceArn" = aws_cloudwatch_event_rule.start_requests[0].arn }
          StringEquals = { "aws:SourceAccount" = data.aws_caller_identity.current.account_id }
        }
      }] : []
    )
  })
}
