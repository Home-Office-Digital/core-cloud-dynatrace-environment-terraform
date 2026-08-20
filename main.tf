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
  source      = "git::https://github.com/Home-Office-Digital/core-cloud-aws-secrets-terraform.git?ref=1.0.0"
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

module "dynatrace_default_launchpad" {
  source = "./dynatrace_default_launchpad"
  count  = contains(keys(var.tenant_vars), "default_launchpad") ? 1 : 0

  launchpad_name      = var.tenant_vars.default_launchpad.name
  launchpad_content   = var.tenant_vars.default_launchpad.content
  launchpad_custom_id = try(var.tenant_vars.default_launchpad.custom_id, null)
  launchpad_private   = try(var.tenant_vars.default_launchpad.private, null)
}

# Retired module rename (dynatrace_log_bucket_assignment owned more than just bucket-assignment rules) - state address stays module.dynatrace_log_pipeline, from must stay the old name.
moved {
  from = module.dynatrace_log_bucket_assignment
  to   = module.dynatrace_log_pipeline
}

# ⚠️ Literal, tenant-specific addresses - moved blocks can't be parameterized per-tenant in Terraform, so this only covers the migration from key "platform" to custom_id "tiered_log_bucket_router". Verified true for every tenant today (only global_defaults.yaml sets log_pipeline/log_pipeline_legacy, no tenant_vars.yaml overrides it), but NOT enforced going forward: a tenant whose old category key or new custom_id ever differs from these two literals needs its OWN additional moved block (or a manual `terraform state mv`) before applying, or it will hit the exact same destroy/recreate-on-an-immutable-pipeline failure this block was added to fix.
moved {
  from = module.dynatrace_log_pipeline["platform"]
  to   = module.dynatrace_log_pipeline["tiered_log_bucket_router"]
}

locals {
  # log_pipeline_base is an ordered LIST, not a map (composition order matters, for_each over a map has none) - keyed by custom_id here purely to drive for_each.
  log_pipeline_base_by_id = {
    for base_pipeline in try(var.tenant_vars.log_pipeline_base, []) : base_pipeline.custom_id => base_pipeline
  }

  # log_pipeline_legacy: kept declared (not destroyed) but left out of routing/group composition, so it goes inert without being deleted - phase 1 of the two-phase cutover; phase 2 removes the entry once verified (see dynatrace_log_pipeline_group's README).
  log_pipeline_legacy_by_id = {
    for legacy_pipeline in try(var.tenant_vars.log_pipeline_legacy, []) : legacy_pipeline.custom_id => legacy_pipeline
  }

  # Every pipeline (base, legacy, default member, or named member) shares one custom_id namespace - collected here so the uniqueness check below catches cross-collisions.
  all_log_pipeline_custom_ids = concat(
    [for base_pipeline in try(var.tenant_vars.log_pipeline_base, []) : base_pipeline.custom_id],
    [for legacy_pipeline in try(var.tenant_vars.log_pipeline_legacy, []) : legacy_pipeline.custom_id],
    (
      contains(keys(var.tenant_vars), "log_pipeline_group") &&
      contains(keys(var.tenant_vars.log_pipeline_group), "default_member")
    ) ? [var.tenant_vars.log_pipeline_group.default_member.custom_id] : [],
    [for member_key, member in try(var.tenant_vars.log_pipeline_members, {}) : member.custom_id]
  )
}

module "dynatrace_log_pipeline" {
  source = "./dynatrace_log_pipeline"

  # Base pipelines AND legacy pipelines pending retirement both use this generic module - only log_pipeline_base feeds the group's composition, so legacy entries stay unwrapped, just kept alive in state.
  for_each = merge(local.log_pipeline_base_by_id, local.log_pipeline_legacy_by_id)

  pipeline_custom_id             = each.value.custom_id
  pipeline_display_name          = each.value.display_name
  group_role                     = try(each.value.group_role, "basePipeline")
  routing                        = try(each.value.routing, "notRoutable")
  allow_manage_existing_pipeline = try(each.value.allow_manage_existing_pipeline, false)
  enforce_tier1_only_active      = try(each.value.enforce_tier1_only_active, false)
  tier1_rule_id_regex            = try(each.value.tier1_rule_id_regex, "tier1")
  security_context_rules         = try(each.value.security_context_rules, [])
  processing_fields_add_rules    = try(each.value.processing_fields_add_rules, [])
  rules                          = each.value.rules
}

