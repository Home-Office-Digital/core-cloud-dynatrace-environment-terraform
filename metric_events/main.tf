terraform {
  required_providers {
    dynatrace = {
      version = "~> 1.0"
      source  = "dynatrace-oss/dynatrace"
    }
  }
}

# memory warning alerts
resource "dynatrace_metric_events" "freeable_memory_warning_alerts" {
  count                      = var.metrics_vars.memory_usage.warning.enabled == true ? 1 : 0
  enabled                    = var.metrics_vars.memory_usage.warning.enabled
  event_entity_dimension_key = var.common_metrics_vars.event_entity_dimension_key
  summary                    = var.metrics_vars.memory_usage.summary
  event_template {
    description = var.metrics_vars.memory_usage.description
    davis_merge = var.common_metrics_vars.davis_merge
    event_type  = var.common_metrics_vars.event_type
    title       = var.metrics_vars.memory_usage.warning.title
    dynamic "metadata" {
      for_each = var.metrics_vars.memory_usage.warning.tags
      content {
        metadata_key   = metadata.value.key
        metadata_value = metadata.value.value
      }
    }
  }
  model_properties {
    type               = var.common_metrics_vars.model_properties_type
    alert_condition    = var.metrics_vars.memory_usage.alert_condition
    alert_on_no_data   = var.common_metrics_vars.alert_on_no_data
    dealerting_samples = var.metrics_vars.memory_usage.dealerting_samples
    samples            = var.metrics_vars.memory_usage.warning.samples != null ? var.metrics_vars.memory_usage.warning.samples : var.common_metrics_vars.samples
    threshold          = var.metrics_vars.memory_usage.warning.threshold
    violating_samples  = var.metrics_vars.memory_usage.warning.violating_samples != null ? var.metrics_vars.memory_usage.warning.violating_samples : var.common_metrics_vars.violating_samples
  }
  query_definition {
    type        = var.metrics_vars.memory_usage.query_definition_type
    aggregation = var.metrics_vars.memory_usage.aggregation
    metric_key  = var.metrics_vars.memory_usage.metric_key

    entity_filter {
      dimension_key = var.common_metrics_vars.dimension_key
      conditions {
        condition {
          type     = var.common_metrics_vars.entity_filter_condition1_type
          operator = var.common_metrics_vars.entity_filter_condition1_operator
          value    = var.common_metrics_vars.entity_filter_condition1_value
        }
      }
    }
  }
}

# memory critical alerts
resource "dynatrace_metric_events" "freeable_memory_critical_alerts" {
  count                      = var.metrics_vars.memory_usage.critical.enabled == true ? 1 : 0
  enabled                    = var.metrics_vars.memory_usage.critical.enabled
  event_entity_dimension_key = var.common_metrics_vars.event_entity_dimension_key
  summary                    = var.metrics_vars.memory_usage.summary
  event_template {
    description = var.metrics_vars.memory_usage.description
    davis_merge = var.common_metrics_vars.davis_merge
    event_type  = var.common_metrics_vars.event_type
    title       = var.metrics_vars.memory_usage.critical.title
    dynamic "metadata" {
      for_each = var.metrics_vars.memory_usage.critical.tags
      content {
        metadata_key   = metadata.value.key
        metadata_value = metadata.value.value
      }
    }
  }
  model_properties {
    type               = var.common_metrics_vars.model_properties_type
    alert_condition    = var.metrics_vars.memory_usage.alert_condition
    alert_on_no_data   = var.common_metrics_vars.alert_on_no_data
    dealerting_samples = var.metrics_vars.memory_usage.dealerting_samples
    samples            = var.common_metrics_vars.samples
    threshold          = var.metrics_vars.memory_usage.critical.threshold
    violating_samples  = var.common_metrics_vars.violating_samples
  }
  query_definition {
    type        = var.metrics_vars.memory_usage.query_definition_type
    aggregation = var.metrics_vars.memory_usage.aggregation
    metric_key  = var.metrics_vars.memory_usage.metric_key

    entity_filter {
      dimension_key = var.common_metrics_vars.dimension_key
      conditions {
        condition {
          type     = var.common_metrics_vars.entity_filter_condition1_type
          operator = var.common_metrics_vars.entity_filter_condition1_operator
          value    = var.common_metrics_vars.entity_filter_condition1_value
        }
      }
    }
  }
}

