variable "function_name" {
  description = "Name of the sandbox Lambda function."
  type        = string
}

variable "lambda_zip_output_path" {
  description = "Path for the generated Lambda deployment ZIP."
  type        = string
}

variable "layer_arn" {
  description = "Dynatrace OneAgent Lambda layer ARN for the selected runtime, architecture, and AWS region."
  type        = string

  validation {
    condition     = startswith(var.layer_arn, "arn:aws:lambda:")
    error_message = "layer_arn must be a Dynatrace AWS Lambda layer ARN."
  }
}

variable "connection_token_secret_name" {
  description = "Name of the Secrets Manager secret containing the Dynatrace Lambda connection token."
  type        = string
}

variable "dt_tenant" {
  description = "Dynatrace tenant identifier used by the OneAgent Lambda layer."
  type        = string
}

variable "dt_cluster" {
  description = "Dynatrace cluster identifier used by the OneAgent Lambda layer."
  type        = string
}

variable "dt_connection_base_url" {
  description = "Dynatrace connection base URL without an API path."
  type        = string
}

variable "tags" {
  description = "Tags applied to the sample Lambda resources."
  type        = map(string)
  default     = {}
}