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
      errorCode   = [{ exists = false }]
      }, length(var.job_names) > 0 ? {
      requestParameters = {
        jobName = sort(tolist(var.job_names))
      }
    } : {})
  }

  dynatrace_api_token = var.dynatrace_api_token_json_key == null ? ephemeral.aws_secretsmanager_secret_version.dynatrace_api_token.secret_string : jsondecode(ephemeral.aws_secretsmanager_secret_version.dynatrace_api_token.secret_string)[var.dynatrace_api_token_json_key]
}

data "aws_caller_identity" "current" {}

data "aws_secretsmanager_secret" "dynatrace_api_token" {
  name = var.dynatrace_api_token_secret_name
}

ephemeral "aws_secretsmanager_secret_version" "dynatrace_api_token" {
  secret_id = data.aws_secretsmanager_secret.dynatrace_api_token.id
}

resource "aws_cloudwatch_event_connection" "dynatrace" {
  name               = "${local.resource_name}-connection"
  description        = "Authorization for the Dynatrace Events API"
  authorization_type = "API_KEY"

  auth_parameters {
    api_key {
      key   = "Authorization"
      value = "Api-Token ${local.dynatrace_api_token}"
    }
  }
}

resource "aws_cloudwatch_event_api_destination" "dynatrace" {
  name                             = "${local.resource_name}-destination"
  description                      = "Direct Glue lifecycle event delivery to Dynatrace"
  invocation_endpoint              = "${trimsuffix(var.dynatrace_environment_url, "/")}/api/v2/events/ingest"
  http_method                      = "POST"
  connection_arn                   = aws_cloudwatch_event_connection.dynatrace.arn
  invocation_rate_limit_per_second = 10
}

resource "aws_iam_role" "api_destination_invocation" {
  name = "${local.resource_name}-api-destination"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "events.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_policy" "api_destination_invocation" {
  name        = "${local.resource_name}-api-destination"
  description = "Allow EventBridge to invoke the Dynatrace API destination"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["events:InvokeApiDestination"]
      Resource = aws_cloudwatch_event_api_destination.dynatrace.arn
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "api_destination_invocation" {
  role       = aws_iam_role.api_destination_invocation.name
  policy_arn = aws_iam_policy.api_destination_invocation.arn
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
  description   = "Capture successful AWS Glue StartJobRun calls for Dynatrace"
  event_pattern = jsonencode(local.start_event_pattern)
  tags          = var.tags
}

resource "aws_cloudwatch_event_target" "terminal_states" {
  rule      = aws_cloudwatch_event_rule.terminal_states.name
  target_id = "DynatraceGlueTerminalEvents"
  arn       = aws_cloudwatch_event_api_destination.dynatrace.arn
  role_arn  = aws_iam_role.api_destination_invocation.arn

  retry_policy {
    maximum_event_age_in_seconds = 86400
    maximum_retry_attempts       = 185
  }

  dead_letter_config {
    arn = aws_sqs_queue.dead_letter.arn
  }

  input_transformer {
    input_paths = {
      account  = "$.account"
      event_id = "$.id"
      job_name = "$.detail.jobName"
      job_run  = "$.detail.jobRunId"
      message  = "$.detail.message"
      region   = "$.region"
      state    = "$.detail.state"
    }
    input_template = <<-EOT
      {"eventType":"CUSTOM_ALERT","title":"AWS Glue job <state>: <job_name>","timeout":${var.event_timeout_minutes},"properties":{"aws.account.id":"<account>","aws.region":"<region>","aws.glue.job.name":"<job_name>","aws.glue.job.run.id":"<job_run>","aws.glue.job.state":"<state>","eventbridge.event.id":"<event_id>","event.description":"<message>"}}
    EOT
  }
}

resource "aws_cloudwatch_event_target" "start_requests" {
  count = var.capture_start_requests ? 1 : 0

  rule      = aws_cloudwatch_event_rule.start_requests[0].name
  target_id = "DynatraceGlueStartEvents"
  arn       = aws_cloudwatch_event_api_destination.dynatrace.arn
  role_arn  = aws_iam_role.api_destination_invocation.arn

  retry_policy {
    maximum_event_age_in_seconds = 86400
    maximum_retry_attempts       = 185
  }

  dead_letter_config {
    arn = aws_sqs_queue.dead_letter.arn
  }

  input_transformer {
    input_paths = {
      account  = "$.account"
      event_id = "$.id"
      job_name = "$.detail.requestParameters.jobName"
      job_run  = "$.detail.responseElements.jobRunId"
      region   = "$.region"
    }
    input_template = <<-EOT
      {"eventType":"CUSTOM_ALERT","title":"AWS Glue job START_REQUESTED: <job_name>","timeout":${var.event_timeout_minutes},"properties":{"aws.account.id":"<account>","aws.region":"<region>","aws.glue.job.name":"<job_name>","aws.glue.job.run.id":"<job_run>","aws.glue.job.state":"START_REQUESTED","eventbridge.event.id":"<event_id>"}}
    EOT
  }
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
