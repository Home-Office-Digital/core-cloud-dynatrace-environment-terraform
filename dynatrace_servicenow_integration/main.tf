terraform {
  required_providers {
    dynatrace = {
      version = "~> 1.0"
      source  = "dynatrace-oss/dynatrace"
    }
  }
}

data "dynatrace_management_zone_v2" "this"{
  count = var.management_zone != null  ? 1 : 0
  name = var.management_zone 
}
resource "dynatrace_alerting" "servicenow_alert" {
  name = "servicenow_alert"
  management_zone = var.management_zone != null ? data.dynatrace_management_zone_v2.this[0].id : null
  rules {
    dynamic "rule" {
      for_each = var.servicenow_alerting_rules
      content {
        include_mode = rule.value.include_mode
        tags = rule.value.tags
        delay_in_minutes = rule.value.delay_in_minutes
        severity_level = rule.key
      }
    }
  }
}

resource "terraform_data" "servicenow_integration" {
  triggers_replace = {
    integration_name = var.integration_name
    state = var.snow_integration_state
    alerting_profile_id = dynatrace_alerting.servicenow_alert.id
    integration_payload = "{\n  ${join(",\n  ", [for ky, val in var.servicenow_payload : "\"${ky}\": ${val}"])}\n}"
    snow_end_point = var.SERVICENOW_END_POINT
    snow_env_id = var.SERVICENOW_ENV_ID
    snow_client_id = var.SERVICENOW_CLIENT_ID
    #snow_secret_checksum = sha256(var.SERVICENOW_CLIENT_SECRET)
    accept_any_cert = var.accept_any_cert
    notify_event_merges = var.notify_event_merges
    notify_closed_problems = var.notify_closed_problems
  }
  provisioner "local-exec" {
    command = "bash ${path.module}/integration_utils/integration_helper"
    environment = {
      INTEGRATION_NAME = self.triggers_replace.integration_name
      ENABLED = self.triggers_replace.state
      ALERTING_PROFILE_ID = self.triggers_replace.alerting_profile_id
      WEBHOOK_PAYLOAD = self.triggers_replace.integration_payload # TODO - Due to known issues (refer to README), this value is currently ignored.
      SERVICENOW_END_POINT = self.triggers_replace.snow_end_point
      SERVICENOW_ENV_ID = self.triggers_replace.snow_env_id
      SERVICENOW_CLIENT_ID = self.triggers_replace.snow_client_id
      ACCEPT_ANY_CERT = self.triggers_replace.accept_any_cert
      NOTIFY_EVENT_MERGES = self.triggers_replace.notify_event_merges
      NOTIFY_CLOSED_PROBLEMS = self.triggers_replace.notify_closed_problems
    }
  }
  provisioner "local-exec" {
    when = destroy
    command = "bash ${path.module}/integration_utils/integration_helper"
    environment = {
      INTEGRATION_NAME = self.triggers_replace.integration_name
      DELETE_INTEGRATION =  "true"
      ENABLED = self.triggers_replace.state
      ALERTING_PROFILE_ID = self.triggers_replace.alerting_profile_id
      WEBHOOK_PAYLOAD = self.triggers_replace.integration_payload # TODO - Due to known issues (refer to README), this value is currently ignored.
      SERVICENOW_END_POINT = self.triggers_replace.snow_end_point
      SERVICENOW_ENV_ID = self.triggers_replace.snow_env_id
      SERVICENOW_CLIENT_ID = self.triggers_replace.snow_client_id
      ACCEPT_ANY_CERT = self.triggers_replace.accept_any_cert
      NOTIFY_EVENT_MERGES = self.triggers_replace.notify_event_merges
      NOTIFY_CLOSED_PROBLEMS = self.triggers_replace.notify_closed_problems
    }
  }
}

# TODO: Keeping this block here as we may have to
#       re-enable this one, once the problem with the
#       'client_secret' attribute getting stored in the
#       state file in clear text is resolved/addressed
#resource "dynatrace_webhook_notification" "service_now_integration" {
#  active    = true
#  name      = "servicenow_integration"
#  profile   = dynatrace_alerting.servicenow_alert.id
#  url       = var.SERVICENOW_END_POINT
#  insecure  = true # TODO (to confirm that this reflects - 'Accept SSL' which is set to FALSE in the page https://collaboration.homeoffice.gov.uk/pages/viewpage.action?pageId=353049956)
#  notify_event_merges = true
#  notify_closed_problems = true
#  use_oauth_2            = true
#  oauth_2_credentials {
#    access_token_url = "https://${var.SERVICENOW_ENV_ID}.service-now.com/oauth_token.do"
#    client_id        = var.SERVICENOW_CLIENT_ID
#    client_secret    = var.SERVICENOW_CLIENT_SECRET
#  }
#  payload = "{\n  ${join(",\n  ", [for ky, val in var.servicenow_payload : "\"${ky}\": ${val}"])}\n}"
#}
