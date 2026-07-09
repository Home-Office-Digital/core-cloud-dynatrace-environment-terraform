terraform {
  required_providers {
    dynatrace = {
      version = "~> 1.0"
      source  = "dynatrace-oss/dynatrace"
    }
  }
}

resource "dynatrace_kubernetes_enrichment" "this" {
  scope = "environment"

  rules {
    rule {
      type   = "LABEL"
      source = "project-id"
      target = "dt.security_context"
    }
  }
}