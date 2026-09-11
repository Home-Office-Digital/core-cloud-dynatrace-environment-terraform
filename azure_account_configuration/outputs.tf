output "connection_id" {
  description = "Real resource ID of the Dynatrace Azure connection."
  value       = dynatrace_azure_connection.this.id
}

output "monitoring_config_id" {
  description = "Real resource ID of the monitoring configuration, or null if principal_object_id was not set."
  value       = try(dynatrace_hub_extension_v2_config.monitoring_config[0].id, null)
}
