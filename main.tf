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
  source      = "git::https://github.com/UKHomeOffice/core-cloud-aws-secrets-terraform.git?ref=0.2.3"
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
      name              = "include-dynatrace-pods"
      enabled           = true
      send_to_storage   = true
      matcher_attribute = "k8s.namespace.name"
      matcher_values    = ["kube-system"]
    },
    {
      name              = "include-dt-containers"
      enabled           = true
      send_to_storage   = true
      matcher_attribute = "k8s.pod.label"
      matcher_values    = ["dynatrace-logs=true"]
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
  source                    = "./aws_cwl_cwm"
  for_each                  = try(var.tenant_vars.aws_cwl_cwm, {})
  tags                      = each.value.tags
  lifecycle_expiration_days = each.value.lifecycle_expiration_days
  days_after_initiation     = each.value.days_after_initiation
  ingestion_type            = each.value.ingestion_type
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


