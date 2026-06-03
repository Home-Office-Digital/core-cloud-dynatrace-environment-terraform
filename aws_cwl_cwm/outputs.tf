output "cwl_backup_bucket" {
  description = "The name of the S3 bucket created for CloudWatch Logs backup."
  value       = aws_s3_bucket.cwl_backup_bucket.bucket
}
output "firehose_destination" {
  description = "Destination type of the delivery stream"
  value       = aws_kinesis_firehose_delivery_stream.dynatrace_http_stream.destination
}
output "kms_key_arn" {
  description = "The ARN of the KMS key used for S3 encryption."
  value       = aws_kms_key.cc_cosmos_s3_kms_key.arn
}

output "firehose_stream_arn" {
  description = "ARN of the Kinesis Firehose delivery stream"
  value       = aws_kinesis_firehose_delivery_stream.dynatrace_http_stream.arn
}

output "ingestion_type" {
  description = "The ingestion type for the Firehose delivery stream"
  value       = var.ingestion_type
}

output "failed_delivery_sqs_queue_arn" {
  description = "ARN of the SQS queue that receives failed delivery backup object notifications."
  value       = try(aws_sqs_queue.cwl_failed_delivery_events[0].arn, null)
}

output "failed_delivery_s3_notification_prefix" {
  description = "S3 key prefix used to route ObjectCreated notifications for failed HTTP endpoint backups."
  value       = var.ingestion_type == "logs" ? local.failed_delivery_error_prefix : null
}