# cpu warning alerts
resource "dynatrace_metric_events" "cpu_utilization_warning_alerts" {
  count                      = var.metrics_vars.cpu_usage.warning.enabled == true ? 1 : 0
  enabled                    = var.metrics_vars.cpu_usage.warning.enabled
  event_entity_dimension_key = var.common_metrics_vars.event_entity_dimension_key
  summary                    = var.metrics_vars.cpu_usage.summary
  event_template {
    description = var.metrics_vars.cpu_usage.description
    davis_merge = var.common_metrics_vars.davis_merge
    event_type  = var.common_metrics_vars.event_type
    title       = var.metrics_vars.cpu_usage.warning.title
    dynamic "metadata" {
      for_each = var.metrics_vars.cpu_usage.warning.tags
      content {
        metadata_key   = metadata.value.key
        metadata_value = metadata.value.value
      }
    }
  }
  model_properties {
    type               = var.common_metrics_vars.model_properties_type
    alert_condition    = var.metrics_vars.cpu_usage.alert_condition
    alert_on_no_data   = var.common_metrics_vars.alert_on_no_data
    dealerting_samples = var.metrics_vars.cpu_usage.dealerting_samples
    samples            = var.common_metrics_vars.samples
    threshold          = var.metrics_vars.cpu_usage.warning.threshold
    violating_samples  = var.common_metrics_vars.violating_samples
  }
  query_definition {
    type        = var.metrics_vars.cpu_usage.query_definition_type
    aggregation = var.metrics_vars.cpu_usage.aggregation
    metric_key  = var.metrics_vars.cpu_usage.metric_key

    entity_filter {
      dimension_key = var.common_metrics_vars.dimension_key
      conditions {
        condition {
          type     = var.common_metrics_vars.entity_filter_condition1_type
          operator = var.common_metrics_vars.entity_filter_condition1_operator
          value    = var.common_metrics_vars.entity_filter_condition1_value
        }
      }
    }
  }
}

# cpu critical alerts
resource "dynatrace_metric_events" "cpu_utilization_critical_alerts" {
  count                      = var.metrics_vars.cpu_usage.critical.enabled == true ? 1 : 0
  enabled                    = var.metrics_vars.cpu_usage.critical.enabled
  event_entity_dimension_key = var.common_metrics_vars.event_entity_dimension_key
  summary                    = var.metrics_vars.cpu_usage.summary
  event_template {
    description = var.metrics_vars.cpu_usage.description
    davis_merge = var.common_metrics_vars.davis_merge
    event_type  = var.common_metrics_vars.event_type
    title       = var.metrics_vars.cpu_usage.critical.title
    dynamic "metadata" {
      for_each = var.metrics_vars.cpu_usage.critical.tags
      content {
        metadata_key   = metadata.value.key
        metadata_value = metadata.value.value
      }
    }
  }
  model_properties {
    type               = var.common_metrics_vars.model_properties_type
    alert_condition    = var.metrics_vars.cpu_usage.alert_condition
    alert_on_no_data   = var.common_metrics_vars.alert_on_no_data
    dealerting_samples = var.metrics_vars.cpu_usage.dealerting_samples
    samples            = var.common_metrics_vars.samples
    threshold          = var.metrics_vars.cpu_usage.critical.threshold
    violating_samples  = var.common_metrics_vars.violating_samples
  }
  query_definition {
    type        = var.metrics_vars.cpu_usage.query_definition_type
    aggregation = var.metrics_vars.cpu_usage.aggregation
    metric_key  = var.metrics_vars.cpu_usage.metric_key

    entity_filter {
      dimension_key = var.common_metrics_vars.dimension_key
      conditions {
        condition {
          type     = var.common_metrics_vars.entity_filter_condition1_type
          operator = var.common_metrics_vars.entity_filter_condition1_operator
          value    = var.common_metrics_vars.entity_filter_condition1_value
        }
      }
    }
  }
}

