variable "tags" {
  description = "A map of tags to assign to the resource."
  type        = map(string)
}

variable "lifecycle_expiration_days" {
  description = "Number of days to keep objects before expiration"
  type        = number
  default     = 10
}

variable "dt_cwl_api_token_name" {
  description = "The name of the CWL Dynatrace API token in AWS Secrets Manager"
  type        = string
  default     = "dynatrace/cc-cosmos-dt-cwl-firehose-ingest-token"
}

variable "dt_cwm_api_token_name" {
  description = "The name of the CWM Dynatrace API token in AWS Secrets Manager"
  type        = string
  default     = "dynatrace/cc-cosmos-dt-cwm-firehose-ingest-token"
}
variable "dt_endpoint_name" {
  description = "The destination endpoint of the Dynatrace"
  type        = string
  default     = "dynatrace/cc-cosmos-dt-cwl-firehose-destination-endpoint"
}
variable "dt_endpoint_internal_name" {
  description = "The internal destination endpoint of the Dynatrace for metrics ingestion"
  type        = string
  default     = "dynatrace/cc-cosmos-dt-cwl-firehose-destination-endpoint-internal"
}

variable "dt_logs_api_endpoint_name" {
  description = "The destination endpoint for the Dynatrace logs ingestion"
  type        = string
  default     = "dynatrace/cc-cosmos-dt-cwl-logs-destination-endpoint"
}

variable "buffering_interval" {
  type        = number
  default     = 60
  description = "Buffering interval in seconds for Firehose HTTP endpoint"
}

variable "buffering_size" {
  type        = number
  default     = 1
  description = "Buffering size in MB for Firehose HTTP endpoint"
}

variable "retry_duration" {
  type        = number
  default     = 900
  description = "Retry duration in seconds for failed HTTP requests"
}

variable "ingestion_type" {
  description = "Type of ingestion, e.g., metrics or logs"
  type        = string
  default     = "logs"
}

variable "common_attributes" {
  type        = list(object({ name = string, value = string }))
  default     = []
  description = "Optional common attributes to attach to each record"
}

variable "log_retention_days" {
  type        = number
  default     = 1 #tbc but intentionally short retention as logs are exported to Dynatrace
  description = "CloudWatch log retention period"
}

variable "cloudwatch_log_group_name" {
  type        = string
  default     = "/aws/dynatrace_cwl"
  description = "CloudWatch log group name"
}

variable "destination_name" {
  description = "Name for the CloudWatch Logs destination"
  default     = "cc-cosmos-dynatrace-firehose"
  type        = string
}

variable "days_after_initiation" {
description = "Specifies the number of days after initiating a multipart upload when the multipart upload must be completed."
default = 15
type = number
}