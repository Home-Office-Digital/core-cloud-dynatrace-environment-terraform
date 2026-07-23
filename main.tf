locals {
  default_services = yamldecode(file("default_metrics.yaml"))
  # Enable/disable check for corecloud_alerts module
  corecloud_alerts_enabled = (
    contains(keys(var.tenant_vars), "corecloud_alerts") &&
    try(contains(keys(var.tenant_vars.corecloud_alerts), "corecloud_alert_configs"), false) &&
    try(var.tenant_vars.corecloud_alerts.corecloud_alert_configs != null, false) &&
    try(contains(keys(var.tenant_vars.corecloud_alerts), "corecloud_profile_alerting_rules"), false) &&
    try(var.tenant_vars.corecloud_alerts.corecloud_profile_alerting_rules != null, false)
  )
}

module "aws_account_configurations" {
  source           = "./aws_account_configuration"
  for_each         = var.tenant_vars.aws_connections
  tenant_vars      = each.value
  connection_name  = each.key
  default_services = local.default_services
}

module "dynatrace_generic_types" {
  count  = contains(keys(var.tenant_vars), "generic_types") ? 1 : 0
  source = "./dynatrace_generic_types"
}

module "dynatrace_management_zones" {
  source = "./dynatrace_management_zones"

  for_each   = var.tenant_vars.management_zones
  project_id = var.tenant_vars.project_id
  # Create one management zone per named entry under the "management_zones" block of the config.yaml
  zone_vars = each.value
  # Value is the attribute/parameter content of each named entry
  zone_name = each.key
  # Name reference for the zone within config yaml is used as the literal name of the MZ to be created
}

module "ghes_alerts" {
  source = "./alerts/ghes"
  count  = contains(keys(var.tenant_vars), "ghes_alert") ? 1 : 0
  ghes_alert_configs = contains(keys(var.tenant_vars.ghes_alert), "ghes_alert_configs"
    ) && var.tenant_vars.ghes_alert.ghes_alert_configs != null ? tomap(var.tenant_vars.ghes_alert.ghes_alert_configs
  ) : tomap({})
  bcp_alerting = contains(keys(var.tenant_vars.ghes_alert), "bcp_alerting") ? var.tenant_vars.ghes_alert.bcp_alerting : {
    enabled               = false
    alerting_profile_name = ""
    include_mode          = ""
    delay_in_minutes      = 0
    tag_key               = ""
    tag_value             = ""
    email_name            = ""
    email_subject         = ""
    email_to              = []
  }
  slack_webhook_urls = var.slack_webhook_urls
}


module "metric_events" {
  source = "./metric_events"
  count = (contains(keys(var.tenant_vars), "metric_events"
    ) && contains(keys(var.tenant_vars.metric_events), "common_metric_values"
    ) && contains(keys(var.tenant_vars.metric_events), "metrics"
  ) && var.tenant_vars.metric_events.common_metric_values != null && var.tenant_vars.metric_events.metrics != null) ? 1 : 0
  common_metrics_vars = var.tenant_vars.metric_events.common_metric_values
  metrics_vars        = var.tenant_vars.metric_events.metrics
  metric_stream_vars  = var.tenant_vars.metric_events.metric_stream_values
  s3_error_vars       = var.tenant_vars.metric_events.s3_error_values
  tag_audit_lambda    = try(var.tenant_vars.metric_events.tag_audit_lambda, null)
}

module "ghes_dashboards" {
  source        = "./dashboards/ghes_dashboards"
  count         = contains(keys(var.tenant_vars), "ghes_dashboard_hostname") ? 1 : 0
  ghes_hostname = var.tenant_vars.ghes_dashboard_hostname
  # dt_admin_group_name = var.tenant_vars.dt_admin_group_name
  dt_admin_group_id = var.tenant_vars.dt_admin_group_id
}

module "dynatrace_privatelink_aws_accounts_allowlist" {
  source       = "./dynatrace_privatelink_aws_accounts_allowlist"
  count        = contains(keys(var.tenant_vars), "privatelink_allowlist_aws_accounts") ? 1 : 0
  aws_accounts = var.tenant_vars.privatelink_allowlist_aws_accounts
}

module "golden_dashboards" {
  count  = contains(keys(var.tenant_vars), "golden_dashboards") ? 1 : 0
  source = "./dashboards/golden_dashboards"
}

module "aws_secrets" {
  source      = "git::https://github.com/Home-Office-Digital/core-cloud-aws-secrets-terraform.git?ref=1.0.1"
  count       = contains(keys(var.tenant_vars), "aws_secrets") ? 1 : 0
  aws_secrets = var.tenant_vars.aws_secrets
}

