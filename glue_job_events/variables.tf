variable "name" {
  description = "Name prefix for Glue event forwarding resources."
  type        = string

  validation {
    condition     = length(var.name) > 0 && length(var.name) <= 40
    error_message = "name must contain between 1 and 40 characters."
  }
}

variable "dynatrace_environment_url" {
  description = "Dynatrace environment base URL, for example https://abc123.live.dynatrace.com."
  type        = string

  validation {
    condition     = startswith(var.dynatrace_environment_url, "https://")
    error_message = "dynatrace_environment_url must use HTTPS."
  }
}

variable "dynatrace_api_token_secret_name" {
  description = "Name of the Secrets Manager secret containing a token with the events.ingest scope."
  type        = string
}

variable "dynatrace_api_token_json_key" {
  description = "JSON key containing the token. Set to null when the secret value is the token itself."
  type        = string
  default     = null
}

variable "dynatrace_api_token_kms_key_arn" {
  description = "Customer-managed KMS key ARN used by the token secret, when applicable."
  type        = string
  default     = null
}

variable "job_names" {
  description = "Glue job names to forward. An empty set forwards all Glue jobs in the account and region."
  type        = set(string)
  default     = []
}

variable "terminal_states" {
  description = "Glue Job State Change states to forward."
  type        = set(string)
  default     = ["FAILED", "TIMEOUT", "STOPPED"]

  validation {
    condition     = length(var.terminal_states) > 0
    error_message = "terminal_states must contain at least one state."
  }
}

variable "alert_states" {
  description = "States sent as CUSTOM_ALERT instead of CUSTOM_INFO. START_REQUESTED represents StartJobRun."
  type        = set(string)
  default     = ["START_REQUESTED", "FAILED", "TIMEOUT", "STOPPED"]
}

variable "capture_start_requests" {
  description = "Capture StartJobRun API calls. Requires a CloudTrail trail recording Glue management events."
  type        = bool
  default     = true
}

variable "event_timeout_minutes" {
  description = "Dynatrace event timeout in minutes."
  type        = number
  default     = 15

  validation {
    condition     = var.event_timeout_minutes >= 1 && var.event_timeout_minutes <= 360
    error_message = "event_timeout_minutes must be between 1 and 360."
  }
}

variable "log_retention_days" {
  description = "CloudWatch retention for Lambda logs."
  type        = number
  default     = 14
}

variable "lambda_zip_output_path" {
  description = "Path for the generated Lambda deployment ZIP."
  type        = string
}

variable "tags" {
  description = "Tags to apply to supported resources."
  type        = map(string)
  default     = {}
}
