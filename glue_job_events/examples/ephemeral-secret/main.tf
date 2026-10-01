terraform {
  required_version = ">= 1.11.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type    = string
  default = "eu-west-2"
}

variable "secret_id" {
  description = "AWS Secrets Manager secret name or ARN to read ephemerally."
  type        = string
}

ephemeral "aws_secretsmanager_secret_version" "dynatrace_api_token" {
  secret_id = var.secret_id
}

check "ephemeral_token_available" {
  assert {
    condition     = length(ephemeral.aws_secretsmanager_secret_version.dynatrace_api_token.secret_string) > 0
    error_message = "The ephemeral secret value was not available."
  }
}