module "dynatrace_log_pipeline_member" {
  source = "./dynatrace_log_pipeline_member"

  # Additional named member pipelines - not required for default routing (dynatrace_log_pipeline_group's default_member covers that); only needed for team-specific self-service metrics, one per key.
  for_each = try(var.tenant_vars.log_pipeline_members, {})

  custom_id               = each.value.custom_id
  display_name            = each.value.display_name
  metric_extraction_rules = try(each.value.metric_extraction_rules, [])
}

module "dynatrace_log_pipeline_group" {
  source = "./dynatrace_log_pipeline_group"
  count  = contains(keys(var.tenant_vars), "log_pipeline_group") ? 1 : 0

  display_name = var.tenant_vars.log_pipeline_group.display_name

  member_placeholder_position = try(var.tenant_vars.log_pipeline_group.member_placeholder_position, "after")

  # Ordered per log_pipeline_base's list order (see locals above); mandate_stages_type defaults to "include" - set "includeAll" in tenant config for a fully unrestricted base pipeline.
  base_pipelines = [
    for base_pipeline in try(var.tenant_vars.log_pipeline_base, []) : {
      pipeline_id         = module.dynatrace_log_pipeline[base_pipeline.custom_id].id
      mandate_stages_type = try(base_pipeline.mandate_stages_type, "include")
      mandate_stages      = try(base_pipeline.mandate_stages, [])
    }
  ]

  member_stages_type    = try(var.tenant_vars.log_pipeline_group.member_stages.type, "include")
  member_stages_include = try(var.tenant_vars.log_pipeline_group.member_stages.include, [])
  member_stages_exclude = try(var.tenant_vars.log_pipeline_group.member_stages.exclude, [])

  # Created only when tenant_vars.log_pipeline_group.default_member is set - guarantees the group stays reachable; drop the block once real log_pipeline_members entries exist instead.
  create_default_member                  = contains(keys(var.tenant_vars.log_pipeline_group), "default_member")
  default_member_custom_id               = try(var.tenant_vars.log_pipeline_group.default_member.custom_id, null)
  default_member_display_name            = try(var.tenant_vars.log_pipeline_group.default_member.display_name, null)
  default_member_metric_extraction_rules = try(var.tenant_vars.log_pipeline_group.default_member.metric_extraction_rules, [])

  # Named members - adding a log_pipeline_members entry automatically joins the group alongside the default member, if any.
  member_pipeline_ids = [for member_key, member_pipeline in module.dynatrace_log_pipeline_member : member_pipeline.id]
}

check "log_pipeline_group_requires_base" {
  assert {
    # Checks length, not just key presence - log_pipeline_base: [] would satisfy a bare contains() check while leaving the group's composition with zero mandated base stages, defeating the whole point of wrapping members in a governed group.
    condition = (
      !contains(keys(var.tenant_vars), "log_pipeline_group") ||
      length(try(var.tenant_vars.log_pipeline_base, [])) > 0
    )
    error_message = "tenant_vars.log_pipeline_group is set without at least one entry in tenant_vars.log_pipeline_base. The group's composition is computed entirely from log_pipeline_base, so it can't be enabled with that list empty or absent."
  }
}

check "log_routing_requires_log_pipeline_group" {
  assert {
    condition = (
      !contains(keys(var.tenant_vars), "log_routing") ||
      contains(keys(var.tenant_vars), "log_pipeline_group")
    )
    error_message = "tenant_vars.log_routing is set without tenant_vars.log_pipeline_group. dynatrace_log_routing's catch-all route entry is computed from module.dynatrace_log_pipeline_group's mandatory default_member output, so it can't be enabled on its own."
  }
}

