# Azure Account Configuration Module

Manages a Dynatrace "Gen3"/hyperscaler Azure cloud connection - the
credential object that lets Dynatrace poll an Azure subscription for
metric/entity ingestion, following the same shape as `aws_account_configuration`
(one connection per `tenant_vars.azure_connections` map entry).

## Two resources, two different APIs (HOOS-338)

1. **`dynatrace_azure_connection`** (always created) - the Entra ID app
   credential object (`application_id`, `directory_id`, `client_secret`,
   `consumers`). Settings 2.0 schema: `builtin:hyperscaler-authentication.connections.azure`.
   Confirmed against the [provider's resource docs](https://registry.terraform.io/providers/dynatrace-oss/dynatrace/latest/docs/resources/azure_connection).
2. **`dynatrace_hub_extension_v2_config.monitoring_config`** (created only
   when `tenant_vars.principal_object_id` is set) - the region/tag/
   security-context scope and feature-set selection.

**Resource 2 is a different API family, not a Settings 2.0 object.** It's an
Extensions Framework 2.0 (EF2) "monitoring configuration" for the
`com.dynatrace.extension.da-azure` extension, exposed via
`/api/v2/extensions/{name}/monitoringConfigurations` - the real object has a
plain UUID `objectId` and no `schemaId`, unlike every Settings 2.0 object.
`dynatrace_hub_extension_v2_config` takes `name` (fixed:
`com.dynatrace.extension.da-azure`), `scope` (fixed: `integration-azure`), and
`value` (a raw JSON string - Dynatrace's own docs for this resource say the
shape "differs depending on the Extension," so it can't be more structured
than that).

### Confirmed JSON shape for `value`

```json
{
  "enabled": true,
  "description": "<connection name>",
  "version": "1.1.8",
  "featureSets": ["microsoft_compute.virtualmachines_essential", "..."],
  "activationContext": "DATA_ACQUISITION",
  "azure": {
    "credentials": [
      {
        "description": "<connection name>",
        "enabled": true,
        "connectionId": "<dynatrace_azure_connection.this.id>",
        "servicePrincipalId": "<application_id>",
        "principalObjectId": "<Service Principal Object ID - see below>",
        "type": "SECRET"
      }
    ],
    "locationFiltering": ["uksouth", "ukwest", "global", "westeurope"],
    "subscriptionFiltering": [],
    "subscriptionFilteringMode": "INCLUDE",
    "tagFiltering": [],
    "tagEnrichment": [],
    "useIngestEnrichmentConfig": false,
    "dtLabelsEnrichment": {
      "dt.security_context": { "literal": "aiaas" }
    },
    "smartscapeConfiguration": { "enabled": true },
    "eventHubsConfiguration": [],
    "namespaces": [],
    "manualDeploymentStatus": "NA",
    "deploymentScope": "SUBSCRIPTION"
  }
}
```

### `dt.security_context` enrichment - confirmed shape

**`dtLabelsEnrichment` is a separate top-level field from `tagEnrichment`**,
easy to conflate since both are enrichment-related. `tagEnrichment` is
unrelated to `dt.security_context` - `dtLabelsEnrichment` is what actually
carries it. Confirmed shape for a literal value:
`{ "dt.security_context": { "literal": "aiaas" } }`. Set via
`tenant_vars.security_context` (passed through verbatim, so the tenant_vars
value must already use the exact keys Dynatrace expects - `literal`, or
presumably `tagKey` for a tag-derived value per Dynatrace's dtctl docs, though
that variant hasn't been independently confirmed). The module omits the whole
`dtLabelsEnrichment` key (not even an empty object) when
`tenant_vars.security_context` isn't set, matching what a connection with no
enrichment configured actually looks like.

### `principal_object_id` vs `application_id` - don't confuse these

The **Principal ID** AIaaS provided (alongside Application ID, Client ID,
Directory ID) is the Azure AD **Service Principal's Object ID** - a different
object from the Application ID, and it's what Azure RBAC role assignments
actually point at. It does **not** appear on `dynatrace_azure_connection` at
all - it only shows up here, as `azure.credentials[0].principalObjectId`, on
the monitoring configuration. `application_id` gets reused here too, oddly
named `servicePrincipalId` in this JSON (Dynatrace's own naming, not this
module's).

### `deployment_scope` default

The module defaults to `"SUBSCRIPTION"` - the confirmed intended value for
this ticket's use case. The ticket's own "future recommendations" section
flags management-group-level integration as a separate, unexplored future
initiative - not what this connection should use today.

### `extension_version` needs verifying per environment

`com.dynatrace.extension.da-azure` version `1.1.8` is this module's default,
but the active version can differ per environment/tenant - check via the Hub
or `dynatrace_hub_extension_active_version` before trusting the default in a
new environment.

## Secrets

`client_secret` is a dedicated sensitive module input, **not** a `tenant_vars`
key - it must never be committed to `tenant_vars.yaml`. It's sourced the same
way `SERVICENOW_CLIENT_SECRET` is (see `azure_shared_variables.tf`): AWS
Secrets Manager -> a dedicated per-secret IAM role -> the terragrunt
pipeline's `TF_VAR_azure_client_secrets` (a `map(string)` keyed by connection
name, mirroring `slack_webhook_urls`).

`application_id`/`directory_id`/`principal_object_id` are not secret (they're
app registration identifiers, not the secret itself) and live in
`tenant_vars.yaml` like any other AWS connection field.

## Example `tenant_vars.yaml`

Connection object only, no monitoring configuration (no entities/metrics -
this is what "1 added" with nothing visible in the Clouds app means):

```yaml
azure_connections:
  AIaaSDev:
    application_id: "<Entra ID app's Application (client) ID>"
    directory_id: "<Entra ID Directory (tenant) ID>"
```

Full setup, with monitoring configuration (matches `tenants/hoos/dev/tenant_vars.yaml`):

```yaml
azure_connections:
  AIaaSDev:
    application_id: "<Entra ID app's Application (client) ID>"
    directory_id: "<Entra ID Directory (tenant) ID>"
    principal_object_id: "<Service Principal Object ID - NOT application_id>"
    deployment_scope: "SUBSCRIPTION"
    regions: ["uksouth", "ukwest", "global", "westeurope"]
    security_context:
      literal: "aiaas"
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `connection_name` | Name of the connection (the `tenant_vars.azure_connections` map key) | `string` | n/a | yes |
| `tenant_vars` | Per-connection config - see field list in `variables.tf` | `any` | n/a | yes |
| `client_secret` | Azure app registration client secret | `string` (sensitive) | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| `connection_id` | Real resource ID of the Dynatrace Azure connection |
| `monitoring_config_id` | Real resource ID of the monitoring configuration, or `null` if `principal_object_id` was not set |

## Provider resource reference

- [`dynatrace_azure_connection`](https://registry.terraform.io/providers/dynatrace-oss/dynatrace/latest/docs/resources/azure_connection)
- [`dynatrace_hub_extension_v2_config`](https://registry.terraform.io/providers/dynatrace-oss/dynatrace/latest/docs/resources/hub_extension_v2_config)

## Provider version

`dynatrace_azure_connection` needs a recent provider release (confirmed
present as of `1.104.0`; this repo's `.terraform.lock.hcl` files are
currently pinned to `1.103.0`). Run `terraform init -upgrade` for this module
before first use - do not hand-edit the lock file.
