# Dynatrace Log Routing Module

This module manages the tenant's **Dynamic Routing table** for logs
(`dynatrace_openpipeline_v2_logs_routing`) - the ordered list of matcher →
pipeline rules that decides which OpenPipeline pipeline actually receives each
incoming log record, before any of that pipeline's own processing or storage
stages ever run.

## ⚠️ This is a singleton resource - it replaces the ENTIRE table on every apply

Unlike `dynatrace_openpipeline_v2_logs_pipelines` (one resource per pipeline),
there is exactly **one** routing table per tenant, and this resource's own
provider docs warn:

> Deploying an OpenPipeline routing configuration will overwrite the existing
> one of the same kind, causing any manual changes made in the web UI or other
> routing configurations managed by Terraform or Monaco to be lost.

A `routes` list that's missing an entry doesn't leave that entry alone - it
**deletes** it from the live tenant on apply. There is no partial update.

**Before this module is ever applied against a tenant for the first time**,
get the exact live table rather than reconstruct it from the UI:

```
terraform-provider-dynatrace -export dynatrace_openpipeline_v2_logs_routing
```

This writes the real `routing_entries` (exact matchers, exact `pipeline_id`
values, exact order) as ready HCL to local files. Reconcile `routes_before` /
`routes_after` in the calling tenant config against that output before the
first real apply, then confirm `terraform plan` shows the expected diff.

## The "Default route" is not a real, manageable object

The UI shows a `Default route` entry (matcher `true`) pointing at the
tenant's built-in Classic pipeline, marked read-only ("Built-in elements
can't be edited"). It does **not** appear in the `-export` output and has no
`routing_entry` representation at all - it's a platform-injected fallback
that always exists beneath whatever entries this module declares, not
something to include in `routes`. Don't invent a `builtin_pipeline_id` entry
to represent it; there isn't one.

To make a pipeline receive traffic ahead of that fallback, add a route with
a broad/catch-all matcher (e.g. `"true"`) *above* it in priority instead of
trying to edit or replace it.

## Avoid hard-coding other teams' pipeline ids

`pipeline_id` for a `custom` route target is the pipeline's opaque real id,
not its `custom_id`/display name, and this provider has no data source to
look one up by name. For a pipeline this module wiring doesn't own (e.g. a
route to some other team's pipeline), a hard-coded id will silently go stale
if that pipeline is ever recreated. Prefer computing it from a resource/module
output when possible (see the example below), and think twice before taking
on management of a route to a pipeline you don't otherwise own - it may be
simpler to leave it out of `routes` if it's inert (disabled) or not yours to
maintain.

## Example usage

```hcl
module "dynatrace_log_routing" {
  source = "./dynatrace_log_routing"

  # Safety gate: set true only after reconciling `routes` against a real
  # `-export` of the tenant's live routing table.
  allow_manage_existing_routing = true

  routes = [
    {
      description   = "Route to platform OpenPipeline logs pipeline"
      matcher       = "true"
      pipeline_type = "custom"
      # Computed from another module's real output, not hard-coded:
      pipeline_id   = module.dynatrace_log_bucket_assignment["platform"].id
    },
  ]
}
```

At the root module level this is driven by a `log_routing` block in tenant
configuration. `dynatrace_log_bucket_assignment` is called with `for_each`,
keyed by category (e.g. `platform`, `security`) - the calling module
(`main.tf`) injects one route per category automatically, computed from that
category's own `module.dynatrace_log_bucket_assignment[<key>].id`, ordered
alphabetically by key. `routes_before` / `routes_after` in tenant config only
need to supply *other* entries that must exist in the live table (e.g. routes
to pipelines this repo doesn't manage):

```yaml
log_routing:
  allow_manage_existing_routing: true
  routes_before: []
  routes_after: []
```

**Every category needs its own real `routing_matcher`** (set per-category,
alongside that category's `log_bucket_assignment` entry - see that module's
README) once there's more than one. Routes are first-match-wins; two
categories both left on the default `"true"` catch-all means only the
alphabetically-first one ever receives anything - the calling module's `check`
block catches this and fails plan with a clear message rather than leaving a
category silently unreachable.

Because each category's route is computed from `dynatrace_log_bucket_assignment`'s
output, `log_routing` cannot be enabled without `log_bucket_assignment` also
being set - a separate `check` block in the calling module enforces this too.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `allow_manage_existing_routing` | Safety gate. Must be `true` before this module will manage the routing table. Use only after reconciling `routes` against a real `-export`. | `bool` | `false` | no |
| `routes` | Ordered list of `{ description, enabled, matcher, pipeline_type, builtin_pipeline_id, pipeline_id }` routing entries, highest priority first. Must reproduce every entry that should exist live - see the warning above. | `list(object(...))` | n/a | yes |

`pipeline_type` is `"builtin"` or `"custom"`. Use `builtin_pipeline_id` for a
`builtin` target (rare - see the Default route note above) and `pipeline_id`
for a `custom` target.

## Outputs

| Name | Description |
|------|-------------|
| `route_count` | Number of routing entries applied |

## Provider resource reference

[`dynatrace_openpipeline_v2_logs_routing`](https://registry.terraform.io/providers/dynatrace-oss/dynatrace/latest/docs/resources/openpipeline_v2_logs_routing)
