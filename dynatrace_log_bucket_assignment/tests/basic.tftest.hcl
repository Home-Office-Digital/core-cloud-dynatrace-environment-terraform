mock_provider "dynatrace" {}

variables {
  allow_manage_existing_pipeline = true
  pipeline_custom_id             = "logs"
  pipeline_display_name          = "logs"
  rules = [
    {
      id          = "processor_kubernetes_info_tier1"
      description = "Kubernetes info logs to tier1"
      matcher     = "k8s.namespace.name != null and loglevel == \"INFO\""
      bucket_name = "kubernetes_info_tier1"
    },
    {
      id          = "processor_catch_all"
      description = "Catch-all"
      matcher     = "true"
      bucket_name = "unknown"
    }
  ]
}

run "plan_creates_bucket_assignment_pipeline" {
  command = plan

  assert {
    condition     = output.pipeline_custom_id == "logs"
    error_message = "Expected pipeline custom_id to match input"
  }

  assert {
    condition     = output.pipeline_display_name == "logs"
    error_message = "Expected pipeline display_name to match input"
  }

  assert {
    condition     = output.rule_count == 2
    error_message = "Expected rule_count to match number of rules supplied"
  }

  assert {
    condition     = dynatrace_openpipeline_v2_logs_pipelines.log_bucket_assignment.storage[0].processors[0].processor[0].id == "processor_kubernetes_info_tier1"
    error_message = "Expected first processor id to preserve declared order"
  }

  assert {
    condition     = dynatrace_openpipeline_v2_logs_pipelines.log_bucket_assignment.storage[0].processors[0].processor[1].matcher == "true"
    error_message = "Expected catch-all matcher to remain in last processor"
  }

  assert {
    condition     = dynatrace_openpipeline_v2_logs_pipelines.log_bucket_assignment.storage[0].processors[0].processor[0].enabled
    error_message = "Expected processors to default enabled=true when not set"
  }
}

run "enforcement_allows_enabled_catch_all" {
  command = plan

  variables {
    allow_manage_existing_pipeline = true
    pipeline_custom_id             = "logs"
    pipeline_display_name          = "logs"
    enforce_tier1_only_active      = true
    rules = [
      {
        id          = "processor_kubernetes_info_tier1"
        description = "Kubernetes info logs to tier1"
        matcher     = "k8s.namespace.name != null and loglevel == \"INFO\""
        bucket_name = "kubernetes_info_tier1"
      },
      {
        id          = "processor_catch_all"
        description = "Catch-all, always active regardless of tier enforcement"
        matcher     = "true"
        bucket_name = "unknown"
      }
    ]
  }

  assert {
    condition     = output.rule_count == 2
    error_message = "Expected rule_count to match number of rules supplied"
  }
}

run "enforcement_blocks_non_tier1_rule_left_enabled" {
  command = plan

  variables {
    allow_manage_existing_pipeline = true
    pipeline_custom_id             = "logs"
    pipeline_display_name          = "logs"
    enforce_tier1_only_active      = true
    rules = [
      {
        id          = "processor_kubernetes_info_tier2"
        description = "Should be blocked by enforcement - tier2 left enabled"
        matcher     = "k8s.namespace.name != null and loglevel == \"INFO\""
        bucket_name = "kubernetes_info_tier2"
      },
      {
        id          = "processor_catch_all"
        description = "Catch-all"
        matcher     = "true"
        bucket_name = "unknown"
      }
    ]
  }

  expect_failures = [
    check.non_tier1_rules_must_be_disabled,
  ]
}