# disk warning alerts
resource "dynatrace_metric_events" "disk_utilization_warning_alerts" {
  count                      = var.metrics_vars.disk_usage.warning.enabled == true ? 1 : 0
  enabled                    = var.metrics_vars.disk_usage.warning.enabled
  event_entity_dimension_key = var.common_metrics_vars.event_entity_dimension_key
  summary                    = var.metrics_vars.disk_usage.summary
  event_template {
    description = var.metrics_vars.disk_usage.description
    davis_merge = var.common_metrics_vars.davis_merge
    event_type  = var.common_metrics_vars.event_type
    title       = var.metrics_vars.disk_usage.warning.title
    dynamic "metadata" {
      for_each = var.metrics_vars.disk_usage.warning.tags
      content {
        metadata_key   = metadata.value.key
        metadata_value = metadata.value.value
      }
    }
  }
  model_properties {
    type               = var.common_metrics_vars.model_properties_type
    alert_condition    = var.metrics_vars.disk_usage.alert_condition
    alert_on_no_data   = var.common_metrics_vars.alert_on_no_data
    dealerting_samples = var.metrics_vars.disk_usage.dealerting_samples
    samples            = var.common_metrics_vars.samples
    threshold          = var.metrics_vars.disk_usage.warning.threshold
    violating_samples  = var.common_metrics_vars.violating_samples
  }
  query_definition {
    type        = var.metrics_vars.disk_usage.query_definition_type
    aggregation = var.metrics_vars.disk_usage.aggregation
    metric_key  = var.metrics_vars.disk_usage.metric_key

    entity_filter {
      dimension_key = var.common_metrics_vars.dimension_key
      conditions {
        condition {
          type     = var.common_metrics_vars.entity_filter_condition1_type
          operator = var.common_metrics_vars.entity_filter_condition1_operator
          value    = var.common_metrics_vars.entity_filter_condition1_value
        }
      }
    }
  }
}

# disk critical alerts
resource "dynatrace_metric_events" "disk_utilization_critical_alerts" {
  count                      = var.metrics_vars.disk_usage.critical.enabled == true ? 1 : 0
  enabled                    = var.metrics_vars.disk_usage.critical.enabled
  event_entity_dimension_key = var.common_metrics_vars.event_entity_dimension_key
  summary                    = var.metrics_vars.disk_usage.summary
  event_template {
    description = var.metrics_vars.disk_usage.description
    davis_merge = var.common_metrics_vars.davis_merge
    event_type  = var.common_metrics_vars.event_type
    title       = var.metrics_vars.disk_usage.critical.title
    dynamic "metadata" {
      for_each = var.metrics_vars.disk_usage.critical.tags
      content {
        metadata_key   = metadata.value.key
        metadata_value = metadata.value.value
      }
    }
  }
  model_properties {
    type               = var.common_metrics_vars.model_properties_type
    alert_condition    = var.metrics_vars.disk_usage.alert_condition
    alert_on_no_data   = var.common_metrics_vars.alert_on_no_data
    dealerting_samples = var.metrics_vars.disk_usage.dealerting_samples
    samples            = var.common_metrics_vars.samples
    threshold          = var.metrics_vars.disk_usage.critical.threshold
    violating_samples  = var.common_metrics_vars.violating_samples
  }
  query_definition {
    type        = var.metrics_vars.disk_usage.query_definition_type
    aggregation = var.metrics_vars.disk_usage.aggregation
    metric_key  = var.metrics_vars.disk_usage.metric_key

    entity_filter {
      dimension_key = var.common_metrics_vars.dimension_key
      conditions {
        condition {
          type     = var.common_metrics_vars.entity_filter_condition1_type
          operator = var.common_metrics_vars.entity_filter_condition1_operator
          value    = var.common_metrics_vars.entity_filter_condition1_value
        }
      }
    }
  }
}

