variable "launchpad_name" {
  description = "Display name of the launchpad document."
  type        = string
}

variable "launchpad_content" {
  description = "Launchpad document content as a Terraform/YAML object that can be JSON-encoded for dynatrace_document."
  type        = any

  validation {
    condition     = var.launchpad_content != null && can(jsonencode(var.launchpad_content))
    error_message = "launchpad_content must be a non-null JSON-serializable value."
  }
}

variable "launchpad_custom_id" {
  description = "Optional stable custom id for the launchpad document."
  type        = string
  default     = null
}

variable "launchpad_private" {
  description = "Whether the launchpad document should be private."
  type        = bool
  default     = null
}
