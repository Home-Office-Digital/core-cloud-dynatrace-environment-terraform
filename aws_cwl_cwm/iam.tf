locals {
  org_id                                     = data.aws_organizations_organization.current.id
  firehose_access_role_name                  = "${local.firehose_name}-access-role"
  cc_cosmos_firehose_s3_logs_kms_policy_name = "${local.firehose_name}-s3-logs-kms-policy"
}

resource "aws_iam_role" "cc_cosmos_cwl_firehose_access_role" {
  name = local.firehose_access_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "firehose.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
  tags = var.tags
}

resource "aws_iam_policy" "cc_cosmos_cwl_firehose_s3_logs_kms_policy" {
  name        = local.cc_cosmos_firehose_s3_logs_kms_policy_name
  description = "Policy for Firehose roles to access S3 bucket and KMS key"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3Access"
        Effect = "Allow"
        Action = [
          "s3:AbortMultipartUpload",
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:PutObject",
          "s3:PutObjectAcl"
        ]
        Resource = [
          aws_s3_bucket.cwl_backup_bucket.arn,
          "${aws_s3_bucket.cwl_backup_bucket.arn}/*"
        ]
      },
      {
        Sid    = "CloudWatchLogsAccess"
        Effect = "Allow"
        Action = [
          "logs:PutLogEvents"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      },
      {
        Sid    = "KMSAccess"
        Effect = "Allow"
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = [
          aws_kms_key.cc_cosmos_s3_kms_key.arn
        ]
      }
    ]
  })
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "firehose_s3_policy_attachment" {
  role       = aws_iam_role.cc_cosmos_cwl_firehose_access_role.name
  policy_arn = aws_iam_policy.cc_cosmos_cwl_firehose_s3_logs_kms_policy.arn
}

## IAM policy to allow CWL to assume role to Firehose stream
resource "aws_iam_role" "cwl_to_firehose_role" {
  count = var.ingestion_type == "logs" ? 1 : 0
  name  = "CloudWatchLogsToFirehoseRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = "logs.${data.aws_region.current.region}.amazonaws.com"
        }
      }
    ]
  })
  tags = var.tags
}

resource "aws_iam_policy" "logs_to_firehose_policy" {
  count       = var.ingestion_type == "logs" ? 1 : 0
  name        = "CloudWatchLogsToFirehosePolicy"
  description = "Allows CloudWatch Logs to put records into Firehose"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "firehose:PutRecord",
          "firehose:PutRecordBatch"
        ]
        Resource = [aws_kinesis_firehose_delivery_stream.dynatrace_http_stream.arn]
      }
    ]
  })
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "cwl_to_firehose_attach" {
  count      = var.ingestion_type == "logs" ? 1 : 0
  role       = aws_iam_role.cwl_to_firehose_role[0].id
  policy_arn = aws_iam_policy.logs_to_firehose_policy[0].arn
}

# Policy to allow cwl sender account to access the destination in recipient account
resource "aws_cloudwatch_log_destination_policy" "cwl_dt_subscription_policy" {
  count = var.ingestion_type == "logs" ? 1 : 0

  destination_name = aws_cloudwatch_log_destination.cloudwatch_logs_destination[0].name
  access_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowPutSubscriptionFilter"
        Effect    = "Allow"
        Principal = "*"
        Condition = {
          StringEquals = {
            "aws:PrincipalOrgID" = local.org_id
          }
        }
        Action   = "logs:PutSubscriptionFilter"
        Resource = aws_cloudwatch_log_destination.cloudwatch_logs_destination[0].arn
      }
    ]
  })
}

# Resource-based IAM policy allowing S3 bucket notifications to publish to SQS
resource "aws_sqs_queue_policy" "cwl_failed_delivery_events" {
  count = var.ingestion_type == "logs" ? 1 : 0

  queue_url = aws_sqs_queue.cwl_failed_delivery_events[0].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowS3BucketNotifications"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.cwl_failed_delivery_events[0].arn
        Condition = {
          ArnLike = {
            "aws:SourceArn" = aws_s3_bucket.cwl_backup_bucket.arn
          }
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "cwl_failed_delivery_replay" {
  count = local.failed_delivery_notifications_enabled ? 1 : 0

  name        = "${local.firehose_name}-failed-delivery-replay"
  description = "Allow Lambda to read from S3 and replay them to Firehose delivery stream"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadBackupObjects"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:GetObjectTagging",
          "s3:PutObject",
          "s3:PutObjectTagging",
          "s3:DeleteObject"
        ]
        Resource = [
          aws_s3_bucket.cwl_backup_bucket.arn,
          "${aws_s3_bucket.cwl_backup_bucket.arn}/*"
        ]
      },
      {
        Sid    = "ReadFailedDeliveryQueue"
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:ChangeMessageVisibility"
        ]
        Resource = [
          aws_sqs_queue.cwl_failed_delivery_events[0].arn
        ]
      },
      {
        Sid    = "UseS3BackupKmsKey"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey"
        ]
        Resource = [
          aws_kms_key.cc_cosmos_s3_kms_key.arn
        ]
      },
      {
        Sid    = "ReplayToFirehose"
        Effect = "Allow"
        Action = [
          "firehose:PutRecord",
          "firehose:PutRecordBatch"
        ]
        Resource = [
          aws_kinesis_firehose_delivery_stream.dynatrace_http_stream.arn
        ]
      }
    ]
  })
  tags = var.tags
}

resource "aws_iam_role" "cwl_failed_delivery_replay" {
  count = local.failed_delivery_notifications_enabled ? 1 : 0
  name = "${local.firehose_name}-failed-delivery-replay"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "cwl_failed_delivery_replay" {
  count = local.failed_delivery_notifications_enabled ? 1 : 0
  role       = aws_iam_role.cwl_failed_delivery_replay[0].name
  policy_arn = aws_iam_policy.cwl_failed_delivery_replay[0].arn
}

resource "aws_iam_role_policy_attachment" "cwl_failed_delivery_replay_basic" {
  count = local.failed_delivery_notifications_enabled ? 1 : 0
  role       = aws_iam_role.cwl_failed_delivery_replay[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}