# Dynatrace Platform Buckets Module

This module manages Dynatrace Grail platform buckets as code.

## Example

```hcl
module "dynatrace_platform_buckets" {
  source = "./dynatrace_platform_buckets"

  name         = "cc-logs"
  display_name = "CC logs bucket"
  retention    = 35
  table        = "logs"
}
```
