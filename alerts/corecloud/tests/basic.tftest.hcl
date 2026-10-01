mock_provider "dynatrace" {}

variables {
  corecloud_alert_configs = {
    glue = {
      enabled                    = true
      notify_closed_problem      = false
      slack_notification_enabled = true
      alerting_profile_name      = "corecloud_glue_profile"
      slack_notification_name    = "corecloud_glue_slack_alert_notification"
      channel_name               = "dynatrace-dev-notifications"
      slack_webhook_url_key      = "corecloud_critical_alert_config"
      slack_message              = "{\"text\":\"{ProblemTitle}\"}"
    }
  }

  corecloud_profile_alerting_rules = {
    glue = {
      alerting_profile_name = "corecloud_glue_profile"
      rules = {
        CUSTOM_ALERT = {}
      }
    }
  }

  slack_webhook_urls = {
    corecloud_critical_alert_config = "https://example.invalid/slack"
  }
}

run "custom_alert_profile_without_management_zone" {
  command = plan

  assert {
    condition     = dynatrace_alerting.corecloud_profile["glue"].name == "corecloud_glue_profile"
    error_message = "The Glue alerting profile must be created."
  }

  assert {
    condition     = dynatrace_alerting.corecloud_profile["glue"].management_zone == null
    error_message = "Environment-level Glue events must not be restricted by a management zone."
  }

  assert {
    condition     = dynatrace_webhook_notification.custom_slack_alerts["glue"].active
    error_message = "The Glue Slack notification must be active."
  }
}
