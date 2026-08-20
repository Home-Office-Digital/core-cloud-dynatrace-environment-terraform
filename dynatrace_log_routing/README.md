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
      description   = "Route to default OpenPipeline logs entry (base pipeline via its mandatory default member)"
      matcher       = "true"
      pipeline_type = "custom"
      # Computed from another module's real output, not hard-coded. Note this
      # points at dynatrace_log_pipeline_group's mandatory default_member
      # pipeline, never a base one directly - see that module's README for
      # why a base pipeline that's part of a group can't be a routing target
      # at all. This is what makes "logs use the base pipeline by default"
      # true with zero extra config - no separate member pipeline to declare.
      pipeline_id   = module.dynatrace_log_pipeline_group[0].default_member_pipeline_id
    },
  ]
}
```

At the root module level this is driven by a `log_routing` block in tenant
configuration. The calling module (`main.tf`) builds `routes` in three
tiers, in this order:

1. Any explicitly named `log_pipeline_members` entries (one route per key,
   sorted alphabetically) - only relevant once team-specific member
   pipelines with real, distinguishing matchers exist. Empty by default.
2. `dynatrace_log_pipeline_group`'s mandatory `default_member_pipeline_id`,
   always last among these, with a `"true"` catch-all matcher - the
   guaranteed fallback that catches anything the tier-1 entries didn't.
3. `routes_before` / `routes_after` from tenant config, for entries that
   must exist in the live table but aren't managed by either of the above
   (e.g. routes to pipelines this repo doesn't own).

```yaml
log_routing:
  allow_manage_existing_routing: true
  routes_before: []
  routes_after: []
```

**A named `log_pipeline_members` entry does NOT automatically get a route.**
A member pipeline is a valid, complete object on its own - the platform has
no requirement that every member be paired with a routing entry. Set
`create_route: true` on a member once it's actually meant to be reachable;
left unset (default `false`), the member still gets created (and still
joins the pipeline group) but produces no entry in `routes` at all - no
inert placeholder route cluttering the table for a pipeline that isn't
ready to receive traffic yet.

**Every ROUTED named `log_pipeline_members` entry (`create_route: true`)
needs its own real `routing_matcher`** (see `dynatrace_log_pipeline_member`'s
README) - the calling module's `check` block fails plan if more than one
routed member is left on the default `"true"` catch-all, since routes are
first-match-wins and only the first would ever fire. Members with
`create_route` not set to `true` are excluded from that check entirely,
since they don't produce a route to be ambiguous about. The pipeline
group's own `default_member` catch-all is separately, deliberately exempt
too - it's supposed to be `"true"`, that's what makes it the fallback.

```yaml
log_pipeline_members:
  nginx_test:
    custom_id: logs-tenant-nginx-test
    display_name: "Nginx test member"
    # No create_route (defaults false): this pipeline exists and is part of
    # the group, but has no routing_entry at all - nothing reaches it yet.
    metric_extraction_rules: [...]
```

Because the catch-all route is computed from
`dynatrace_log_pipeline_group`'s output, `log_routing` cannot be enabled
without `log_pipeline_group` also being set - a separate `check` block in
the calling module enforces this too.

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