# Metric Update critical alerts (METRIC_SELECTOR)
resource "dynatrace_metric_events" "metric_update_critical_alerts" {
  count                      = var.metrics_vars.metric_update.critical.enabled == true ? 1 : 0
  enabled                    = var.metrics_vars.metric_update.critical.enabled
  event_entity_dimension_key = var.metric_stream_vars.event_entity_dimension_key
  summary                    = var.metrics_vars.metric_update.summary

  event_template {
    description = var.metrics_vars.metric_update.description
    davis_merge = var.metric_stream_vars.davis_merge
    event_type  = var.metric_stream_vars.event_type
    title       = var.metrics_vars.metric_update.critical.title

    dynamic "metadata" {
      for_each = var.metrics_vars.metric_update.critical.tags
      content {
        metadata_key   = metadata.value.key
        metadata_value = metadata.value.value
      }
    }
  }

  model_properties {
    type               = var.metric_stream_vars.model_properties_type
    alert_condition    = var.metrics_vars.metric_update.alert_condition
    alert_on_no_data   = var.metric_stream_vars.alert_on_no_data
    dealerting_samples = var.metrics_vars.metric_update.dealerting_samples
    samples            = var.metric_stream_vars.samples
    threshold          = var.metrics_vars.metric_update.critical.threshold
    violating_samples  = var.metric_stream_vars.violating_samples
  }

  query_definition {
    type            = var.metrics_vars.metric_update.query_definition_type
    metric_selector = var.metric_stream_vars.metric_selector
    #  aggregation     = var.metrics_vars.metric_update.aggregation
  }
}

# Publish Error Rate alerts
resource "dynatrace_metric_events" "publish_error_rate_critical_alerts" {
  count                      = var.metrics_vars.publish_error_rate.critical.enabled == true ? 1 : 0
  enabled                    = var.metrics_vars.publish_error_rate.critical.enabled
  event_entity_dimension_key = var.metric_stream_vars.event_entity_dimension_key
  summary                    = var.metrics_vars.publish_error_rate.summary

  event_template {
    description = var.metrics_vars.publish_error_rate.description
    davis_merge = var.metric_stream_vars.davis_merge
    event_type  = var.metric_stream_vars.event_type
    title       = var.metrics_vars.publish_error_rate.critical.title

    dynamic "metadata" {
      for_each = var.metrics_vars.publish_error_rate.critical.tags
      content {
        metadata_key   = metadata.value.key
        metadata_value = metadata.value.value
      }
    }
  }

  model_properties {
    type               = var.metric_stream_vars.model_properties_type
    alert_condition    = var.metrics_vars.publish_error_rate.alert_condition
    alert_on_no_data   = var.metric_stream_vars.alert_on_no_data
    dealerting_samples = var.metrics_vars.publish_error_rate.dealerting_samples
    samples            = var.metric_stream_vars.samples
    threshold          = var.metrics_vars.publish_error_rate.critical.threshold
    violating_samples  = var.metric_stream_vars.violating_samples
  }

  query_definition {
    type            = var.metrics_vars.publish_error_rate.query_definition_type
    metric_selector = var.metric_stream_vars.metric_selector
    #  aggregation     = var.metrics_vars.publish_error_rate.aggregation
  }
}

# S3 Multipart Upload 4xx Errors
resource "dynatrace_metric_events" "multipart_upload_4xx_errors_critical_alerts" {
  count                      = var.metrics_vars.multipart_upload_4xx_errors.critical.enabled == true ? 1 : 0
  enabled                    = var.metrics_vars.multipart_upload_4xx_errors.critical.enabled
  event_entity_dimension_key = var.s3_error_vars.event_entity_dimension_key
  summary                    = var.metrics_vars.multipart_upload_4xx_errors.summary

  event_template {
    description = var.metrics_vars.multipart_upload_4xx_errors.description
    davis_merge = var.s3_error_vars.davis_merge
    event_type  = var.s3_error_vars.event_type
    title       = var.metrics_vars.multipart_upload_4xx_errors.critical.title

    dynamic "metadata" {
      for_each = var.metrics_vars.multipart_upload_4xx_errors.critical.tags
      content {
        metadata_key   = metadata.value.key
        metadata_value = metadata.value.value
      }
    }
  }

  model_properties {
    type               = var.s3_error_vars.model_properties_type
    alert_condition    = var.metrics_vars.multipart_upload_4xx_errors.alert_condition
    alert_on_no_data   = var.s3_error_vars.alert_on_no_data
    dealerting_samples = var.metrics_vars.multipart_upload_4xx_errors.dealerting_samples
    samples            = var.s3_error_vars.samples
    threshold          = var.metrics_vars.multipart_upload_4xx_errors.critical.threshold
    violating_samples  = var.s3_error_vars.violating_samples
  }

  query_definition {
    type            = var.metrics_vars.multipart_upload_4xx_errors.query_definition_type
    metric_selector = var.s3_error_vars.metric_selector
    #  aggregation     = var.metrics_vars.multipart_upload_4xx_errors.aggregation
  }
}