module "dynatrace_servicenow_integration" {
  source = "./dynatrace_servicenow_integration"
  count = contains(
    keys(var.tenant_vars),
    "servicenow_integration"
  ) ? 1 : 0

  SERVICENOW_END_POINT     = var.SERVICENOW_END_POINT
  SERVICENOW_ENV_ID        = var.SERVICENOW_ENV_ID
  SERVICENOW_CLIENT_ID     = var.SERVICENOW_CLIENT_ID
  SERVICENOW_CLIENT_SECRET = var.SERVICENOW_CLIENT_SECRET

  management_zone = try(var.tenant_vars.servicenow_integration.management_zone, null)
  servicenow_payload = contains(
    keys(var.tenant_vars.servicenow_integration),
    "servicenow_payload"
  ) ? var.tenant_vars.servicenow_integration.servicenow_payload : tomap({})

  servicenow_alerting_rules = contains(
    keys(var.tenant_vars.servicenow_integration),
    "servicenow_alerting_profile_rules"
  ) ? tomap(var.tenant_vars.servicenow_integration.servicenow_alerting_profile_rules) : tomap({})

  accept_any_cert = contains(
    keys(var.tenant_vars.servicenow_integration),
    "accept_any_cert"
  ) ? var.tenant_vars.servicenow_integration.accept_any_cert : "true"

  notify_event_merges = contains(
    keys(var.tenant_vars.servicenow_integration),
    "notify_event_merges"
  ) ? var.tenant_vars.servicenow_integration.notify_event_merges : "true"

  notify_closed_problems = contains(
    keys(var.tenant_vars.servicenow_integration),
    "notify_closed_problems"
  ) ? var.tenant_vars.servicenow_integration.notify_closed_problems : "true"

  snow_integration_state = contains(
    keys(var.tenant_vars.servicenow_integration),
    "snow_integration_state"
  ) ? var.tenant_vars.servicenow_integration.snow_integration_state : "false"
}

module "dynatrace_aws_monitoring_profile_integration" {
  source = "./alerts/aws_monitoring_profile"
  count = contains(
    keys(var.tenant_vars),
    "aws_monitoring_profile_integration"
  ) ? 1 : 0

  aws_monitoring_profile_alerting_rules = contains(
    keys(var.tenant_vars.aws_monitoring_profile_integration),
    "aws_monitoring_profile_rules"
  ) ? tomap(var.tenant_vars.aws_monitoring_profile.aws_monitoring_profile_rules) : tomap({})

  aws_monitoring_profile_alert_config = var.tenant_vars.aws_monitoring_profile_integration
  slack_webhook_url                   = var.slack_webhook_urls["aws_monitoring_profile"]
}

module "anomaly_detection" {
  count  = contains(keys(var.tenant_vars), "anomaly_detection") ? 1 : 0
  source = "./anomaly_detection/"
}


module "dynatrace_log_storage_rules" {
  count  = contains(keys(var.tenant_vars), "dynatrace_log_storage_rules") ? 1 : 0
  source = "./dynatrace_log_storage"

  rules = [
    {
      # ordering is important here, as rules are processed in order and the first matching rule is applied, so this rule must be before the include-all rule in the list.
      name            = "exclude-pods-dynatrace-logs-false"
      enabled         = true
      send_to_storage = false
      matchers = [
        {
          attribute = "k8s.pod.label"
          values    = ["dynatrace-logs=false"]
        }
      ]
    },
    {
      # catch-all rule to include logs for pods that do have the dynatrace-logs label set to true, or where the label is not set at all.
      # this rule must be last in the list.
      name            = "include-all"
      enabled         = true
      send_to_storage = true
      matchers        = [] # catch-all rule
    }
  ]
}

module "web_application" {
  source               = "./web_applications/"
  for_each             = contains(keys(var.tenant_vars), "web_applications") ? var.tenant_vars.web_applications : {}
  project_id           = var.tenant_vars.project_id
  service_id           = each.value.service_id
  application_id       = each.value.application_id
  environment_type     = each.value.environment_type
  web_application_name = each.value.name
  web_application_type = each.value.type
  rum_enabled          = each.value.rum_enabled
  matcher              = each.value.matcher
  pattern              = each.value.pattern
  description          = try(each.value.description, "")
}

module "dynatrace_corecloud_alerts" {
  source                           = "./alerts/corecloud"
  count                            = local.corecloud_alerts_enabled ? 1 : 0
  corecloud_alert_configs          = try(var.tenant_vars.corecloud_alerts.corecloud_alert_configs, null)
  corecloud_profile_alerting_rules = try(var.tenant_vars.corecloud_alerts.corecloud_profile_alerting_rules, null)
  slack_webhook_urls               = var.slack_webhook_urls
}

