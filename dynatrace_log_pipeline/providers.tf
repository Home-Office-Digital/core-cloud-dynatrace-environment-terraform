terraform {
  # This module's own non_tier1_rules_must_be_disabled check block requires
  # Terraform >= 1.5 - declared here so a consumer on an older Terraform binary
  # gets a clear version-mismatch error instead of a confusing check-block
  # syntax error.
  required_version = ">= 1.5.0"

  required_providers {
    dynatrace = {
      version = "~> 1.0"
      source  = "dynatrace-oss/dynatrace"
    }
  }
}
