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

# Optional entry point: a base pipeline can never be routed to directly (see
# README), so the group would be unreachable if it ended up with zero
# members. Set create_default_member = false once real, explicitly-declared
# member pipelines exist via member_pipeline_ids and this internal one is no
# longer needed - the checks above make sure that's not done leaving the
# group with no members at all.
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
    # Declaration order across these dynamic blocks IS the composition
    # order Dynatrace uses - only one of the two placeholder blocks below
    # ever actually emits a block (for_each is a 0-or-1-element list), so
    # member_placeholder_position controls whether the placeholder ends up
    # before or after the base pipelines list.
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
