resource "dynatrace_azure_connection" "this" {
  name = var.connection_name
  type = "clientSecret"

  client_secret {
    application_id = var.application_id
    directory_id   = var.directory_id
    client_secret  = var.client_secret
    consumers      = try(var.tenant_vars.consumers, [])
  }
}

# EF2 config, not a Settings 2.0 object - see README for the value shape.
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
            servicePrincipalId = var.application_id
            principalObjectId  = var.principal_object_id
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
      # dt.security_context lives under dtLabelsEnrichment, not tagEnrichment.
      contains(keys(var.tenant_vars), "security_context") ? {
        dtLabelsEnrichment = {
          "dt.security_context" = var.tenant_vars.security_context
        }
      } : {}
    )
  })
}
