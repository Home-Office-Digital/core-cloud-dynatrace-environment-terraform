resource "dynatrace_azure_connection" "this" {
  name = var.connection_name
  type = "clientSecret"

  client_secret {
    application_id = var.tenant_vars.application_id
    directory_id   = var.tenant_vars.directory_id
    client_secret  = var.client_secret
    consumers      = try(var.tenant_vars.consumers, [])
  }
}

# Region/tag/security-context scope is a SEPARATE resource from the connection
# above, not a Settings 2.0 object (no schemaId, plain UUID objectId) - it's
# an Extensions Framework 2.0 (EF2) "monitoring configuration" for the
# com.dynatrace.extension.da-azure extension, exposed via
# /api/v2/extensions/{name}/monitoringConfigurations and managed in Terraform
# by dynatrace_hub_extension_v2_config (name/scope/value, where value is a raw
# JSON string - see README for the confirmed shape).
# Gated on tenant_vars.principal_object_id being set (see README for why this
# field, not application_id, is what's required here) so tenants that only
# want the credential/connection object aren't forced to provide it. Checks
# for a non-null, non-blank value (not just key presence) - a null or empty
# principal_object_id would otherwise still create a monitoring config, just
# one Dynatrace would reject or misbehave on.
resource "dynatrace_hub_extension_v2_config" "monitoring_config" {
  count = local.monitoring_config_enabled ? 1 : 0

  name  = "com.dynatrace.extension.da-azure"
  scope = "integration-azure"

  value = jsonencode({
    enabled           = true
    description       = var.connection_name
    version           = try(var.tenant_vars.extension_version, "1.1.8")
    featureSets       = try(var.tenant_vars.feature_sets, local.default_azure_feature_sets)
    activationContext = "DATA_ACQUISITION"
    azure = merge(
      {
        credentials = [
          {
            description        = var.connection_name
            enabled            = true
            connectionId       = dynatrace_azure_connection.this.id
            servicePrincipalId = var.tenant_vars.application_id
            principalObjectId  = var.tenant_vars.principal_object_id
            type               = "SECRET"
          }
        ]
        locationFiltering         = try(var.tenant_vars.regions, ["global"])
        subscriptionFiltering     = try(var.tenant_vars.subscription_filtering, [])
        subscriptionFilteringMode = try(var.tenant_vars.subscription_filtering_mode, "INCLUDE")
        tagFiltering              = try(var.tenant_vars.tag_filters, [])
        tagEnrichment             = try(var.tenant_vars.tag_enrichment, [])
        useIngestEnrichmentConfig = false
        smartscapeConfiguration = {
          enabled = true
        }
        eventHubsConfiguration = []
        namespaces             = []
        manualDeploymentStatus = "NA"
        deploymentScope        = try(var.tenant_vars.deployment_scope, "SUBSCRIPTION")
      },
      # dt.security_context enrichment: tenant_vars.security_context is passed
      # through verbatim, expected shape { literal = "<value>" } (confirmed)
      # or { tagKey = "<key>" } (per Dynatrace's dtctl docs, not independently
      # confirmed). Field is omitted entirely (not even an empty object) when
      # tenant_vars doesn't set it, matching what a config with no enrichment
      # looks like.
      contains(keys(var.tenant_vars), "security_context") ? {
        dtLabelsEnrichment = {
          "dt.security_context" = var.tenant_vars.security_context
        }
      } : {}
    )
  })
}
