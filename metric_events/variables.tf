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
      aggregation           = string
      metric_key            = string
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
      aggregation           = string
      metric_key            = string
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
      aggregation           = string
      metric_key            = string
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
      aggregation           = string
      metric_key            = string
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
