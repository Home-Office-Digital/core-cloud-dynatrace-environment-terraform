variable "name" {
  description = "The name / id of the bucket definition"
  type        = string
}

variable "retention" {
  description = "The retention of stored data in days"
  type        = number
}

variable "table" {
  description = "The Grail table this bucket applies to"
  type        = string
  default     = "logs"

  validation {
    condition     = contains(["logs", "spans", "events", "bizevents"], var.table)
    error_message = "table must be one of: logs, spans, events, bizevents."
  }
}

variable "display_name" {
  description = "Optional friendly display name shown in the UI"
  type        = string
  default     = null
}
