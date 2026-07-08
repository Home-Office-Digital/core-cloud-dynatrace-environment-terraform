mock_provider "dynatrace" {}

variables {
  name         = "cc-logs"
  retention    = 35
  display_name = "CC logs bucket"
}

run "plan_creates_platform_bucket" {
  command = plan

  assert {
    condition     = output.name == "cc-logs"
    error_message = "Expected bucket name to match input"
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
    condition     = output.display_name == "CC logs bucket"
    error_message = "Expected display name to match input"
  }
}
