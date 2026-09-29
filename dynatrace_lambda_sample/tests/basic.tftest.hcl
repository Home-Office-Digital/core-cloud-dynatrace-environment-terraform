mock_provider "aws" {}

variables {
  function_name                = "global-dev-dynatrace-oneagent-sample"
  lambda_zip_output_path       = "./lambda-artifacts/global-dev-dynatrace-oneagent-sample.zip"
  layer_arn                    = "arn:aws:lambda:eu-west-2:123456789012:layer:Dynatrace_OneAgent_sample:1"
  connection_token_secret_name = "cc-dynatrace-oneagent-instance-token"
  dt_tenant                    = "gkm95600"
  dt_cluster                   = "-1480073609"
  dt_connection_base_url       = "https://home-office-dev.live.dynatrace.com"
  tags                         = { project = "global" }
}

run "plans_instrumented_python_lambda" {
  command = plan

  assert {
    condition     = aws_lambda_function.sample.runtime == "python3.12"
    error_message = "The sample function must use a supported Python runtime."
  }

  assert {
    condition     = length(aws_lambda_function.sample.layers) == 1 && aws_lambda_function.sample.layers[0] == var.layer_arn
    error_message = "The Dynatrace OneAgent layer must be attached to the sample function."
  }

  assert {
    condition     = aws_lambda_function.sample.environment[0].variables["AWS_LAMBDA_EXEC_WRAPPER"] == "/opt/dynatrace"
    error_message = "The Lambda execution wrapper must point to the OneAgent layer."
  }

  assert {
    condition     = aws_lambda_function.sample.environment[0].variables["DT_CONNECTION_AUTH_TOKEN_SECRETS_MANAGER_ARN"] != ""
    error_message = "The OneAgent connection token must be referenced through Secrets Manager."
  }
}