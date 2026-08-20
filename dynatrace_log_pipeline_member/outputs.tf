output "id" {
  value = dynatrace_openpipeline_v2_logs_pipelines.member.id
}

output "pipeline_custom_id" {
  value = dynatrace_openpipeline_v2_logs_pipelines.member.custom_id
}

output "pipeline_display_name" {
  value = dynatrace_openpipeline_v2_logs_pipelines.member.display_name
}

output "metric_rule_count" {
  value = length(var.metric_extraction_rules)
}
