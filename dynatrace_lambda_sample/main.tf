terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    archive = {
      source = "hashicorp/archive"
    }
  }
}

data "aws_secretsmanager_secret" "connection_token" {
  name = var.connection_token_secret_name
}

data "archive_file" "sample" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = var.lambda_zip_output_path
}

resource "aws_iam_role" "sample" {
  name = "${var.function_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "basic_execution" {
  role       = aws_iam_role.sample.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "connection_token" {
  name = "${var.function_name}-connection-token"
  role = aws_iam_role.sample.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "secretsmanager:GetSecretValue"
      Resource = data.aws_secretsmanager_secret.connection_token.arn
    }]
  })
}

resource "aws_cloudwatch_log_group" "sample" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = 7
  tags              = var.tags
}

resource "aws_lambda_function" "sample" {
  function_name = var.function_name
  description   = "HOOS sandbox function for validating Dynatrace OneAgent Lambda instrumentation"
  role          = aws_iam_role.sample.arn
  runtime       = "python3.12"
  handler       = "app.handler"

  filename         = data.archive_file.sample.output_path
  source_code_hash = data.archive_file.sample.output_base64sha256
  layers           = [var.layer_arn]

  memory_size                    = 256
  timeout                        = 10
  reserved_concurrent_executions = 1

  environment {
    variables = {
      AWS_LAMBDA_EXEC_WRAPPER                      = "/opt/dynatrace"
      DT_TENANT                                    = var.dt_tenant
      DT_CLUSTER                                   = var.dt_cluster
      DT_CONNECTION_BASE_URL                       = var.dt_connection_base_url
      DT_CONNECTION_AUTH_TOKEN_SECRETS_MANAGER_ARN = data.aws_secretsmanager_secret.connection_token.arn
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.sample,
    aws_iam_role_policy_attachment.basic_execution,
    aws_iam_role_policy.connection_token,
  ]

  tags = var.tags
}