module "dynatrace_kafka_settings" {
  source        = "./settings/kafka"
  count         = contains(keys(var.tenant_vars), "kafka_settings") ? 1 : 0
  enabled       = try(var.tenant_vars.kafka_settings.enabled, false)
  kafka_streams = try(var.tenant_vars.kafka_settings.kafka_streams, false)
}

module "dynatrace_kubernetes_enrichment" {
  count  = contains(keys(var.tenant_vars), "kubernetes_enrichment") ? 1 : 0
  source = "./settings/kubernetes_enrichment"
}

module "hub_extensions" {

  source   = "./hub_extensions"
  for_each = { for k, v in try(var.tenant_vars.hub_extensions, {}) : k => v if v != null }

  tenant_vars  = each.value
  extn_version = each.value.extn_version

  # Optional scoping
  management_zone   = try(each.value.management_zone, null)
  host_group        = try(each.value.host_group, null)
  host              = try(each.value.host, null)
  active_gate_group = try(each.value.active_gate_group, null)
  #end of optional scoping

  description       = try(each.value.description, "")
  featureSets       = try(each.value.featureSets, null)
  extension_name    = each.value.extension_name
  enabled           = try(each.value.enabled, true)
  activationTags    = try(each.value.activationTags, ["[AWS]dynatrace: true"])
  activationContext = try(each.value.activationContext, "LOCAL")

  # Python certificate monitor specific attributes
  check_hosts            = try(each.value.check_hosts, null)
  port_range             = try(each.value.port_range, null)
  additional_sni         = try(each.value.additional_sni, null)
  debug                  = try(each.value.debug, null)
  enable_ua_and_metrics  = try(each.value.enable_ua_and_metrics, null)
  alerting_configuration = try(each.value.alerting_configuration, null)
  filter_technologies    = try(each.value.filter_technologies, null)
  log_event_interval     = try(each.value.log_event_interval, null)
}

module "oam_sink" {
  source   = "./oam_sink/"
  for_each = contains(keys(var.tenant_vars), "oam_sink") ? var.tenant_vars.oam_sink : {}

  tenant_vars = each.value
  org_id      = each.value.org_id
  sink_name   = each.value.sink_name
  ou_paths    = each.value.ou_paths
}

module "metric_stream" {
  source   = "./metric_stream/"
  for_each = contains(keys(var.tenant_vars), "metric_stream") ? var.tenant_vars.metric_stream : {}

  tenant_vars                     = each.value
  output_format                   = each.value.output_format
  env_name                        = each.value.env_name
  metrics_stream_name             = each.value.metrics_stream_name
  include_linked_accounts_metrics = each.value.include_linked_accounts_metrics
  firehose_arn                    = module.aws_cwl_s3_bucket[var.tenant_vars.metric_stream_to_firehose_map[each.key]].firehose_stream_arn
  include_filter                  = try(each.value.include_filter, {})
  exclude_filter                  = try(each.value.exclude_filter, {})


}

module "aws_cwl_s3_bucket" {
  source                                        = "./aws_cwl_cwm"
  for_each                                      = try(var.tenant_vars.aws_cwl_cwm, {})
  tags                                          = each.value.tags
  lifecycle_expiration_days                     = each.value.lifecycle_expiration_days
  days_after_initiation                         = each.value.days_after_initiation
  failed_delivery_sqs_message_retention_seconds = try(each.value.failed_delivery_sqs_message_retention_seconds, null)
  lambda_zip_output_path                        = "${dirname(var.terragrunt_dir)}/lambda-artifacts/${each.key}-${basename(var.terragrunt_dir)}-cwl-failed-delivery-replay.zip"
  ingestion_type                                = each.value.ingestion_type
}

module "monitoring_k8s_clusters" {
  source          = "./monitoring"
  count           = contains(keys(var.tenant_vars), "k8s_monitoring_config") ? 1 : 0
  metrics_enabled = var.tenant_vars.k8s_monitoring_config.enabled
  event_patterns  = var.tenant_vars.k8s_monitoring_config.event_patterns
}

module "platform_dashboards" {
  source = "./dashboards/platform_dashboards"
  #var.tenant_vars.platform_dashboards.enabled: true is the toggle
  for_each = { for file in local.files : file => file }
  filename = each.key
  #mandatory if enabled with var.tenant_vars.platform_dashboards hence no checks
  groups_to_share = var.tenant_vars.platform_dashboards.groups
}

module "dynatrace_platform_buckets" {
  source = "./dynatrace_platform_buckets"

  for_each = contains(keys(var.tenant_vars), "platform_buckets") ? var.tenant_vars.platform_buckets : {}

  name         = each.key
  retention    = each.value.retention
  display_name = try(each.value.display_name, null)
}