check "log_pipeline_members_need_distinct_matchers" {
  assert {
    # Default here MUST match the route builder's own default ("false", not "true" - see the routes computation below) or this check both false-positives (flagging omitted matchers as ambiguous "true" catch-alls they aren't) and mismatches its own error message. This only catches members that explicitly share matcher "true" - two routed members both left on the omitted-matcher default are inert, not ambiguous, and correctly don't trip this.
    condition = (
      length([
        for member_key, member in try(var.tenant_vars.log_pipeline_members, {}) : member_key
        if try(member.create_route, false)
      ]) <= 1 ||
      length([
        for member_key, member in try(var.tenant_vars.log_pipeline_members, {}) : member_key
        if try(member.create_route, false) && trimspace(lower(try(member.routing_matcher, "false"))) == "true"
      ]) <= 1
    )
    error_message = "More than one routed log_pipeline_members entry has matcher \"true\". Only the first ever matches - give every routed member beyond one a real, distinguishing routing_matcher."
  }
}

check "log_pipeline_ids_must_be_unique" {
  assert {
    # custom_id is chosen per-entry, not derived from the map/list key - nothing else stops a collision, which would otherwise only surface as an API error at apply time.
    condition = (
      length(local.all_log_pipeline_custom_ids) ==
      length(distinct(local.all_log_pipeline_custom_ids))
    )
    error_message = "Two or more log_pipeline_base/log_pipeline_legacy/log_pipeline_group.default_member/log_pipeline_members entries share the same custom_id. Every pipeline in the tenant needs its own unique custom_id."
  }
}

module "dynatrace_log_routing" {
  source = "./dynatrace_log_routing"
  count  = contains(keys(var.tenant_vars), "log_routing") ? 1 : 0

  # default_member_pipeline_id bypasses the actual group resource in its reference chain, so the implicit graph alone doesn't guarantee group assignment happens before routing - without this, a record could reach the member before it's part of the group and miss the base pipeline's mandated stages.
  depends_on = [module.dynatrace_log_pipeline_group]

  allow_manage_existing_routing = try(var.tenant_vars.log_routing.allow_manage_existing_routing, false)

  # Routes target member pipelines only (base pipelines in a group can't be routed to directly - see dynatrace_log_pipeline_group's README); named log_pipeline_members entries are ordered before the default_member fallback, deliberately not alphabetically.
  # ⚠️ default_member's matcher fails closed to "false" (not "true") if routing_matcher isn't set explicitly - this resource replaces the WHOLE routing table on every apply, and a "true" default here once wiped out every other pipeline's route in one apply. Set the real matcher deliberately once known.
  routes = concat(
    try(var.tenant_vars.log_routing.routes_before, []),
    [
      # create_route is opt-in (default false) - a member can exist with no route at all, a normal valid state; set true only once it's meant to be reachable.
      for member_key in sort(keys(try(var.tenant_vars.log_pipeline_members, {}))) : {
        description = "Route to ${member_key} OpenPipeline logs member pipeline"
        enabled     = true
        # Fail-closed default, same reasoning as default_member below - an omitted matcher means "inert", not "catches everything".
        matcher             = try(var.tenant_vars.log_pipeline_members[member_key].routing_matcher, "false")
        pipeline_type       = "custom"
        builtin_pipeline_id = null
        pipeline_id         = module.dynatrace_log_pipeline_member[member_key].id
      }
      if try(var.tenant_vars.log_pipeline_members[member_key].create_route, false)
    ],
    [
      # Only generated when log_pipeline_group.default_member is set - its output is null otherwise, and a route can't have a null pipeline_id.
      for _ in(
        contains(keys(var.tenant_vars), "log_pipeline_group") &&
        contains(keys(var.tenant_vars.log_pipeline_group), "default_member")
        ) ? [1] : [] : {
        description         = "Route to default OpenPipeline logs entry (base pipeline via its default member)"
        enabled             = true
        matcher             = try(var.tenant_vars.log_pipeline_group.default_member.routing_matcher, "false")
        pipeline_type       = "custom"
        builtin_pipeline_id = null
        pipeline_id         = module.dynatrace_log_pipeline_group[0].default_member_pipeline_id
      }
    ],
    try(var.tenant_vars.log_routing.routes_after, [])
  )
}
