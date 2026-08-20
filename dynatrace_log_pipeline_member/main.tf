resource "dynatrace_openpipeline_v2_logs_pipelines" "member" {
  custom_id    = var.custom_id
  display_name = var.display_name

  # Hardcoded, not exposed as inputs: a member pipeline is only ever a
  # routable member of a pipeline group in this design - see module README.
  group_role = "memberPipeline"
  routing    = "routable"

  lifecycle {
    create_before_destroy = true
  }

  dynamic "metric_extraction" {
    for_each = length(var.metric_extraction_rules) > 0 ? [1] : []
    content {
      processors {
        dynamic "processor" {
          for_each = var.metric_extraction_rules
          content {
            type        = processor.value.type
            id          = processor.value.id
            description = processor.value.description
            enabled     = processor.value.enabled
            matcher     = processor.value.matcher

            dynamic "counter_metric" {
              for_each = processor.value.type == "counterMetric" ? [1] : []
              content {
                metric_key = processor.value.metric_key

                dynamic "dimensions" {
                  for_each = length(processor.value.dimensions) > 0 ? [1] : []
                  content {
                    dynamic "dimension" {
                      for_each = processor.value.dimensions
                      content {
                        extraction_type        = dimension.value.extraction_type
                        strategy               = dimension.value.strategy
                        source_field_name      = dimension.value.source_field_name
                        destination_field_name = dimension.value.destination_field_name
                      }
                    }
                  }
                }
              }
            }

            dynamic "value_metric" {
              for_each = processor.value.type == "valueMetric" ? [1] : []
              content {
                metric_key    = processor.value.metric_key
                field         = processor.value.field
                default_value = processor.value.default_value

                dynamic "dimensions" {
                  for_each = length(processor.value.dimensions) > 0 ? [1] : []
                  content {
                    dynamic "dimension" {
                      for_each = processor.value.dimensions
                      content {
                        extraction_type        = dimension.value.extraction_type
                        strategy               = dimension.value.strategy
                        source_field_name      = dimension.value.source_field_name
                        destination_field_name = dimension.value.destination_field_name
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
