variable "corecloud_alert_configs" {
  type = map(object({
    # generic config for aws monitoring profile alerts
    notify_closed_problem             = bool
    slack_notification_enabled        = bool
    slack_message                     = string
    slack_notification_name           = string
    channel_name                      = string
    enabled                           = bool
    alerting_profile_name             = string
  }))
}

variable "corecloud_profile_alerting_rules" {
  type = map(object({
    alerting_profile_name = string 
    management_zone       = string
    rules = map(object({
      include_mode          = optional(string, "NONE")
      tags                  = optional(list(string), [])
      delay_in_minutes      = optional(number, 0)
      severity_level        = optional(string)
      predefined_events     = optional(object({
        negate = optional(bool, false)
        values = list(string)
      }))
    }))
  }))
}

variable "synthetic_alert_profile_configs" {
  description = "Alerting profiles for synthetic monitoring with predefined event type filters."
  type = map(object({
    alerting_profile_name   = string
    management_zone         = string
    delay_in_minutes        = optional(number, 0)
    predefined_event_values = list(string)
  }))
  default = {}
}

variable "slack_webhook_urls" {
  type = map(string)
  description = "A map with keys matching the keys under 'core cloud' with the relevant channels' urls."
  sensitive = true
}