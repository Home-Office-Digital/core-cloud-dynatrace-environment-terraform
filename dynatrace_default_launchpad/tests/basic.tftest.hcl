mock_provider "dynatrace" {}

variables {
  launchpad_name = "Operations launchpad"
  launchpad_content = {
    sections = []
    version  = 1
  }
  launchpad_custom_id = "operations-launchpad"
  launchpad_private   = false
  group_launchpads = [
    {
      user_group_id = "00000000-0000-0000-0000-000000000001"
      is_enabled    = true
    }
  ]
}

run "plan_creates_launchpad_document_and_default_assignment" {
  command = plan

  assert {
    condition     = output.document_name == "Operations launchpad"
    error_message = "Expected launchpad document name to match input."
  }
}