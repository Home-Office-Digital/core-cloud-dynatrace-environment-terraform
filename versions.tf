terraform {
  # check blocks (root main.tf, and dynatrace_log_pipeline's own
  # non_tier1_rules_must_be_disabled check) require Terraform >= 1.5. Without
  # this constraint, an older Terraform binary hits a confusing syntax error
  # on the check block itself rather than a clear version-mismatch message.
  required_version = ">= 1.5.0"
}
