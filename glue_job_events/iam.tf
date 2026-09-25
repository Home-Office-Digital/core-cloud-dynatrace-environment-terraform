resource "aws_iam_role" "handler" {
  name = local.resource_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_policy" "read_token" {
  name        = "${local.resource_name}-read-token"
  description = "Allow the Glue event Lambda to read only its Dynatrace API token"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [{
        Sid      = "ReadDynatraceToken"
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = data.aws_secretsmanager_secret.dynatrace_api_token.arn
      }],
      var.dynatrace_api_token_kms_key_arn == null ? [] : [{
        Sid      = "DecryptDynatraceToken"
        Effect   = "Allow"
        Action   = ["kms:Decrypt"]
        Resource = var.dynatrace_api_token_kms_key_arn
      }]
    )
  })

  tags = var.tags
}

resource "aws_iam_policy" "write_dead_letter" {
  name        = "${local.resource_name}-write-dlq"
  description = "Allow failed Glue event Lambda invocations to reach the dead-letter queue"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["sqs:SendMessage"]
      Resource = aws_sqs_queue.dead_letter.arn
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "read_token" {
  role       = aws_iam_role.handler.name
  policy_arn = aws_iam_policy.read_token.arn
}

resource "aws_iam_role_policy_attachment" "write_dead_letter" {
  role       = aws_iam_role.handler.name
  policy_arn = aws_iam_policy.write_dead_letter.arn
}

resource "aws_iam_role_policy_attachment" "basic_execution" {
  role       = aws_iam_role.handler.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "xray_write" {
  role       = aws_iam_role.handler.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}
