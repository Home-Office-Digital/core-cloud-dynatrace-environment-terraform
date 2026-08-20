variable "display_name" {
  description = "Display name of the pipeline group"
  type        = string
}

variable "member_placeholder_position" {
  description = "Where the member placeholder sits relative to base_pipelines: \"before\" or \"after\" (default) - only observable for stages configured on both sides."
  type        = string
  default     = "after"

  validation {
    condition     = contains(["before", "after"], var.member_placeholder_position)
    error_message = "member_placeholder_position must be one of: before, after."
  }
}

variable "base_pipelines" {
  description = "Ordered list of base pipelines wrapped around the member placeholder (see member_placeholder_position); mandate_stages_type/mandate_stages control which of each base's stages actually run (\"includeAll\" recommended for a base)."

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
    # mandate_stages is ignored when mandate_stages_type is "includeAll".
    condition     = alltrue([for base_pipeline in var.base_pipelines : base_pipeline.mandate_stages_type == "includeAll" || length(base_pipeline.mandate_stages) > 0])
    error_message = "Every base_pipelines entry must set mandate_stages, unless mandate_stages_type is \"includeAll\"."
  }
}

variable "member_stages_type" {
  description = "Restriction mode for stages members may run: \"include\" (recommended, allow-list), \"exclude\" (deny-list), or \"includeAll\" (no restriction - defeats the governance purpose, use deliberately)."
  type        = string
  default     = "include"

  validation {
    condition     = contains(["include", "exclude", "includeAll"], var.member_stages_type)
    error_message = "member_stages_type must be one of: include, exclude, includeAll."
  }
}

variable "member_stages_include" {
  description = "Stages members may run, when member_stages_type = \"include\" - anything else is locked out regardless of a member's own config."
  type        = list(string)
  default     = []
}

variable "member_stages_exclude" {
  description = "Stages member pipelines may NOT run, when member_stages_type = \"exclude\"."
  type        = list(string)
  default     = []
}

variable "member_pipeline_ids" {
  description = "IDs of member pipelines wrapped by this group in addition to default_member; must be non-empty if create_default_member is false, since the group needs at least one member to be reachable."
  type        = list(string)
  default     = []
}

variable "create_default_member" {
  description = "Whether this module creates its own internal catch-all member pipeline (default_member_*) - set false once real member_pipeline_ids exist and it's no longer needed (see main.tf check blocks)."
  type        = bool
  default     = true
}

variable "default_member_custom_id" {
  description = "custom_id for the internally-created catch-all member pipeline; required only when create_default_member is true."
  type        = string
  default     = null
}

variable "default_member_display_name" {
  description = "Display name for the internally-created default member pipeline; required only when create_default_member is true."
  type        = string
  default     = null
}

variable "default_member_metric_extraction_rules" {
  description = "Optional metric-extraction rules for the default member pipeline; empty by default since it exists purely as the entry point, not for self-service metrics."

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
