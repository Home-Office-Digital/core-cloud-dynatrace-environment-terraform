variable "connection_name" {
  description = "Name of the Dynatrace Azure connection (the tenant_vars.azure_connections map key)."
  type        = string
}

variable "tenant_vars" {
  description = <<-EOT
    Per-connection configuration. Expected keys:
      application_id          (string, required) Application (client) ID of the Azure app registration.
      directory_id            (string, required) Directory (tenant) ID of Microsoft Entra ID.
      consumers               (list(string), optional) Dynatrace integrations allowed to use this connection.
                               Possible values: "SVC:com.dynatrace.da". Defaults to [].
      principal_object_id     (string, optional) Object ID of the app's Service Principal (NOT the
                               application_id) - required by the monitoring configuration, not the
                               connection itself. Leave unset to create only the connection/credential
                               object, with no monitoring configuration (no entities/metrics ingested).
      extension_version       (string, optional) Version of the com.dynatrace.extension.da-azure
                               extension active in the target environment. Defaults to "1.1.8" - verify
                               against the target environment before relying on the default (see README).
      feature_sets            (list(string), optional) Azure service feature sets to monitor. Defaults to
                               a broad built-in list - see locals.tf.
      regions                 (list(string), optional) Azure regions to monitor (locationFiltering).
                               Defaults to ["global"].
      subscription_filtering  (list(string), optional) Subscription IDs to include/exclude. Defaults to [].
      subscription_filtering_mode (string, optional) "INCLUDE" or "EXCLUDE". Defaults to "INCLUDE".
      tag_filters             (list, optional) Tag-based scoping of monitored resources. Defaults to [].
      tag_enrichment          (list, optional) Distinct from security_context below. Shape unconfirmed -
                               defaults to [].
      security_context        (object, optional) dt.security_context enrichment, passed through verbatim
                               into azure.dtLabelsEnrichment["dt.security_context"]. Confirmed shape for a
                               literal value: { literal = "<value>" }. Omitted entirely (not even an empty
                               object) when unset. See README for the tagKey variant caveat.
      deployment_scope        (string, optional) "MANAGEMENT_GROUP" or "SUBSCRIPTION". Defaults to
                               "SUBSCRIPTION" - this ticket's confirmed real use case (management-group
                               level is explicitly a separate, unexplored future initiative per the ticket).
  EOT
  type        = any
}

variable "client_secret" {
  description = "Client secret of the Azure app registration. Sourced via TF_VAR from AWS Secrets Manager in the pipeline - never committed to tenant_vars.yaml."
  type        = string
  sensitive   = true

  validation {
    condition     = length(trimspace(var.client_secret)) > 0
    error_message = "client_secret must not be empty - check that TF_VAR_azure_client_secrets/AWS Secrets Manager has a non-empty entry for this connection name, rather than silently sending an empty secret to Dynatrace."
  }
}
