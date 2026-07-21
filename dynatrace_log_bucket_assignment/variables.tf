variable "pipeline_custom_id" {
  description = "The custom_id of the existing Dynatrace OpenPipeline logs pipeline to manage (e.g. the tenant's base logs pipeline). This pipeline must already exist and be imported before first apply - see module README."
  type        = string
}

variable "allow_manage_existing_pipeline" {
  description = "Safety gate for first-time adoption on existing pipelines. Keep false until the pipeline has been imported and the plan has been reviewed for stage drift."
  type        = bool
  default     = false
}

variable "pipeline_display_name" {
  description = "Display name of the pipeline"
  type        = string
}

variable "group_role" {
  description = "Role of the pipeline within the OpenPipeline group"
  type        = string
  default     = "basePipeline"

  validation {
    condition     = contains(["basePipeline", "compositionPipeline", "memberPipeline"], var.group_role)
    error_message = "group_role must be one of: basePipeline, compositionPipeline, memberPipeline."
  }
}

variable "routing" {
  description = "Routing mode for the pipeline. Left unset (null) by default so existing routing configuration is not overridden."
  type        = string
  default     = null

  validation {
    condition     = var.routing == null || contains(["notRoutable", "routable"], var.routing)
    error_message = "routing must be one of: notRoutable, routable."
  }
}

variable "rules" {
  description = "Ordered list of bucket-assignment rules for the pipeline's storage stage. Order matters (first match wins) - include a catch-all entry (matcher = \"true\") last."

  type = list(object({
    id          = string
    description = optional(string, "")
    enabled     = optional(bool, true)
    matcher     = string
    bucket_name = string
  }))

  validation {
    condition     = length(var.rules) > 0
    error_message = "rules must contain at least one bucket-assignment processor."
  }

  validation {
    condition     = trimspace(lower(var.rules[length(var.rules) - 1].matcher)) == "true"
    error_message = "The last rules entry must be a catch-all with matcher = \"true\"."
  }
}

variable "security_context_rules" {
  description = "Ordered list of security-context rules for the pipeline's security_context stage. Leave empty to avoid managing this stage."

  type = list(object({
    id                = string
    description       = optional(string, "")
    enabled           = optional(bool, true)
    matcher           = string
    source_field_name = string
  }))

  default = []
}

variable "enforce_tier1_only_active" {
  description = "When true, any rule whose id does not match tier1_rule_id_regex must be disabled. Useful for transition phases where only tier1 routing is active."
  type        = bool
  default     = false
}

variable "tier1_rule_id_regex" {
  description = "Regex used to identify tier1 rules by id when enforce_tier1_only_active is true."
  type        = string
  default     = "tier1"

  validation {
    condition     = can(regex(var.tier1_rule_id_regex, "tier1"))
    error_message = "tier1_rule_id_regex must be a valid regex expression."
  }
}

locals {
  # The catch-all rule (matcher = "true", enforced by the rules validation above to always
  # be present as the last entry) is exempt - it's not tier-scoped, so its id will never
  # match tier1_rule_id_regex, and it's expected to stay enabled regardless of enforcement.
  non_tier1_enabled_rule_ids = [
    for rule in var.rules : rule.id
    if !can(regex(var.tier1_rule_id_regex, rule.id))
    && rule.enabled
    && trimspace(lower(rule.matcher)) != "true"
  ]
}

check "non_tier1_rules_must_be_disabled" {
  assert {
    condition     = !var.enforce_tier1_only_active || length(local.non_tier1_enabled_rule_ids) == 0
    error_message = "enforce_tier1_only_active is true, but some non-tier1 rules are enabled: ${join(", ", local.non_tier1_enabled_rule_ids)}"
  }
}
