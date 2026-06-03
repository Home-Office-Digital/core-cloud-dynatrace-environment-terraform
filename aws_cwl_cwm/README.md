## Notes:

### Reference architecture: see https://collaboration.homeoffice.gov.uk/spaces/CORE/pages/380273616/Dynatrace+Cloudwatch+Logs+Collection

### This module other than the input variables defined in the variables.tf file also needs two secrets declared in AWS Secret manager (see the variables.tf for the actual name)

## Failed delivery S3 -> SQS notification

For `ingestion_type = "logs"`, this module configures:

- S3 ObjectCreated event notifications from the Firehose backup bucket
- Prefix filter: `errors/http-endpoint-failed/`
- SQS target queue for failed delivery backup notifications

This ensures only failed HTTP endpoint backup objects trigger notifications.

### Related input variable

- `failed_delivery_sqs_message_retention_seconds` (default: `1209600`)
	Controls SQS message retention for failed delivery notifications.

### Verification steps (post-apply)

1. Confirm S3 notification configuration includes the queue and prefix filter:

```bash
aws s3api get-bucket-notification-configuration \
	--bucket <firehose-backup-bucket-name>
```

2. Upload a test object under the configured prefix and verify a message appears:

```bash
aws s3 cp ./sample.gz s3://<firehose-backup-bucket-name>/errors/http-endpoint-failed/test/sample.gz
aws sqs receive-message --queue-url <failed-delivery-queue-url> --max-number-of-messages 1
```

3. Upload outside the prefix and verify no new message is produced:

```bash
aws s3 cp ./sample.gz s3://<firehose-backup-bucket-name>/errors/other/test/sample.gz
aws sqs receive-message --queue-url <failed-delivery-queue-url> --max-number-of-messages 1
```

Expected SQS message body includes S3 bucket/object key fields needed to locate the failed backup object.