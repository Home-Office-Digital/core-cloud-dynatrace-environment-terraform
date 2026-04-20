variable "common_metrics_vars" {
  description = "Common metric configuration variables"
  type = object({
    model_properties_type = string
    alert_on_no_data      = bool
    samples               = string
    violating_samples     = string
    davis_merge           = bool
    event_type            = string

    event_entity_dimension_key        = string
    dimension_key                     = string
    entity_filter_condition1_type     = string
    entity_filter_condition1_operator = string
    entity_filter_condition1_value    = string
  })
}
variable "metric_stream_vars" {
  description = "metric stream configuration variables"
  type = object({
    model_properties_type = string
    alert_on_no_data      = bool
    samples               = string
    violating_samples     = string
    davis_merge           = bool
    event_type            = string

    event_entity_dimension_key = string
    dimension_key              = string
    metric_selector            = string
  })
}
variable "s3_error_vars" {
  description = "S3 error configuration variables"
  type = object({
    model_properties_type = string
    alert_on_no_data      = bool
    samples               = string
    violating_samples     = string
    davis_merge           = bool
    event_type            = string

    event_entity_dimension_key = string
    dimension_key              = string
    metric_selector            = string
  })
}
# config related to metrics
variable "metrics_vars" {
  type = object({
    memory_usage = object({
      summary               = string
      description           = string
      alert_condition       = string
      dealerting_samples    = string
      query_definition_type = string
      aggregation           = string
      metric_key            = string
      warning = object({
        enabled           = bool
        title             = string
        threshold         = string
        samples           = optional(string, null)
        violating_samples = optional(string, null)
        tags = list(object({
          key   = string
          value = string
        }))
      })
      critical = object({
        enabled   = bool
        title     = string
        threshold = string
        tags = list(object({
          key   = string
          value = string
        }))
      })
    })
    cpu_usage = object({
      summary               = string
      description           = string
      alert_condition       = string
      dealerting_samples    = string
      query_definition_type = string
      aggregation           = string
      metric_key            = string
      warning = object({
        enabled   = bool
        title     = string
        threshold = string
        tags = list(object({
          key   = string
          value = string
        }))
      })
      critical = object({
        enabled   = bool
        title     = string
        threshold = string
        tags = list(object({
          key   = string
          value = string
        }))
      })
    })
    metric_update = object({
      summary               = string
      description           = string
      alert_condition       = string
      dealerting_samples    = string
      query_definition_type = string
      #  aggregation           = string
      metric_key = string
      critical = object({
        enabled   = bool
        title     = string
        threshold = string
        tags = list(object({
          key   = string
          value = string
        }))
      })
    })
    publish_error_rate = object({
      summary               = string
      description           = string
      alert_condition       = string
      dealerting_samples    = string
      query_definition_type = string
      #  aggregation           = string
      metric_key = string
      critical = object({
        enabled   = bool
        title     = string
        threshold = string
        tags = list(object({
          key   = string
          value = string
        }))
      })
    })
    multipart_upload_4xx_errors = object({
      summary               = string
      description           = string
      alert_condition       = string
      dealerting_samples    = string
      query_definition_type = string
      #  aggregation           = string
      metric_key = string
      critical = object({
        enabled   = bool
        title     = string
        threshold = string
        tags = list(object({
          key   = string
          value = string
        }))
      })
    })
    multipart_upload_5xx_errors = object({
      summary               = string
      description           = string
      alert_condition       = string
      dealerting_samples    = string
      query_definition_type = string
      #  aggregation           = string
      metric_key = string
      critical = object({
        enabled   = bool
        title     = string
        threshold = string
        tags = list(object({
          key   = string
          value = string
        }))
      })
    })
    disk_usage = object({
      summary               = string
      description           = string
      alert_condition       = string
      dealerting_samples    = string
      query_definition_type = string
      aggregation           = string
      metric_key            = string
      warning = object({
        enabled   = bool
        title     = string
        threshold = string
        tags = list(object({
          key   = string
          value = string
        }))
      })
      critical = object({
        enabled   = bool
        title     = string
        threshold = string
        tags = list(object({
          key   = string
          value = string
        }))
      })
    })
  })
}

variable "tag_audit_lambda" {
  type = object({
    enabled                    = bool
    event_entity_dimension_key = string
    legacy_id                  = string
    summary                    = string
    event_template = object({
      davis_merge = bool
      description = string
      event_type  = string
      title       = string
    })
    model_properties = object({
      alert_condition    = string
      alert_on_no_data   = bool
      dealerting_samples = number
      samples            = number
      signal_fluctuation = number
      threshold          = number
      tolerance          = number
      type               = string
      violating_samples  = number
    })
    query_definition = object({
      aggregation     = string
      management_zone = string
      metric_key      = string
      metric_selector = string
      query_offset    = number
      type            = string
      entity_filter = object({
        dimension_key = string
        conditions = list(object({
          operator = string
          type     = string
          value    = string
        }))
      })
    })
  })
  default = null
}
