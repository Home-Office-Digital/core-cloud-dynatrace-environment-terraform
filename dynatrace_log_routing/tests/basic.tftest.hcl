mock_provider "dynatrace" {}

variables {
  allow_manage_existing_routing = true
  routes = [
    {
      description   = "Route to platform pipeline"
      enabled       = true
      matcher       = "true"
      pipeline_type = "custom"
      pipeline_id   = "mock-pipeline-id"
    }
  ]
}

run "plan_creates_routing_table" {
  command = plan

  assert {
    condition     = output.route_count == 1
    error_message = "Expected route_count to match number of routes supplied"
  }

  assert {
    condition     = dynatrace_openpipeline_v2_logs_routing.routing.routing_entries[0].routing_entry[0].description == "Route to platform pipeline"
    error_message = "Expected route description to match input"
  }

  assert {
    condition     = dynatrace_openpipeline_v2_logs_routing.routing.routing_entries[0].routing_entry[0].pipeline_id == "mock-pipeline-id"
    error_message = "Expected pipeline_id to be passed through unchanged"
  }
}

run "rejects_empty_routes" {
  command = plan

  variables {
    routes = []
  }

  expect_failures = [
    var.routes,
  ]
}

run "rejects_invalid_pipeline_type" {
  command = plan

  variables {
    routes = [
      {
        description   = "Bad route"
        matcher       = "true"
        pipeline_type = "not-a-real-type"
      }
    ]
  }

  expect_failures = [
    var.routes,
  ]
}

run "rejects_custom_route_missing_pipeline_id" {
  command = plan

  variables {
    routes = [
      {
        description   = "Missing pipeline_id"
        matcher       = "true"
        pipeline_type = "custom"
      }
    ]
  }

  expect_failures = [
    var.routes,
  ]
}

run "rejects_builtin_route_missing_builtin_pipeline_id" {
  command = plan

  variables {
    routes = [
      {
        description   = "Missing builtin_pipeline_id"
        matcher       = "true"
        pipeline_type = "builtin"
      }
    ]
  }

  expect_failures = [
    var.routes,
  ]
}
