variable "allow_manage_existing_routing" {
  description = "Safety gate for first-time adoption of the existing dynamic routing table. Keep false until the resource has been imported and the plan has been reviewed for entry drift. This resource replaces the ENTIRE routing table on every apply."
  type        = bool
  default     = false
}

variable "routes" {
  description = "Ordered list of dynamic routing entries, highest priority first. Must reproduce every *manageable* entry currently live in the tenant's routing table - applying with a partial list deletes the missing entries. Does NOT include platform-injected fallbacks like the Classic pipeline's \"Default route\" - that has no routing_entry representation at all and must not be declared here. See the module README."

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

  validation {
    condition     = alltrue([for r in var.routes : r.pipeline_type != "custom" || r.pipeline_id != null])
    error_message = "Every route with pipeline_type = \"custom\" must set pipeline_id."
  }

  validation {
    condition     = alltrue([for r in var.routes : r.pipeline_type != "builtin" || r.builtin_pipeline_id != null])
    error_message = "Every route with pipeline_type = \"builtin\" must set builtin_pipeline_id."
  }
}
