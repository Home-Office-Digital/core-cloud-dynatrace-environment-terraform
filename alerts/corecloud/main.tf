terraform {
  required_providers {
    dynatrace = {
      version = "~> 1.0"
      source  = "dynatrace-oss/dynatrace"
    }
  }
}

locals {
  alerting_profile_ids_by_name = merge(
    { for key, profile in dynatrace_alerting.corecloud_profile : profile.name => profile.id },
    { for key, profile in dynatrace_alerting.synthetic_profile : profile.name => profile.id }
  )
}

data "dynatrace_management_zone_v2" "zones" {
  for_each = var.corecloud_profile_alerting_rules
  name     = each.value.management_zone
}

resource "dynatrace_webhook_notification" "custom_slack_alerts" { 
  for_each               = var.corecloud_alert_configs
  active                 = each.value.slack_notification_enabled
  name                   = each.value.slack_notification_name 
  profile                = local.alerting_profile_ids_by_name[each.value.alerting_profile_name]
  secret_url             = var.slack_webhook_urls[each.key]
  url_contains_secret    = true
  insecure               = false
  notify_event_merges    = false
  notify_closed_problems = true
  payload                = each.value.slack_message
}

resource "dynatrace_alerting" "corecloud_profile" {
    for_each        = var.corecloud_profile_alerting_rules
    name            = each.value.alerting_profile_name
    management_zone = data.dynatrace_management_zone_v2.zones[each.key].id
    rules {
        dynamic "rule" {
            for_each = each.value.rules
            content {
                include_mode     = rule.value.include_mode
                tags             = rule.value.tags
                delay_in_minutes = rule.value.delay_in_minutes
                severity_level   = rule.key
      }
    }
  }
}

data "dynatrace_management_zone_v2" "synthetic_zones" {
  for_each = var.synthetic_alert_profile_configs
  name     = each.value.management_zone
}

resource "dynatrace_alerting" "synthetic_profile" {
  for_each        = var.synthetic_alert_profile_configs
  name            = each.value.alerting_profile_name
  management_zone = data.dynatrace_management_zone_v2.synthetic_zones[each.key].id
  rules {
    rule {
      severity_level   = "AVAILABILITY"
      delay_in_minutes = each.value.delay_in_minutes
      include_mode     = "NONE"
      predefined_events {
        negate = false
        values = each.value.predefined_event_values
      }
    }
  }
}
