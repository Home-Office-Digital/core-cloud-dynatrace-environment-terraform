variable "display_name" {
  description = "Display name of the pipeline group"
  type        = string
}

variable "member_placeholder_position" {
  description = "Where the member pipeline placeholder sits relative to base_pipelines in the composition order: \"before\" (member runs first, then base pipelines) or \"after\" (base pipelines run first, then the routed member - the default). Only matters for stage types configured on BOTH a base pipeline and a member pipeline (e.g. \"processing\", if member_stages allows it) - that's the only case where which one runs first is observable."
  type        = string
  default     = "after"

  validation {
    condition     = contains(["before", "after"], var.member_placeholder_position)
    error_message = "member_placeholder_position must be one of: before, after."
  }
}

variable "base_pipelines" {
  description = "Ordered list of base pipelines wrapped around the member pipeline placeholder. Order matters - entries run in list order, all on the same side of the placeholder (see member_placeholder_position for which side). mandate_stages_type controls how much of each base pipeline's own config actually runs as part of this composition: \"includeAll\" (recommended for a base - unrestricted, every stage the pipeline has configured runs) or \"include\"/\"exclude\" to narrow it to specific stages via mandate_stages."

  type = list(object({
    pipeline_id         = string
    mandate_stages_type = optional(string, "include")
    mandate_stages      = optional(list(string), [])
  }))

  default = []

  validation {
    condition     = alltrue([for base_pipeline in var.base_pipelines : contains(["include", "exclude", "includeAll"], base_pipeline.mandate_stages_type)])
    error_message = "Every base_pipelines entry's mandate_stages_type must be one of: include, exclude, includeAll."
  }

  validation {
    # mandate_stages is meaningless (and ignored) when mandate_stages_type is
    # "includeAll" - only require it to be non-empty for include/exclude.
    condition     = alltrue([for base_pipeline in var.base_pipelines : base_pipeline.mandate_stages_type == "includeAll" || length(base_pipeline.mandate_stages) > 0])
    error_message = "Every base_pipelines entry must set mandate_stages, unless mandate_stages_type is \"includeAll\"."
  }
}

variable "member_stages_type" {
  description = "Restriction mode for stages member pipelines are allowed to run. \"include\" (recommended) allow-lists specific stages - everything else is locked out regardless of what a member pipeline configures. \"exclude\" deny-lists specific stages. \"includeAll\" leaves every stage available to members (no restriction - defeats the governance purpose of a group, use deliberately)."
  type        = string
  default     = "include"

  validation {
    condition     = contains(["include", "exclude", "includeAll"], var.member_stages_type)
    error_message = "member_stages_type must be one of: include, exclude, includeAll."
  }
}

variable "member_stages_include" {
  description = "Stages member pipelines may run, when member_stages_type = \"include\". Any stage not listed here cannot be executed by a member pipeline, no matter what that pipeline's own config contains."
  type        = list(string)
  default     = []
}

variable "member_stages_exclude" {
  description = "Stages member pipelines may NOT run, when member_stages_type = \"exclude\"."
  type        = list(string)
  default     = []
}

variable "member_pipeline_ids" {
  description = "IDs of member pipelines wrapped by this group, in addition to the internally-created default_member (if create_default_member is true). Compute this from module.dynatrace_log_pipeline_member[*].id outputs rather than hard-coding. Must be non-empty if create_default_member is false - the group needs at least one member from somewhere to be reachable at all (a base pipeline can never be routed to directly)."
  type        = list(string)
  default     = []
}

variable "create_default_member" {
  description = "Whether this module creates its own internal catch-all member pipeline (default_member_*). Useful when nothing else guarantees the group has at least one member yet. Set false once real, explicitly-declared member pipelines exist (via member_pipeline_ids) and the internal one is no longer needed. Cross-checked against member_pipeline_ids and the default_member_* variables via check blocks in main.tf, not here - validation blocks can only reference the variable they're declared on unless the module requires Terraform >= 1.9, and this one only requires >= 1.5.0 (see root versions.tf)."
  type        = bool
  default     = true
}

variable "default_member_custom_id" {
  description = "custom_id for the internally-created catch-all member pipeline. Required only when create_default_member is true - see the check block in main.tf."
  type        = string
  default     = null
}

variable "default_member_display_name" {
  description = "Display name for the internally-created default member pipeline. Required only when create_default_member is true - see the check block in main.tf."
  type        = string
  default     = null
}

variable "default_member_metric_extraction_rules" {
  description = "Optional metric-extraction rules for the default member pipeline. Left empty by default - this pipeline exists purely as the mandatory entry point into the group's base pipeline(s), not for self-service metrics. Add rules here, or declare additional named member pipelines via member_pipeline_ids, once that's actually needed."

  type = list(object({
    id          = string
    description = optional(string, "")
    enabled     = optional(bool, true)
    matcher     = string
    type        = string

    metric_key    = string
    field         = optional(string)
    default_value = optional(number)

    dimensions = optional(list(object({
      extraction_type        = optional(string, "field")
      strategy               = optional(string, "equals")
      source_field_name      = string
      destination_field_name = optional(string)
    })), [])
  }))

  default = []
}
