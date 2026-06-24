locals {
  aws_kms_alias_firehose = var.ingestion_type == "metrics" ? "alias/cc_cosmos_firehose_cwm_s3_kms_alias" : "alias/cc_cosmos_firehose_cwl_s3_kms_alias"
}
resource "aws_kms_key" "cc_cosmos_s3_kms_key" {
  description         = "KMS CMK for S3 encryption"
  enable_key_rotation = true

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowRootAccountFullAccess",
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action   = "kms:*",
        Resource = "*"
      },
      {
        Sid    = "AllowFirehoseServiceToUseKey",
        Effect = "Allow",
        Principal = {
          Service = "firehose.amazonaws.com"
        },
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        Resource = "*",
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = "${data.aws_caller_identity.current.account_id}"
          }
        }
      },
      {
        Sid    = "AllowFirehoseRolesToUseKey",
        Effect = "Allow",
        Principal = {
          AWS = concat(
            [aws_iam_role.cc_cosmos_cwl_firehose_access_role.arn],
            local.failed_delivery_notifications_enabled ? [aws_iam_role.cwl_failed_delivery_replay[0].arn] : []
          )
        },
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        Resource = "*"
      },
      {
        Sid    = "AllowCloudWatchLogsToUseKey",
        Effect = "Allow",
        Principal = {
          Service = "logs.${data.aws_region.current.region}.amazonaws.com"
        },
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        Resource = "*"
      },
      {
        Sid    = "AllowLambdaServiceToUseKey",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        Resource = "*",
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }

    ]
  })
  tags = var.tags
}

resource "aws_kms_alias" "cc_cosmos_firehose_s3_kms_alias" {
  name          = local.aws_kms_alias_firehose
  target_key_id = aws_kms_key.cc_cosmos_s3_kms_key.id
}