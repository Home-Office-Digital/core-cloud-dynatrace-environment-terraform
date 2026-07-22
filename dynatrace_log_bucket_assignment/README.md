# Dynatrace Log Bucket Assignment Module

This module manages the **storage stage** of an existing Dynatrace OpenPipeline logs pipeline (`dynatrace_openpipeline_v2_logs_pipelines`), adding an ordered list of `bucketAssignment` processors that route logs into specific Grail buckets (e.g. the tiered `platform_buckets` created via the `dynatrace_platform_buckets` module) based on a DQL matcher.

Rules are evaluated in the order given — the first matching rule wins. Always include a catch-all entry last (`matcher = "true"`) so records that don't match any specific rule still land somewhere predictable, rather than silently falling through to whatever the pipeline's default/unassigned behaviour is.

## ⚠️ Read before first apply: this resource owns the whole pipeline, not just storage

`dynatrace_openpipeline_v2_logs_pipelines` is a **per-pipeline** resource — one Terraform resource maps to one pipeline's *entire* definition (`processing`, `cost_allocation`, `metric_extraction`, `storage`, etc.), not just the part this module declares. This module only ever writes the `storage` stage.

If the pipeline referenced by `pipeline_custom_id` already exists (which it almost always will — most tenants have a built-in base "logs" pipeline) and has live configuration in stages this module doesn't declare, applying this module for the first time without first importing that pipeline risks silently clearing those other stages.

**Before the first real apply against a tenant:**
1. `terraform import dynatrace_openpipeline_v2_logs_pipelines.log_bucket_assignment <pipeline_custom_id>`
2. `terraform plan` and inspect the diff carefully — if it proposes removing/clearing any stage other than `storage`, that stage's configuration needs to be added to this module (or the calling module) as static blocks matching the imported state before you apply for real.

## ⚠️ `group_role` / `routing` interaction, and renaming

- The API rejects `routing = "routable"` on any pipeline with `group_role = "basePipeline"` — a base pipeline structurally cannot be a Dynamic Routing target. If this pipeline needs to receive traffic via a dynamic route (see `dynatrace_log_routing`), it must be `group_role = "memberPipeline"` with `routing = "routable"` set explicitly — the module's own default (`basePipeline`) will not work for that case.
- `custom_id` is immutable. Changing `pipeline_custom_id` (e.g. a rename) forces Terraform to destroy the old pipeline and create a new one. This module sets `lifecycle { create_before_destroy = true }` specifically so the new pipeline exists (and anything referencing its `id`, like `dynatrace_log_routing`, can re-point to it) *before* the old one is destroyed — without that, the destroy fails outright if the old pipeline's id is still referenced elsewhere (e.g. the dynamic routing table), since the API refuses to delete an object something else still points to.

## Example usage

```hcl
module "dynatrace_log_bucket_assignment" {
  source = "./dynatrace_log_bucket_assignment"

  # Safety gate: set true only after importing the existing pipeline and
  # reviewing a clean plan for non-storage stages.
  allow_manage_existing_pipeline = true

  pipeline_custom_id    = "logs"
  pipeline_display_name = "logs"
  # memberPipeline + routable: required if this pipeline should receive traffic
  # via a dynamic route (see dynatrace_log_routing). The default, basePipeline,
  # cannot be made routable - the API rejects that combination.
  group_role            = "memberPipeline"
  routing               = "routable"

  # Transition toggle: only rules whose id matches this regex can stay enabled.
  enforce_tier1_only_active = true
  tier1_rule_id_regex       = "tier1"

  rules = [
    {
      id          = "processor_kubernetes_info_tier1"
      description = "Kubernetes info logs to tier1"
      matcher     = "isNotNull(k8s.namespace.name) and loglevel == \"INFO\""
      bucket_name = "kubernetes_info_tier1"
    },
    {
      id          = "processor_catch_all"
      description = "Anything unmatched"
      matcher     = "true"
      bucket_name = "unknown"
    },
  ]
}
```

At the root module level this is driven by a `log_bucket_assignment` block in tenant configuration:

```yaml
log_bucket_assignment:
  allow_manage_existing_pipeline: true
  pipeline_custom_id: "logs"
  pipeline_display_name: "logs"
  group_role: "memberPipeline"
  routing: "routable"
  enforce_tier1_only_active: true
  tier1_rule_id_regex: "tier1"
  rules:
    - id: "processor_kubernetes_info_tier1"
      description: "Kubernetes info logs to tier1"
      matcher: 'isNotNull(k8s.namespace.name) and loglevel == "INFO"'
      bucket_name: "kubernetes_info_tier1"
    - id: "processor_catch_all"
      description: "Anything unmatched"
      matcher: "true"
      bucket_name: "unknown"
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `allow_manage_existing_pipeline` | Safety gate. Must be `true` before this module will manage an existing pipeline. Use only after import and plan review. | `bool` | `false` | no |
| `pipeline_custom_id` | `custom_id` of the existing pipeline to manage | `string` | n/a | yes |
| `pipeline_display_name` | Display name of the pipeline | `string` | n/a | yes |
| `group_role` | `basePipeline`, `compositionPipeline`, or `memberPipeline` | `string` | `"basePipeline"` | no |
| `routing` | `notRoutable` or `routable`; left `null` so existing routing isn't overridden unless explicitly set | `string` | `null` | no |
| `enforce_tier1_only_active` | If `true`, all non-tier1 rules must have `enabled = false`. The catch-all rule (`matcher = "true"`) is always exempt from this, regardless of its id, since it isn't tier-scoped. | `bool` | `false` | no |
| `tier1_rule_id_regex` | Regex used to classify rule IDs as tier1 when enforcement is enabled | `string` | `"tier1"` | no |
| `rules` | Ordered list of `{ id, description, enabled, matcher, bucket_name }` bucket-assignment rules. `description` defaults to `""`, `enabled` defaults to `true`. | `list(object(...))` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| `id` | The pipeline's real resource id (not `custom_id`) - reference this from anything that needs to point at the pipeline, e.g. a `dynatrace_log_routing` route entry, so it can't drift if the pipeline is ever recreated |
| `pipeline_custom_id` | The managed pipeline's `custom_id` |
| `pipeline_display_name` | The managed pipeline's `display_name` |
| `rule_count` | Number of rules applied |

## Matcher syntax

`matcher` is a DQL boolean expression, evaluated against each log record. Field names for distinguishing log source category (e.g. Kubernetes vs. Host vs. Cloud) and severity level are tenant/ingestion-pipeline specific — verify actual field names against real log records in the target tenant (Logs app → inspect a record's attributes) rather than assuming standard semantic-convention names, the same way `dynatrace_log_storage`'s README notes the public Dynatrace docs don't reliably describe valid values for adjacent settings.

## Testing

```
terraform init -backend=false
terraform validate
terraform test
```

`tests/basic.tftest.hcl` uses `mock_provider "dynatrace" {}` and asserts against `plan` output only — it does not apply against a real tenant.

## Provider resource reference

[`dynatrace_openpipeline_v2_logs_pipelines`](https://registry.terraform.io/providers/dynatrace-oss/dynatrace/latest/docs/resources/openpipeline_v2_logs_pipelines) — note the *deprecated* `dynatrace_openpipeline_logs` (singular, environment-wide) resource is a different, older resource and should not be used; it manages every pipeline in the environment as one resource, which is a much larger blast radius than this module's per-pipeline scope.
