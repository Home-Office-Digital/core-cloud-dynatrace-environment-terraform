data "archive_file" "cwl_failed_delivery_replay" {
  count = local.failed_delivery_notifications_enabled ? 1 : 0

  type        = "zip"
  output_path = var.lambda_zip_output_path
  source_file = "${path.module}/src/lambda_function.py"
}

resource "aws_lambda_function" "cwl_failed_delivery_replay" {
  count = local.failed_delivery_notifications_enabled ? 1 : 0
  #checkov:skip=CKV_AWS_116:DLQ coming in later story
  #checkov:skip=CKV_AWS_117:No VPC required for this Lambda
  #checkov:skip=CKV_AWS_272:Code signing not required for internal utility Lambda

  depends_on = [
    data.archive_file.cwl_failed_delivery_replay[0],
    aws_iam_role_policy_attachment.cwl_failed_delivery_replay,
    aws_iam_role_policy_attachment.cwl_failed_delivery_replay_basic
  ]

  function_name = "${local.firehose_name}-failed-delivery-replay"
  description   = "Replays failed CloudWatch Logs Firehose deliveries from S3 back into Firehose"

  role    = aws_iam_role.cwl_failed_delivery_replay[0].arn
  runtime = "python3.12"
  handler = "lambda_function.lambda_handler"

  filename         = data.archive_file.cwl_failed_delivery_replay[0].output_path
  source_code_hash = data.archive_file.cwl_failed_delivery_replay[0].output_base64sha256

  timeout     = 300
  memory_size = 512
  reserved_concurrent_executions = 5

  tracing_config {
    mode = "Active"
  }

  tags = var.tags
}

resource "aws_lambda_event_source_mapping" "cwl_failed_delivery_replay" {
  count = local.failed_delivery_notifications_enabled ? 1 : 0

  event_source_arn = aws_sqs_queue.cwl_failed_delivery_events[0].arn
  function_name    = aws_lambda_function.cwl_failed_delivery_replay[0].arn

  batch_size = 10
  enabled    = true
}