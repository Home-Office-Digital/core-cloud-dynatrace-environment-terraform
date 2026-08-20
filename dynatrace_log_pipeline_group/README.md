# Dynatrace Log Pipeline Group Module

This module manages a `dynatrace_openpipeline_v2_logs_pipelinegroups`
resource - the construct that wraps one or more platform-owned **base
pipelines** around a placeholder position where any of several
team-owned **member pipelines** (see `dynatrace_log_pipeline_member`) run,
per Dynatrace's [pipeline groups](https://docs.dynatrace.com/docs/shortlink/openpipeline-pipeline-groups)
concept.

A pipeline group is what makes "base pipeline enforces bucket
routing/security context on every tenant, tenants can only self-service
metric extraction" an actual platform guarantee rather than a convention
that relies on every team's pipeline being configured correctly.

## This module can optionally create a "default member" for you

A base pipeline can never be routed to directly (see below) - a group is
unreachable without at least one member pipeline wrapped around it.
`create_default_member` (default `true`) controls whether this module
creates one itself internally (`module.default_member`, controlled by
`default_member_custom_id`/`default_member_display_name`/
`default_member_metric_extraction_rules`) so a caller doesn't have to
separately declare and wire up a `dynatrace_log_pipeline_member` instance
just to make the group functional. By default it's a plain catch-all
pass-through with no metric-extraction rules of its own.

**Set `create_default_member = false` once real, explicitly-declared member
pipelines exist via `member_pipeline_ids`** - there's no reason to keep an
inert internal fallback around once a real one is doing the job. The
`create_default_member_requires_a_reachable_member` check block refuses to
apply if this is set to `false` while `member_pipeline_ids` is also empty -
the group would have zero members and be entirely unreachable.

`member_pipeline_ids` is available for *additional* (or, with
`create_default_member = false`, the *only*) explicitly named
team-specific member pipelines, each with their own metric-extraction
rules.

## Mandate vs. Restrict - two separate, complementary controls

