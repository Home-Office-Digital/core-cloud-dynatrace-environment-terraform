output "id" {
  value = dynatrace_openpipeline_v2_logs_pipelinegroups.group.id
}

output "default_member_pipeline_id" {
  description = "Real id of the internally-created default member pipeline, or null if create_default_member is false. Route dynatrace_log_routing's fallback entry here when non-null, since a base pipeline can never be routed to directly."
  value       = var.create_default_member ? module.default_member[0].id : null
}

output "member_pipeline_count" {
  value = length(var.member_pipeline_ids) + (var.create_default_member ? 1 : 0)
}
