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
   when `principal_object_id` is set) - the region/tag/security-context
   scope and feature-set selection.

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

`application_id`, `directory_id`, `principal_object_id`, and `client_secret`
are all dedicated sensitive module inputs, **not** `tenant_vars` keys - none
of them are committed to `tenant_vars.yaml`. All four come from the same AWS
Secrets Manager secret (`cc-dynatrace-azure-credentials`), as a per-connection
object: `{"<connection name>": {"application_id": "...", "directory_id": "...", "principal_object_id": "...", "client_secret": "..."}}`,
via a dedicated per-secret IAM role -> the terragrunt pipeline's
`TF_VAR_azure_connection_secrets` (see `azure_shared_variables.tf`).
`principal_object_id` may be omitted from a connection's object - unset means
connection-only, no monitoring config.

## Example `tenant_vars.yaml`

Everything identity/credential-related now lives in AWS Secrets Manager, so a
minimal connection-only entry needs no fields at all:

```yaml
azure_connections:
  AIaaSDev: {}
```

Full setup, with monitoring configuration (matches `tenants/global/dev/tenant_vars.yaml`):

```yaml
azure_connections:
  AIaaSDev:
    deployment_scope: "SUBSCRIPTION"
    regions: ["uksouth", "ukwest", "global", "westeurope"]
    security_context:
      literal: "aiaas"
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `connection_name` | Name of the connection (the `tenant_vars.azure_connections` map key) | `string` | n/a | yes |
| `tenant_vars` | Per-connection config (non-identity fields) - see field list in `variables.tf` | `any` | n/a | yes |
| `application_id` | Application (client) ID, from AWS Secrets Manager | `string` (sensitive) | n/a | yes |
| `directory_id` | Directory (tenant) ID, from AWS Secrets Manager | `string` (sensitive) | n/a | yes |
| `principal_object_id` | Service Principal Object ID, from AWS Secrets Manager | `string` (sensitive) | `null` | no |
| `client_secret` | Azure app registration client secret, from AWS Secrets Manager | `string` (sensitive) | n/a | yes |

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
