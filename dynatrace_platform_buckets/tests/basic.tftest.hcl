mock_provider "dynatrace" {}

variables {
  name         = "cc-playground-logs"
  retention    = 35
  table        = "logs"
  display_name = "Custom logs bucket playground"
}

run "plan_creates_platform_bucket_for_playground" {
  command = plan

  assert {
    condition     = output.name == "cc-playground-logs"
    error_message = "Expected playground bucket name to match input"
  }

  assert {
    condition     = output.table == "logs"
    error_message = "Expected bucket table to be logs"
  }

  assert {
    condition     = output.retention == 35
    error_message = "Expected bucket retention to match input"
  }

  assert {
    condition     = output.display_name == "Custom logs bucket playground"
    error_message = "Expected display name to match playground bucket naming"
  }
}
