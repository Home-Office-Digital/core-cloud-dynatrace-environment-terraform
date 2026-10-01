# AWS Glue job events to Dynatrace

Captures Glue job start requests and final stop/failure states with EventBridge,
then posts them directly to the Dynatrace Events API v2 through an EventBridge
API destination.

The EventBridge connection uses an ephemeral Secrets Manager value. The token
must include the Dynatrace `events.ingest` scope. The POC intentionally tests
whether this ephemeral value can be passed into the EventBridge connection.

The secret must exist in the same AWS account and region as the module, and the
Terraform deployment role must be allowed to read it and decrypt its KMS key.

Set `DYNATRACE_API_TOKEN_SECRET_ID` locally when you want to test a different
Secrets Manager secret identifier. Do not commit secret values.

## Signals

- Start: CloudTrail `StartJobRun` API calls, represented as `START_REQUESTED`.
- Stop: native Glue Job State Change events with state `STOPPED`.
- Failure: native Glue Job State Change events with state `FAILED` or `TIMEOUT`.

Capturing start requests requires an active CloudTrail trail that records Glue
management events in every relevant account and region. A start request does
not prove that the job reached `RUNNING`.

## Tenant configuration

Add a keyed entry to `tenant_vars.yaml`:

```yaml
glue_job_events:
  cc_glue:
    dynatrace_environment_url: "https://<environment-id>.live.dynatrace.com"
    dynatrace_api_token_secret_name: "cc-dynatrace-api-token"
    dynatrace_api_token_json_key: "DYNATRACE_API_TOKEN"
    job_names:
      - "example-job"
    tags:
      project-id: "cc"
      service-id: "dynatrace"
```

Omit `dynatrace_api_token_json_key` when the complete secret string is the API
token. Omit `job_names` to forward all Glue jobs in the deployment account and
region. The direct API destination sends lifecycle events as `CUSTOM_ALERT`.

Failed EventBridge API destination deliveries are retried and then stored in an
encrypted SQS dead-letter queue. Operational monitoring should alarm on visible
DLQ messages.
