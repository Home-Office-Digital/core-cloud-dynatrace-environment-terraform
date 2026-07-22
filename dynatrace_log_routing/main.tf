resource "dynatrace_openpipeline_v2_logs_routing" "routing" {
  lifecycle {
    precondition {
      condition     = var.allow_manage_existing_routing
      error_message = "Set allow_manage_existing_routing=true only after importing the routing table and reviewing plan output for entry drift."
    }
  }

  routing_entries {
    dynamic "routing_entry" {
      for_each = var.routes
      content {
        description         = routing_entry.value.description
        enabled             = routing_entry.value.enabled
        matcher             = routing_entry.value.matcher
        pipeline_type       = routing_entry.value.pipeline_type
        builtin_pipeline_id = routing_entry.value.builtin_pipeline_id
        pipeline_id         = routing_entry.value.pipeline_id
      }
    }
  }
}
