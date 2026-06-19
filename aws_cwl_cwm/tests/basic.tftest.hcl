mock_provider "aws" {}

# minimum required inputs for the module to run, these can be overridden in the test cases below
variables {
  ingestion_type  = "logs"
  tags            = {}
  lambda_zip_output_path  = "./lambda-artifacts/test-cwl-failed-delivery-replay.zip"
}

# TEST 1: Basic plan succeeds
run "plan_succeeds_with_defaults" {
  command = plan

  assert {
    condition     = output.firehose_destination == "http_endpoint"
    error_message = "Kinesis Firehose delivery stream should be created with the correct name"
  }

  assert {
    condition     = output.failed_delivery_s3_notification_prefix == "errors/http-endpoint-failed/"
    error_message = "S3 ObjectCreated notifications must be filtered to errors/http-endpoint-failed/"
  }
}
