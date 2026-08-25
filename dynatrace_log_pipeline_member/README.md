# Dynatrace Log Pipeline Member Module

This module manages a single tenant/team-owned **member pipeline**
(`dynatrace_openpipeline_v2_logs_pipelines` with `group_role = "memberPipeline"`,
`routing = "routable"`) that only ever configures the **processing**
(`fieldsAdd`) and **metric extraction** stages - deriving fields (for
example, `loglevel` from raw content) and counting or measuring values out
of log records the team already owns.

It is deliberately narrow: `group_role` and `routing` are hardcoded inside
this module, not exposed as inputs, and there is no way to configure
`security_context` or `storage` here at all - those stay base-pipeline-only,
enforced by the pipeline group's `member_stages`.

## ⚠️ This is one half of a governance boundary, not the whole thing

Restricting this module's own inputs stops someone from *accidentally*
wiring up a member pipeline with extra stages through this code path. It
does **not**, by itself, stop the Dynatrace API from running whatever stages
a member pipeline happens to have configured - that enforcement is the
`dynatrace_log_pipeline_group` module's `member_stages` restriction
(`type = "include", include = ["processing", "metricExtraction"]`), applied once this
pipeline is added to that group's `member_pipeline_ids`. A member pipeline
created by this module but never added to the group is unrestricted - it
must be paired with `dynatrace_log_pipeline_group` to actually be governed.

## Pipeline role is permanent

Per Dynatrace's own docs: *"The pipeline role is permanent. Converting
roles - from member to base, or base to member - isn't supported."* A
pipeline created with `group_role = "memberPipeline"` can never become a
base pipeline later (or vice versa) - if that's ever needed, it requires a
new pipeline with a new `custom_id`, not an in-place change.

## `custom_id` is immutable

Changing `custom_id` (e.g. a rename) forces Terraform to destroy the old
pipeline and create a new one. This module sets
`lifecycle { create_before_destroy = true }` so the new pipeline (and
anything referencing its `id`, like `dynatrace_log_routing` or the pipeline
group's `member_pipeline_ids`) exists before the old one is destroyed.

## Example usage

```hcl
module "dynatrace_log_pipeline_member" {
  source = "./dynatrace_log_pipeline_member"

  custom_id    = "logs-tenant-platform"
  display_name = "Platform team logs"

  metric_extraction_rules = [
    {
      id          = "metric_error_count"
      description = "Count ERROR-level records"
      matcher     = "loglevel == \"ERROR\""
      type        = "counterMetric"
      metric_key  = "log.platform.error.count"
    },
  ]
}
```

At the root module level this is driven by a `log_pipeline_members` map in
tenant configuration, keyed by tenant/team name - `main.tf` calls this
module with `for_each`, one member pipeline per key. Adding a new tenant is
purely a config addition: a new map entry here, plus a matching
`routing_matcher` (consumed by `dynatrace_log_routing`, see that module's
README) - no module code changes needed.

```yaml
log_pipeline_members:
  platform:
    custom_id: logs-tenant-platform
    display_name: "Platform team logs"
    routing_matcher: 'true'
    metric_extraction_rules:
      - id: metric_error_count
        description: "Count ERROR-level records"
        matcher: 'loglevel == "ERROR"'
        type: counterMetric
        metric_key: log.platform.error.count
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `custom_id` | `custom_id` of the member pipeline | `string` | n/a | yes |
| `display_name` | Display name of the member pipeline | `string` | n/a | yes |
| `metric_extraction_rules` | Ordered list of `{ id, description, enabled, matcher, type, metric_key, field, default_value, dimensions }` metric-extraction processors. `type` is `counterMetric` or `valueMetric`; `field` is required for `valueMetric`. `dimensions` is a list of `{ extraction_type, strategy, source_field_name, destination_field_name }`. | `list(object(...))` | `[]` | no |
| `processing_fields_add_rules` | Ordered list of `{ id, description, enabled, matcher, field_name, field_value }` processing-stage `fieldsAdd` processors, run before metric extraction and before the group's mandated storage stage. | `list(object(...))` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| `id` | The pipeline's real resource id - reference this from `dynatrace_log_routing` and from `dynatrace_log_pipeline_group`'s `member_pipeline_ids`, never hard-code it |
| `pipeline_custom_id` | The managed pipeline's `custom_id` |
| `pipeline_display_name` | The managed pipeline's `display_name` |
| `metric_rule_count` | Number of metric-extraction rules applied |
| `processing_rule_count` | Number of processing-stage rules applied |

## Matcher syntax

`matcher` is a DQL boolean expression evaluated against each log record.
`processing_fields_add_rules` matchers run against the raw record (typically
`content`), since nothing has derived fields yet at that point. Any field a
`metric_extraction_rules` matcher/dimension relies on must already exist on
the raw record, be set by this module's own `processing_fields_add_rules`
above it, or be added upstream by the group's base pipeline(s) - verify
field names against real records (Logs app) rather than assuming them.

## Provider resource reference

[`dynatrace_openpipeline_v2_logs_pipelines`](https://registry.terraform.io/providers/dynatrace-oss/dynatrace/latest/docs/resources/openpipeline_v2_logs_pipelines) -
same underlying resource as `dynatrace_log_pipeline`, just restricted by
convention (this module's own limited inputs) plus by the pipeline group's
`member_stages` enforcement to the processing and metric-extraction stages
only.
