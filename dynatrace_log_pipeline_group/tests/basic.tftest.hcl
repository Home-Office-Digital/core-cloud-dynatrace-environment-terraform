mock_provider "dynatrace" {}

variables {
  display_name = "Tenant Logs Pipeline Group"

  base_pipelines = [
    {
      pipeline_id    = "mock-base-pipeline-id"
      mandate_stages = ["processing", "securityContext", "storage"]
    }
  ]

  member_stages_type    = "include"
  member_stages_include = ["metricExtraction"]

  member_pipeline_ids = ["mock-extra-member-pipeline-id"]

  default_member_custom_id    = "logs-default-entry"
  default_member_display_name = "Default log entry (all logs)"
}

run "plan_creates_pipeline_group" {
  command = plan

  assert {
    # 1 mandatory default_member + 1 extra member_pipeline_ids entry. This is
    # computed purely from variables (length()), not from module.default_member's
    # resource attributes, so it's known at plan time even under mock_provider -
    # member_pipelines itself contains module.default_member.id, which is only
    # known after apply, so it isn't asserted on directly here (this repo's
    # tests are plan-only against mock_provider - see module READMEs).
    condition     = output.member_pipeline_count == 2
    error_message = "Expected member_pipeline_count to include the mandatory default_member plus any extra member_pipeline_ids"
  }

  assert {
    condition     = dynatrace_openpipeline_v2_logs_pipelinegroups.group.display_name == "Tenant Logs Pipeline Group"
    error_message = "Expected display_name to be passed through"
  }

  assert {
    condition     = dynatrace_openpipeline_v2_logs_pipelinegroups.group.member_stages[0].type == "include"
    error_message = "Expected member_stages type to be passed through"
  }

  assert {
    condition = anytrue([
      for included_stage in dynatrace_openpipeline_v2_logs_pipelinegroups.group.member_stages[0].include :
      included_stage == "metricExtraction"
    ])
    error_message = "Expected member_stages include to contain metricExtraction"
  }

  assert {
    condition     = dynatrace_openpipeline_v2_logs_pipelinegroups.group.composition[0].pipeline_group_composition[0].pipeline_id == "mock-base-pipeline-id"
    error_message = "Expected first composition entry to be the base pipeline, not the placeholder"
  }

  assert {
    condition     = dynatrace_openpipeline_v2_logs_pipelinegroups.group.composition[0].pipeline_group_composition[0].is_pipeline_placeholder == false
    error_message = "Expected the base pipeline entry to not be the placeholder"
  }

  assert {
    condition     = dynatrace_openpipeline_v2_logs_pipelinegroups.group.composition[0].pipeline_group_composition[1].is_pipeline_placeholder == true
    error_message = "Expected the member placeholder to be the last composition entry"
  }

  assert {
    condition = anytrue([
      for mandated_stage in dynatrace_openpipeline_v2_logs_pipelinegroups.group.composition[0].pipeline_group_composition[0].stages[0].include :
      mandated_stage == "storage"
    ])
    error_message = "Expected the base pipeline's mandated stages to include storage"
  }
}

run "plan_member_placeholder_before_reverses_composition_order" {
  command = plan

  variables {
    member_placeholder_position = "before"
  }

  assert {
    condition     = dynatrace_openpipeline_v2_logs_pipelinegroups.group.composition[0].pipeline_group_composition[0].is_pipeline_placeholder == true
    error_message = "Expected the member placeholder to be the FIRST composition entry when member_placeholder_position = \"before\""
  }

  assert {
    condition     = dynatrace_openpipeline_v2_logs_pipelinegroups.group.composition[0].pipeline_group_composition[1].pipeline_id == "mock-base-pipeline-id"
    error_message = "Expected the base pipeline to be the SECOND composition entry when member_placeholder_position = \"before\""
  }
}

run "rejects_invalid_member_placeholder_position" {
  command = plan

  variables {
    member_placeholder_position = "notARealPosition"
  }

  expect_failures = [
    var.member_placeholder_position,
  ]
}

run "plan_base_pipeline_includeall_is_unrestricted" {
  command = plan

  variables {
    base_pipelines = [
      {
        pipeline_id          = "mock-base-pipeline-id"
        mandate_stages_type  = "includeAll"
      }
    ]
  }

  assert {
    condition     = dynatrace_openpipeline_v2_logs_pipelinegroups.group.composition[0].pipeline_group_composition[0].stages[0].type == "includeAll"
    error_message = "Expected the base pipeline's stages type to be includeAll when mandate_stages_type is set to includeAll"
  }
}

run "plan_create_default_member_false_uses_only_extra_members" {
  command = plan

  variables {
    create_default_member       = false
    default_member_custom_id    = null
    default_member_display_name = null
  }

  assert {
    # create_default_member is false, so only member_pipeline_ids (1 entry)
    # counts - no default_member added on top.
    condition     = output.member_pipeline_count == 1
    error_message = "Expected member_pipeline_count to exclude default_member when create_default_member is false"
  }

  assert {
    condition     = output.default_member_pipeline_id == null
    error_message = "Expected default_member_pipeline_id to be null when create_default_member is false"
  }
}

run "rejects_create_default_member_false_with_no_other_members" {
  command = plan

  variables {
    create_default_member       = false
    default_member_custom_id    = null
    default_member_display_name = null
    member_pipeline_ids         = []
  }

  expect_failures = [
    check.create_default_member_requires_a_reachable_member,
  ]
}

run "rejects_empty_base_pipelines" {
  command = plan

  variables {
    base_pipelines = []
  }

  expect_failures = [
    var.base_pipelines,
  ]
}

run "rejects_base_pipeline_with_no_mandated_stages" {
  command = plan

  variables {
    base_pipelines = [
      {
        pipeline_id    = "mock-base-pipeline-id"
        mandate_stages = []
      }
    ]
  }

  expect_failures = [
    var.base_pipelines,
  ]
}

run "rejects_invalid_member_stages_type" {
  command = plan

  variables {
    member_stages_type = "notARealType"
  }

  expect_failures = [
    var.member_stages_type,
  ]
}
