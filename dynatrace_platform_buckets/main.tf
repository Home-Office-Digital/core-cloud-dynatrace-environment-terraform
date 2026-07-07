resource "dynatrace_platform_bucket" "platform_bucket" {
  name         = var.name
  retention    = var.retention
  table        = var.table
  display_name = var.display_name
}