- **Mandate** (`base_pipelines[*].mandate_stages_type`/`mandate_stages`, this
  module's `composition` block): declares which of a *base* pipeline's own
  stages execute as part of this composition. `mandate_stages_type =
  "includeAll"` (recommended for a base pipeline) is unrestricted - every
  stage that pipeline has configured runs, nothing filtered out. Use
  `"include"`/`"exclude"` with `mandate_stages` instead to narrow a specific
  base pipeline down to only some of its configured stages, if that's ever
  needed for a multi-base composition (see Dynatrace's
  [multi-cloud ingest governance tutorial](https://docs.dynatrace.com/docs/platform/openpipeline/use-cases/pipeline-groups-multicloud)
  for an example of chaining several base pipelines, each mandating a
  different stage subset).
- **Restrict** (`member_stages_*`, this module's `member_stages` block):
  declares which stages *member* pipelines are allowed to run at all. This
  is the governance boundary - a member pipeline's own HCL cannot make a
  restricted stage execute, regardless of what that pipeline configures.

## Base pipelines must already be `group_role = "basePipeline"`, `routing = "notRoutable"`

Per Dynatrace's own routing/role table: a custom pipeline that's both
`basePipeline` and part of a group **cannot be routed to directly** -
that's not a limitation, it's how the group is invoked. Routing a record to
a *member* pipeline that's part of a group causes the whole composition
(every mandated base-pipeline stage, then the member) to execute - the base
pipeline(s) are only reachable that way. Don't add a `dynatrace_log_routing`
entry pointing at a base pipeline; it will be rejected or simply never
receive anything.

## ⚠️ Pipeline role is permanent - this is not an in-place migration

Dynatrace's docs are explicit: *"The pipeline role is permanent. Converting
roles - from member to base, or base to member - isn't supported."*
If a pipeline you want to use as this group's base was previously a
standalone/member pipeline (as opposed to being purpose-built as a base
pipeline from the start), it must be recreated with a new `custom_id` and
`group_role = "basePipeline"` - there's no `terraform apply` that flips the
role of an existing pipeline object.

**Do this as two separate, deliberate applies, not one:**

1. **Phase 1 - additive only.** Declare the new base pipeline, new member
   pipeline(s), and this group, and re-point `dynatrace_log_routing` at the
   new member. Critically, *keep the old pipeline declared* too - via the
   plain `dynatrace_log_pipeline` module, same as the base, but left out of
   this module's `base_pipelines` and out of every `dynatrace_log_routing`
   route entry. That combination (still declared, but unrouted and not part
   of the group's composition) makes it go inert - no traffic - without
   Terraform destroying it. A `terraform plan` for phase 1 should show only
   creates and one routing-table update, never a destroy.
2. **Phase 2 - the actual retirement, later.** Once you've verified (e.g. in
   Grail) that logs are landing in the right buckets via the new base+member
   pair, remove the old pipeline's declaration entirely, as its own
   standalone config change. That's what makes Terraform destroy it - review
   that plan in isolation so the destroy is the only thing in it.

At the root module level, `main.tf` calls this the `log_pipeline_legacy`
list: pipelines declared in `log_pipeline_base`-shaped config so
`dynatrace_log_pipeline` keeps managing them, but never fed into this
module's `base_pipelines` and never given a route - see the root `main.tf`
locals and `core-cloud-dynatrace-terragrunt`'s tenant config for the actual
phase-1 declaration.

## This resource is net-new for most tenants - probably no import needed

Unlike `dynatrace_log_pipeline` (which almost always adopts a tenant's
pre-existing base "logs" pipeline), a pipeline group is an opt-in construct
most tenants won't already have one of. Before the first apply, confirm in
the Dynatrace UI (OpenPipeline → Pipeline groups) that nothing already
exists under this `display_name`/for these pipelines - if something does,
treat it the same way `dynatrace_log_pipeline`'s README treats an existing
base pipeline: import it and review the plan for drift before applying.

## IAM/OAuth scope

This resource needs `settings:objects:read`/`write` **scoped to the
`pipeline-groups` schema** (`builtin:openpipeline.logs.pipeline-groups`),
which is distinct from whatever already authorizes
`dynatrace_openpipeline_v2_logs_pipelines`. Confirm the Terraform OAuth
client's IAM policy grants this schema group before the first apply - a
generic `settings:objects:*` grant that happens to already cover pipelines
does not automatically cover pipeline groups.

## Example usage

```hcl
module "dynatrace_log_pipeline_group" {
  source = "./dynatrace_log_pipeline_group"

  display_name = "Tenant Logs Pipeline Group"

  base_pipelines = [
    {
      pipeline_id         = module.dynatrace_log_pipeline["tiered_log_bucket_router_base"].id
      mandate_stages_type = "includeAll"
    },
  ]

  member_stages_type    = "include"
  member_stages_include = ["metricExtraction"]

  default_member_custom_id    = "logs-default-entry"
  default_member_display_name = "Default log entry (all logs)"

  # Optional: additional named member pipelines, beyond the mandatory
  # default_member above. Empty until team-specific self-service pipelines
  # are actually needed.
  member_pipeline_ids = [for k, m in module.dynatrace_log_pipeline_member : m.id]
}
```

At the root module level this is driven by a `log_pipeline_group` block in
tenant configuration; `base_pipelines` is computed from the tenant's
`log_pipeline_base` list (each entry's own `mandate_stages_type`/
`mandate_stages`) and `member_pipeline_ids` from every declared
`log_pipeline_members` entry (if any - it's optional now) - see `main.tf`
and those modules' READMEs.
Nothing here needs updating when a new tenant/team member pipeline is added
elsewhere in config.

```yaml
log_pipeline_group:
  display_name: "Tenant Logs Pipeline Group"
  member_stages:
    type: include
    include: [metricExtraction]
  default_member:
    custom_id: logs-default-entry
    display_name: "Default log entry (all logs)"
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `display_name` | Display name of the pipeline group | `string` | n/a | yes |
| `member_placeholder_position` | `"before"` or `"after"` - where the member placeholder sits relative to `base_pipelines` in composition order. Only observable for stage types configured on both sides (e.g. `processing`, if `member_stages` allows it). | `string` | `"after"` | no |
| `base_pipelines` | Ordered list of `{ pipeline_id, mandate_stages_type, mandate_stages }` - the composition chain wrapped around the member placeholder, on whichever side `member_placeholder_position` puts it. `mandate_stages_type` defaults to `"include"`; set to `"includeAll"` for an unrestricted base pipeline (`mandate_stages` then unused). | `list(object(...))` | `[]` | no |
| `member_stages_type` | `include`, `exclude`, or `includeAll` | `string` | `"include"` | no |
| `member_stages_include` | Stages members may run, when `member_stages_type = "include"` | `list(string)` | `[]` | no |
| `member_stages_exclude` | Stages members may NOT run, when `member_stages_type = "exclude"` | `list(string)` | `[]` | no |
| `create_default_member` | Whether to create the internal default member pipeline. Set `false` once real `member_pipeline_ids` exist - a `check` block refuses to apply if both this is `false` and `member_pipeline_ids` is empty. | `bool` | `true` | no |
| `default_member_custom_id` | `custom_id` for the default member. Required (checked via a `check` block, not a `validation` block - see variables.tf) only when `create_default_member = true`. | `string` | `null` | no |
| `default_member_display_name` | Display name for the default member. Required under the same condition as `default_member_custom_id`. | `string` | `null` | no |
| `default_member_metric_extraction_rules` | Metric-extraction rules for the default member (when created) - same shape as `dynatrace_log_pipeline_member`'s `metric_extraction_rules` | `list(object(...))` | `[]` | no |
| `member_pipeline_ids` | IDs of member pipelines wrapped by this group, in addition to the default member (if created) | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| `id` | The pipeline group's real resource id |
| `default_member_pipeline_id` | Real id of the default member pipeline, or `null` if `create_default_member = false`. Route `dynatrace_log_routing`'s fallback entry here when non-null - a base pipeline can never be routed to directly. |
| `member_pipeline_count` | Total number of member pipelines wrapped by this group (default member, if created, plus `member_pipeline_ids`) |

## Provider resource reference

[`dynatrace_openpipeline_v2_logs_pipelinegroups`](https://registry.terraform.io/providers/dynatrace-oss/dynatrace/latest/docs/resources/openpipeline_v2_logs_pipelinegroups)
