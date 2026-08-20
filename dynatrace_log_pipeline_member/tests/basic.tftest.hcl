mock_provider "dynatrace" {}

variables {
  custom_id     = "logs-tenant-platform"
  display_name  = "Platform team logs"
  metric_extraction_rules = [
    {
      id          = "metric_error_count"
      description = "Count ERROR-level records"
      matcher     = "loglevel == \"ERROR\""
      type        = "counterMetric"
      metric_key  = "log.platform.error.count"
      dimensions = [
        {
          source_field_name      = "k8s.namespace.name"
          destination_field_name = "namespace"
        }
      ]
    }
  ]
}

run "plan_creates_member_pipeline_with_counter_metric" {
  command = plan

  assert {
    condition     = output.pipeline_custom_id == "logs-tenant-platform"
    error_message = "Expected pipeline custom_id to match input"
  }

  assert {
    condition     = output.metric_rule_count == 1
    error_message = "Expected metric_rule_count to match number of rules supplied"
  }

  assert {
    condition     = dynatrace_openpipeline_v2_logs_pipelines.member.group_role == "memberPipeline"
    error_message = "Expected group_role to be hardcoded to memberPipeline"
  }

  assert {
    condition     = dynatrace_openpipeline_v2_logs_pipelines.member.routing == "routable"
    error_message = "Expected routing to be hardcoded to routable"
  }

  assert {
    condition     = dynatrace_openpipeline_v2_logs_pipelines.member.metric_extraction[0].processors[0].processor[0].counter_metric[0].metric_key == "log.platform.error.count"
    error_message = "Expected counter_metric metric_key to be passed through"
  }

  assert {
    condition = anytrue([
      for dimension_entry in dynatrace_openpipeline_v2_logs_pipelines.member.metric_extraction[0].processors[0].processor[0].counter_metric[0].dimensions[0].dimension :
      dimension_entry.source_field_name == "k8s.namespace.name"
    ])
    error_message = "Expected dimension source_field_name to be passed through"
  }
}

run "plan_creates_member_pipeline_with_value_metric" {
  command = plan

  variables {
    metric_extraction_rules = [
      {
        id            = "metric_quantity"
        description   = "Sum quantity field"
        matcher       = "true"
        type          = "valueMetric"
        metric_key    = "log.platform.quantity"
        field         = "quantity"
        default_value = 0
      }
    ]
  }

  assert {
    condition     = dynatrace_openpipeline_v2_logs_pipelines.member.metric_extraction[0].processors[0].processor[0].value_metric[0].field == "quantity"
    error_message = "Expected value_metric field to be passed through"
  }
}

run "rejects_invalid_processor_type" {
  command = plan

  variables {
    metric_extraction_rules = [
      {
        id         = "metric_bad_type"
        matcher    = "true"
        type       = "gaugeMetric"
        metric_key = "log.platform.bad"
      }
    ]
  }

  expect_failures = [
    var.metric_extraction_rules,
  ]
}

run "rejects_value_metric_missing_field" {
  command = plan

  variables {
    metric_extraction_rules = [
      {
        id         = "metric_missing_field"
        matcher    = "true"
        type       = "valueMetric"
        metric_key = "log.platform.missing"
      }
    ]
  }

  expect_failures = [
    var.metric_extraction_rules,
  ]
}
