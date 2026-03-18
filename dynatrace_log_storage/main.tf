
resource "dynatrace_log_storage" "dynatrace_log_storage_rule" {
  count = length(var.rules)

  name              = var.rules[count.index].name
  enabled           = var.rules[count.index].enabled
  send_to_storage   = var.rules[count.index].send_to_storage

  dynamic "matchers" {
    for_each = var.rules[count.index].matchers
    content {
      matcher {
        attribute = matchers.value.attribute
        operator  = "MATCHES" # According to https://registry.terraform.io/providers/dynatrace-oss/dynatrace/latest/docs/resources/log_storage this is the only possible value for this block and better be hardcoded here.
        values    = matchers.value.values
      }
    }
  }
}
