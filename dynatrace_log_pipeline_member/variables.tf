variable "custom_id" {
  description = "The custom_id of the member pipeline to manage. Immutable - changing it forces destroy/recreate (see module README)."
  type        = string
}

variable "display_name" {
  description = "Display name of the member pipeline"
  type        = string
}

variable "metric_extraction_rules" {
  description = "Ordered list of metric-extraction processors - the only stage this module exposes (governance is enforced by the pipeline group's member_stages, see dynatrace_log_pipeline_group)."

  type = list(object({
    id          = string
    description = optional(string, "")
    enabled     = optional(bool, true)
    matcher     = string
    # "counterMetric" or "valueMetric"
    type = string

    metric_key = string
    # valueMetric only: field to read the metric value from
    field = optional(string)
    # valueMetric only: value to use when `field` is absent on a record
    default_value = optional(number)

    dimensions = optional(list(object({
      extraction_type        = optional(string, "field")
      strategy               = optional(string, "equals")
      source_field_name      = string
      destination_field_name = optional(string)
    })), [])
  }))

  default = []

  validation {
    condition     = alltrue([for rule in var.metric_extraction_rules : contains(["counterMetric", "valueMetric"], rule.type)])
    error_message = "metric_extraction_rules[*].type must be one of: counterMetric, valueMetric."
  }

  validation {
    # valueMetric needs a source field to read; counterMetric just counts matching records.
    condition     = alltrue([for rule in var.metric_extraction_rules : rule.type != "valueMetric" || rule.field != null])
    error_message = "Every metric_extraction_rules entry with type = \"valueMetric\" must set field."
  }
}
