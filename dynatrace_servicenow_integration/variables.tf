# The following variables would directly come from the
# terragrunt pipeline.
variable "servicenow_payload" {
  description = "Message to ServiceNow. Please refer to test pipeline in the terragrunt for implementation example."
  type = map(string)
}

variable "management_zone"{
  type = string
  default = null
  description = "alerting_profile management zone"
}
variable "servicenow_alerting_rules" {
  type = map(object({
    include_mode = optional(string, "NONE") # According to https://registry.terraform.io/providers/dynatrace-oss/dynatrace/latest/docs/resources/alerting#nested-schema-for-rulesrule, 'NONE' applies to all monitored entities
    tags = optional(list(string), [])
    delay_in_minutes = optional(number, 0)
  }))
}

variable "snow_integration_state" {
  type = string
  description = "State to be passed on to through the API, though boolean, better be processed as string."
  default = "false"
}

variable "accept_any_cert" {
  type = string
  description = "Accept any SSL certificates."
  default = "true"
}

variable "notify_event_merges" {
  type = string
  description = "Call webhook if new events merge into existing problems."
  default = "true"
}

variable "notify_closed_problems" {
  type = string
  description = "Call webhook if problem is closed."
  default = "true"
}

variable "integration_name" {
  type = string
  description = "TODO - name of the integration. Must be fed through a dictionary list."
  default = "servicenow_integration"
}