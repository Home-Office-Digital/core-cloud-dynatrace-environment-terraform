output "id" {
  value = dynatrace_openpipeline_v2_logs_pipelines.log_bucket_assignment.id
}

output "pipeline_custom_id" {
  value = dynatrace_openpipeline_v2_logs_pipelines.log_bucket_assignment.custom_id
}

output "pipeline_display_name" {
  value = dynatrace_openpipeline_v2_logs_pipelines.log_bucket_assignment.display_name
}

output "rule_count" {
  value = length(var.rules)
}
