locals {
  failed_delivery_notifications_enabled = var.ingestion_type == "logs"
  failed_delivery_error_suffix          = "http-endpoint-failed/"
  failed_delivery_error_prefix          = "${local.s3_error_prefix}${local.failed_delivery_error_suffix}"
  failed_delivery_queue_name            = "${local.firehose_name}-failed-delivery-events"
}

resource "aws_sqs_queue" "cwl_failed_delivery_events" {
  count = local.failed_delivery_notifications_enabled ? 1 : 0

  name                      = local.failed_delivery_queue_name
  sqs_managed_sse_enabled   = true
  message_retention_seconds = var.failed_delivery_sqs_message_retention_seconds
  tags                      = var.tags
}

resource "aws_s3_bucket_notification" "cwl_failed_delivery_events" {
  count = local.failed_delivery_notifications_enabled ? 1 : 0

  bucket = aws_s3_bucket.cwl_backup_bucket.id

  queue {
    queue_arn     = aws_sqs_queue.cwl_failed_delivery_events[0].arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = local.failed_delivery_error_prefix
  }

  depends_on = [aws_sqs_queue_policy.cwl_failed_delivery_events]
}
