mock_provider "dynatrace" {}

variables {
  allow_manage_existing_pipeline = true
  pipeline_custom_id             = "logs"
  pipeline_display_name          = "logs"
  rules = [
    {
      id          = "processor_kubernetes_info_tier1"
      description = "Kubernetes info logs to tier1"
      matcher     = "isNotNull(k8s.namespace.name) and loglevel == \"INFO\""
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
        matcher     = "isNotNull(k8s.namespace.name) and loglevel == \"INFO\""
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
        matcher     = "isNotNull(k8s.namespace.name) and loglevel == \"INFO\""
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

run "phase1_tier1_bucket_classification_rules" {
  command = plan

  variables {
    allow_manage_existing_pipeline = true
    pipeline_custom_id             = "logs"
    pipeline_display_name          = "logs"
    enforce_tier1_only_active      = true
    rules = [
      {
        id          = "processor_kubernetes_debug_tier1"
        description = "Route Kubernetes debug logs to tier1 during phase 1."
        matcher     = "isNotNull(k8s.namespace.name) and (loglevel == \"DEBUG\" or loglevel == \"debug\")"
        bucket_name = "kubernetes_debug_tier1"
      },
      {
        id          = "processor_kubernetes_info_tier1"
        description = "Route Kubernetes info logs to tier1 during phase 1."
        matcher     = "isNotNull(k8s.namespace.name) and (loglevel == \"INFO\" or loglevel == \"info\")"
        bucket_name = "kubernetes_info_tier1"
      },
      {
        id          = "processor_kubernetes_warn_tier1"
        description = "Route Kubernetes warn logs to tier1 during phase 1."
        matcher     = "isNotNull(k8s.namespace.name) and (loglevel == \"WARN\" or loglevel == \"warn\" or loglevel == \"WARNING\" or loglevel == \"warning\")"
        bucket_name = "kubernetes_warn_tier1"
      },
      {
        id          = "processor_kubernetes_error_fatal_tier1"
        description = "Route Kubernetes error and fatal logs to tier1 during phase 1."
        matcher     = "isNotNull(k8s.namespace.name) and (loglevel == \"ERROR\" or loglevel == \"error\" or loglevel == \"FATAL\" or loglevel == \"fatal\")"
        bucket_name = "kubernetes_error_fatal_tier1"
      },
      {
        id          = "processor_host_debug_tier1"
        description = "Route host debug logs to tier1 during phase 1."
        matcher     = "(isNotNull(dt.entity.host) or isNotNull(host.name)) and (loglevel == \"DEBUG\" or loglevel == \"debug\")"
        bucket_name = "host_debug_tier1"
      },
      {
        id          = "processor_host_info_tier1"
        description = "Route host info logs to tier1 during phase 1."
        matcher     = "(isNotNull(dt.entity.host) or isNotNull(host.name)) and (loglevel == \"INFO\" or loglevel == \"info\")"
        bucket_name = "host_info_tier1"
      },
      {
        id          = "processor_host_warn_tier1"
        description = "Route host warn logs to tier1 during phase 1."
        matcher     = "(isNotNull(dt.entity.host) or isNotNull(host.name)) and (loglevel == \"WARN\" or loglevel == \"warn\" or loglevel == \"WARNING\" or loglevel == \"warning\")"
        bucket_name = "host_warn_tier1"
      },
      {
        id          = "processor_host_error_fatal_tier1"
        description = "Route host error and fatal logs to tier1 during phase 1."
        matcher     = "(isNotNull(dt.entity.host) or isNotNull(host.name)) and (loglevel == \"ERROR\" or loglevel == \"error\" or loglevel == \"FATAL\" or loglevel == \"fatal\")"
        bucket_name = "host_error_fatal_tier1"
      },
      {
        id          = "processor_cloud_debug_tier1"
        description = "Route cloud debug logs to tier1 during phase 1."
        matcher     = "(isNotNull(cloud.provider) or isNotNull(cloud.platform)) and (loglevel == \"DEBUG\" or loglevel == \"debug\")"
        bucket_name = "cloud_debug_tier1"
      },
      {
        id          = "processor_cloud_info_tier1"
        description = "Route cloud info logs to tier1 during phase 1."
        matcher     = "(isNotNull(cloud.provider) or isNotNull(cloud.platform)) and (loglevel == \"INFO\" or loglevel == \"info\")"
        bucket_name = "cloud_info_tier1"
      },
      {
        id          = "processor_cloud_warn_tier1"
        description = "Route cloud warn logs to tier1 during phase 1."
        matcher     = "(isNotNull(cloud.provider) or isNotNull(cloud.platform)) and (loglevel == \"WARN\" or loglevel == \"warn\" or loglevel == \"WARNING\" or loglevel == \"warning\")"
        bucket_name = "cloud_warn_tier1"
      },
      {
        id          = "processor_cloud_error_fatal_tier1"
        description = "Route cloud error and fatal logs to tier1 during phase 1."
        matcher     = "(isNotNull(cloud.provider) or isNotNull(cloud.platform)) and (loglevel == \"ERROR\" or loglevel == \"error\" or loglevel == \"FATAL\" or loglevel == \"fatal\")"
        bucket_name = "cloud_error_fatal_tier1"
      },
      {
        id          = "processor_catch_all"
        description = "Route anything unmatched to the default unknown bucket."
        matcher     = "true"
        bucket_name = "unknown"
      }
    ]
  }

  assert {
    condition     = output.rule_count == 13
    error_message = "Expected all 12 tier1 classification rules plus the catch-all rule"
  }

  assert {
    condition     = dynatrace_openpipeline_v2_logs_pipelines.log_bucket_assignment.storage[0].processors[0].processor[0].id == "processor_kubernetes_debug_tier1"
    error_message = "Expected phase 1 rule ordering to start with Kubernetes debug"
  }

  assert {
    condition     = dynatrace_openpipeline_v2_logs_pipelines.log_bucket_assignment.storage[0].processors[0].processor[12].bucket_assignment[0].bucket_name == "unknown"
    error_message = "Expected the catch-all bucket assignment to remain last"
  }
}
