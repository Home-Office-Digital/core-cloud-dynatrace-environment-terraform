# Cross-variable checks live here, not as inline validation blocks, since a variable's own validation can only reference itself pre-1.9 (this module targets >= 1.5.0, see root versions.tf).
check "create_default_member_requires_a_reachable_member" {
  assert {
    condition     = var.create_default_member || length(var.member_pipeline_ids) > 0
    error_message = "create_default_member is false but member_pipeline_ids is empty - the group would have no members at all and be unreachable (a base pipeline can never be routed to directly)."
  }
}

check "default_member_custom_id_required_when_created" {
  assert {
    condition     = !var.create_default_member || var.default_member_custom_id != null
    error_message = "default_member_custom_id must be set when create_default_member is true."
  }
}

check "default_member_display_name_required_when_created" {
  assert {
    condition     = !var.create_default_member || var.default_member_display_name != null
    error_message = "default_member_display_name must be set when create_default_member is true."
  }
}

# Optional entry point - a base pipeline can never be routed to directly (see README); checks above ensure the group isn't left with zero members.
module "default_member" {
  count  = var.create_default_member ? 1 : 0
  source = "../dynatrace_log_pipeline_member"

  custom_id               = var.default_member_custom_id
  display_name            = var.default_member_display_name
  metric_extraction_rules = var.default_member_metric_extraction_rules
}

resource "dynatrace_openpipeline_v2_logs_pipelinegroups" "group" {
  display_name = var.display_name

  composition {
    # Declaration order here IS the composition order - member_placeholder_position picks which placeholder block below actually emits.
    dynamic "pipeline_group_composition" {
      for_each = var.member_placeholder_position == "before" ? [1] : []
      content {
        is_pipeline_placeholder = true
      }
    }

    dynamic "pipeline_group_composition" {
      for_each = var.base_pipelines
      content {
        is_pipeline_placeholder = false
        pipeline_id             = pipeline_group_composition.value.pipeline_id

        stages {
          type    = pipeline_group_composition.value.mandate_stages_type
          include = pipeline_group_composition.value.mandate_stages
        }
      }
    }

    dynamic "pipeline_group_composition" {
      for_each = var.member_placeholder_position == "after" ? [1] : []
      content {
        is_pipeline_placeholder = true
      }
    }
  }

  member_stages {
    type    = var.member_stages_type
    include = var.member_stages_include
    exclude = var.member_stages_exclude
  }

  member_pipelines = concat(
    var.create_default_member ? [module.default_member[0].id] : [],
    var.member_pipeline_ids
  )
}
