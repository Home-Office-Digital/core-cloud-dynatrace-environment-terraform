resource "dynatrace_document" "launchpad" {
  type      = "launchpad"
  name      = var.launchpad_name
  content   = jsonencode(var.launchpad_content)
  private   = false
}

resource "dynatrace_default_launchpad" "default_launchpad" {
  group_launchpads {
    group_launchpad{
      content {
        is_enabled    = true
        launchpad_id  = dynatrace_document.launchpad.id
        user_group_id = "d3ffb1e7-4d8f-465e-8b37-98feaa2c1748" #Everyone
      }
    }
  }
}