# The count -> for_each moved block that used to live here is retired: state
# has been on module.dynatrace_log_bucket_assignment["platform"] since that
# migration applied, so a "from = ...[0]" block would now be permanently inert
# everywhere. This one replaces it for the module's rename to dynatrace_log_pipeline
# (dynatrace_log_bucket_assignment was a misleading name - it owns the whole
# pipeline resource, not just its bucket-assignment rules). from must stay as
# the OLD module name here - it's the address actually in state right now,
# not something to rename along with everything else.
moved {
  from = module.dynatrace_log_bucket_assignment
  to   = module.dynatrace_log_pipeline
}

module "dynatrace_log_pipeline" {
  source = "./dynatrace_log_pipeline"

  # Keyed by category (e.g. "platform", "security") - one pipeline per key.
  # Each category owns its own pipeline stages independently; the only thing
  # shared across categories is the single tenant-wide routing table below.
  for_each = try(var.tenant_vars.log_pipeline, {})

  pipeline_custom_id             = each.value.pipeline_custom_id
  pipeline_display_name          = each.value.pipeline_display_name
  group_role                     = try(each.value.group_role, "basePipeline")
  routing                        = try(each.value.routing, null)
  allow_manage_existing_pipeline = try(each.value.allow_manage_existing_pipeline, false)
  enforce_tier1_only_active      = try(each.value.enforce_tier1_only_active, false)
  tier1_rule_id_regex            = try(each.value.tier1_rule_id_regex, "tier1")
  security_context_rules         = try(each.value.security_context_rules, [])
  rules                          = each.value.rules
}

check "log_routing_requires_log_pipeline" {
  assert {
    condition = (
      !contains(keys(var.tenant_vars), "log_routing") ||
      contains(keys(var.tenant_vars), "log_pipeline")
    )
    error_message = "tenant_vars.log_routing is set without tenant_vars.log_pipeline. dynatrace_log_routing's own route entries are computed from module.dynatrace_log_pipeline's outputs, so it can't be enabled on its own."
  }
}

check "log_pipeline_categories_need_distinct_matchers" {
  assert {
    # Every category needs a real routing_matcher once there's more than one -
    # two categories both left at the "true" catch-all default means only the
    # first (alphabetically, since map keys drive apply order) ever fires and
    # the rest are silently unreachable.
    condition = (
      length(keys(try(var.tenant_vars.log_pipeline, {}))) <= 1 ||
      length([
        for k, v in try(var.tenant_vars.log_pipeline, {}) : k
        if trimspace(lower(try(v.routing_matcher, "true"))) == "true"
      ]) <= 1
    )
    error_message = "More than one log_pipeline category is left on the default routing_matcher (\"true\"). Only the first ever matches - give every category beyond one a real, distinguishing routing_matcher."
  }
}

check "log_pipeline_custom_ids_must_be_unique" {
  assert {
    # pipeline_custom_id is chosen per-category by whoever adds it, not derived
    # from the category key - nothing else stops two categories colliding on
    # the same id, which would otherwise only surface as an API error at apply
    # time against the live tenant.
    condition = (
      length([for k, v in try(var.tenant_vars.log_pipeline, {}) : v.pipeline_custom_id]) ==
      length(distinct([for k, v in try(var.tenant_vars.log_pipeline, {}) : v.pipeline_custom_id]))
    )
    error_message = "Two or more log_pipeline categories share the same pipeline_custom_id. Each category needs its own unique custom_id."
  }
}

module "dynatrace_log_routing" {
  source = "./dynatrace_log_routing"
  count  = contains(keys(var.tenant_vars), "log_routing") ? 1 : 0

  allow_manage_existing_routing = try(var.tenant_vars.log_routing.allow_manage_existing_routing, false)

  # One computed route per category pipeline, ordered alphabetically by
  # category key (Terraform's for_each has no other inherent order) - each
  # entry's pipeline_id comes from that category's own module output, never
  # hard-entered, so it can't drift from what dynatrace_log_pipeline
  # actually creates. routes_before/routes_after from tenant_vars supply every
  # other entry that must exist in the live table, since this resource
  # replaces the whole table on apply.
  routes = concat(
    try(var.tenant_vars.log_routing.routes_before, []),
    [
      for k in sort(keys(try(var.tenant_vars.log_pipeline, {}))) : {
        description         = "Route to ${k} OpenPipeline logs pipeline"
        enabled             = true
        matcher             = try(var.tenant_vars.log_pipeline[k].routing_matcher, "true")
        pipeline_type       = "custom"
        builtin_pipeline_id = null
        pipeline_id         = module.dynatrace_log_pipeline[k].id
      }
    ],
    try(var.tenant_vars.log_routing.routes_after, [])
  )
}
