variable "connection_name" {
  description = "Name of the Dynatrace Azure connection (the tenant_vars.azure_connections map key)."
  type        = string
}

variable "tenant_vars" {
  description = <<-EOT
    Per-connection configuration (non-identity fields only - application_id,
    directory_id, principal_object_id and client_secret come from AWS Secrets
    Manager, not here). Keys:
      consumers                   (optional, default []) e.g. ["SVC:com.dynatrace.da"].
      extension_version           (optional, default "1.1.8") com.dynatrace.extension.da-azure version.
      feature_sets                (optional, default: see locals.tf)
      regions                     (optional, default ["global"]) -> locationFiltering.
      subscription_filtering      (optional, default [])
      subscription_filtering_mode (optional, default "INCLUDE")
      tag_filters                 (optional, default [])
      tag_enrichment              (optional, default []) shape unconfirmed, distinct from security_context.
      security_context            (optional) e.g. { literal = "aiaas" } -> azure.dtLabelsEnrichment["dt.security_context"].
      deployment_scope            (optional, default "SUBSCRIPTION")
  EOT
  type        = any
}

variable "application_id" {
  description = "Application (client) ID of the Azure app registration. Sourced via TF_VAR from AWS Secrets Manager - never committed to tenant_vars.yaml."
  type        = string
  sensitive   = true

  validation {
    condition     = length(trimspace(var.application_id)) > 0
    error_message = "application_id must not be empty - check that TF_VAR_azure_connection_secrets/AWS Secrets Manager has a non-empty entry for this connection name."
  }
}

variable "directory_id" {
  description = "Directory (tenant) ID of Microsoft Entra ID. Sourced via TF_VAR from AWS Secrets Manager - never committed to tenant_vars.yaml."
  type        = string
  sensitive   = true

  validation {
    condition     = length(trimspace(var.directory_id)) > 0
    error_message = "directory_id must not be empty - check that TF_VAR_azure_connection_secrets/AWS Secrets Manager has a non-empty entry for this connection name."
  }
}

variable "principal_object_id" {
  description = "Object ID of the app's Service Principal (NOT application_id) - required by the monitoring configuration, not the connection itself. Null = connection only, no monitoring config. Sourced via TF_VAR from AWS Secrets Manager."
  type        = string
  default     = null
  sensitive   = true
}

variable "client_secret" {
  description = "Client secret of the Azure app registration. Sourced via TF_VAR from AWS Secrets Manager in the pipeline - never committed to tenant_vars.yaml."
  type        = string
  sensitive   = true

  validation {
    condition     = length(trimspace(var.client_secret)) > 0
    error_message = "client_secret must not be empty - check that TF_VAR_azure_connection_secrets/AWS Secrets Manager has a non-empty entry for this connection name, rather than silently sending an empty secret to Dynatrace."
  }
}
