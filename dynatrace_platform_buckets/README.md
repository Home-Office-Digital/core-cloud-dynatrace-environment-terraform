# Dynatrace Platform Buckets Module

This module manages Dynatrace Grail platform buckets as code.

## Example

```hcl
module "dynatrace_platform_buckets" {
  source = "./dynatrace_platform_buckets"

  name         = "cc-playground-logs"
  display_name = "Custom logs bucket playground"
  retention    = 35
  table        = "logs"
}
```
