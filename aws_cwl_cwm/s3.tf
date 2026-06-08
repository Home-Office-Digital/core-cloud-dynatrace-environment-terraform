locals {
  s3_encryption_algorithm = "aws:kms"
  versioning_status       = "Disabled"
  s3_backup_bucket_name   = "${local.firehose_name}-bucket-${data.aws_caller_identity.current.account_id}"
}

#checkov:skip=CKV_AWS_144: core cloud is not yet cross region
#checkov:skip=CKV_AWS_21: the content of this bucket is produced only by AWS services and the source data is cloudwatch which should be treated as the master version.
#checkov:skip=CKV_AWS_18: No user/client access so cloudtrail is sufficient
resource "aws_s3_bucket" "cwl_backup_bucket" {
  bucket = local.s3_backup_bucket_name
  tags   = var.tags
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.cwl_backup_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cwl_backup_bucket_encryption" {
  bucket = aws_s3_bucket.cwl_backup_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = local.s3_encryption_algorithm
      kms_master_key_id = aws_kms_alias.cc_cosmos_firehose_s3_kms_alias.target_key_id
    }
  }
}

resource "aws_s3_bucket_versioning" "cwl_backup_bucket_versioning" {
  bucket = aws_s3_bucket.cwl_backup_bucket.id
  versioning_configuration {
    status = local.versioning_status
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  bucket = aws_s3_bucket.cwl_backup_bucket.id

  rule {
    id     = "cwl-bucket-lifecycle-rule"
    status = "Enabled"

    expiration {
      days = var.lifecycle_expiration_days
    }
  }

  rule {
    id     = "cwl-abort-incomplete-multipart-uploads"
    status = "Enabled"

    # No filter → applies to all multipart uploads
    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = var.days_after_initiation
    }
  }
}
