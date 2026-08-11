resource "dynatrace_document" "launchpad" {
  type      = "launchpad"
  name      = var.launchpad_name
  content   = jsonencode(var.launchpad_content)
  custom_id = var.launchpad_custom_id
  private   = var.launchpad_private
}

resource "dynatrace_default_launchpad" "default_launchpad" {
  group_launchpads {
    dynamic "group_launchpad" {
      for_each = var.group_launchpads
      content {
        is_enabled    = group_launchpad.value.is_enabled
        launchpad_id  = dynatrace_document.launchpad.id
        user_group_id = group_launchpad.value.user_group_id
      }
    }
  }
}