# S3 Multipart Upload 5xx Errors
resource "dynatrace_metric_events" "multipart_upload_5xx_errors_critical_alerts" {
  count                      = var.metrics_vars.multipart_upload_5xx_errors.critical.enabled == true ? 1 : 0
  enabled                    = var.metrics_vars.multipart_upload_5xx_errors.critical.enabled
  event_entity_dimension_key = var.s3_error_vars.event_entity_dimension_key
  summary                    = var.metrics_vars.multipart_upload_5xx_errors.summary

  event_template {
    description = var.metrics_vars.multipart_upload_5xx_errors.description
    davis_merge = var.s3_error_vars.davis_merge
    event_type  = var.s3_error_vars.event_type
    title       = var.metrics_vars.multipart_upload_5xx_errors.critical.title

    dynamic "metadata" {
      for_each = var.metrics_vars.multipart_upload_5xx_errors.critical.tags
      content {
        metadata_key   = metadata.value.key
        metadata_value = metadata.value.value
      }
    }
  }

  model_properties {
    type               = var.s3_error_vars.model_properties_type
    alert_condition    = var.metrics_vars.multipart_upload_5xx_errors.alert_condition
    alert_on_no_data   = var.s3_error_vars.alert_on_no_data
    dealerting_samples = var.metrics_vars.multipart_upload_5xx_errors.dealerting_samples
    samples            = var.s3_error_vars.samples
    threshold          = var.metrics_vars.multipart_upload_5xx_errors.critical.threshold
    violating_samples  = var.s3_error_vars.violating_samples
  }

  query_definition {
    type            = var.metrics_vars.multipart_upload_5xx_errors.query_definition_type
    metric_selector = var.s3_error_vars.metric_selector
    #  aggregation     = var.metrics_vars.multipart_upload_5xx_errors.aggregation
  }
}


resource "dynatrace_metric_events" "tag_audit_lambda" {
  count                      = var.tag_audit_lambda != null && var.tag_audit_lambda.enabled ? 1 : 0
  enabled                    = var.tag_audit_lambda.enabled
  event_entity_dimension_key = var.tag_audit_lambda.event_entity_dimension_key
  legacy_id                  = var.tag_audit_lambda.legacy_id
  summary                    = var.tag_audit_lambda.summary

  event_template {
    davis_merge = var.tag_audit_lambda.event_template.davis_merge
    description = var.tag_audit_lambda.event_template.description
    event_type  = var.tag_audit_lambda.event_template.event_type
    title       = var.tag_audit_lambda.event_template.title
  }

  model_properties {
    alert_condition    = var.tag_audit_lambda.model_properties.alert_condition
    alert_on_no_data   = var.tag_audit_lambda.model_properties.alert_on_no_data
    dealerting_samples = var.tag_audit_lambda.model_properties.dealerting_samples
    samples            = var.tag_audit_lambda.model_properties.samples
    signal_fluctuation = var.tag_audit_lambda.model_properties.signal_fluctuation
    threshold          = var.tag_audit_lambda.model_properties.threshold
    tolerance          = var.tag_audit_lambda.model_properties.tolerance
    type               = var.tag_audit_lambda.model_properties.type
    violating_samples  = var.tag_audit_lambda.model_properties.violating_samples
  }

  query_definition {
    aggregation     = var.tag_audit_lambda.query_definition.aggregation
    management_zone = var.tag_audit_lambda.query_definition.management_zone
    metric_key      = var.tag_audit_lambda.query_definition.metric_key
    metric_selector = var.tag_audit_lambda.query_definition.metric_selector
    query_offset    = var.tag_audit_lambda.query_definition.query_offset
    type            = var.tag_audit_lambda.query_definition.type

    entity_filter {
      dimension_key = var.tag_audit_lambda.query_definition.entity_filter.dimension_key

      conditions {
        dynamic "condition" {
          for_each = var.tag_audit_lambda.query_definition.entity_filter.conditions
          content {
            operator = condition.value.operator
            type     = condition.value.type
            value    = condition.value.value
          }
        }
      }
    }
  }
}
