variable "allow_manage_existing_routing" {
  description = "Safety gate for first-time adoption of the existing dynamic routing table. Keep false until the resource has been imported and the plan has been reviewed for entry drift. This resource replaces the ENTIRE routing table on every apply."
  type        = bool
  default     = false
}

variable "routes" {
  description = "Ordered list of dynamic routing entries, highest priority first. Must reproduce every entry currently live in the tenant's routing table, including built-in ones (e.g. the Classic pipeline's Default route) - applying with a partial list deletes the missing entries."

  type = list(object({
    description         = string
    enabled             = optional(bool, true)
    matcher             = string
    pipeline_type       = string
    builtin_pipeline_id = optional(string)
    pipeline_id         = optional(string)
  }))

  validation {
    condition     = length(var.routes) > 0
    error_message = "routes must contain at least one routing entry."
  }

  validation {
    condition     = alltrue([for r in var.routes : contains(["builtin", "custom"], r.pipeline_type)])
    error_message = "pipeline_type must be one of: builtin, custom."
  }
}
