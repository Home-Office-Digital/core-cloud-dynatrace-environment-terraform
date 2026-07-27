resource "dynatrace_openpipeline_v2_logs_pipelines" "log_bucket_assignment" {
  custom_id    = var.pipeline_custom_id
  display_name = var.pipeline_display_name
  group_role   = var.group_role
  routing      = var.routing

  lifecycle {
    create_before_destroy = true

    precondition {
      condition     = var.allow_manage_existing_pipeline
      error_message = "Set allow_manage_existing_pipeline=true only after importing the target pipeline and reviewing plan output for non-storage stage drift."
    }
  }

  dynamic "security_context" {
    for_each = length(var.security_context_rules) > 0 ? [1] : []
    content {
      processors {
        dynamic "processor" {
          for_each = var.security_context_rules
          content {
            type        = "securityContext"
            id          = processor.value.id
            description = processor.value.description
            enabled     = processor.value.enabled
            matcher     = processor.value.matcher

            security_context {
              value {
                type = "field"
                field {
                  source_field_name = processor.value.source_field_name
                }
              }
            }
          }
        }
      }
    }
  }

  dynamic "processing" {
    for_each = length(var.processing_fields_add_rules) > 0 ? [1] : []
    content {
      processors {
        dynamic "processor" {
          for_each = var.processing_fields_add_rules
          content {
            type        = "fieldsAdd"
            id          = processor.value.id
            description = processor.value.description
            enabled     = processor.value.enabled
            matcher     = processor.value.matcher

            fields_add {
              fields {
                field {
                  name  = processor.value.field_name
                  value = processor.value.field_value
                }
              }
            }
          }
        }
      }
    }
  }

  storage {
    processors {
      dynamic "processor" {
        for_each = var.rules
        content {
          type        = "bucketAssignment"
          id          = processor.value.id
          description = processor.value.description
          enabled     = processor.value.enabled
          matcher     = processor.value.matcher

          bucket_assignment {
            bucket_name = processor.value.bucket_name
          }
        }
      }
    }
  }
}
