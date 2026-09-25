# AWS Glue job events to Dynatrace

Captures Glue job start requests and final stop/failure states with EventBridge,
then posts them to the Dynatrace Events API v2 through Lambda.

The Lambda reads the Dynatrace API token from Secrets Manager at runtime. The
token is not read by Terraform and is not stored in Terraform state. The token
must include the Dynatrace `events.ingest` scope.

The secret must exist in the same AWS account and region as the module. The
module grants its Lambda role `secretsmanager:GetSecretValue`. If the secret
also has a restrictive resource policy, allow the role ARN exposed by the
module's `lambda_role_arn` output. Supply `dynatrace_api_token_kms_key_arn` when
the secret uses a customer-managed KMS key.

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
    alert_states:
      - "START_REQUESTED"
      - "STOPPED"
      - "FAILED"
      - "TIMEOUT"
    tags:
      project-id: "cc"
      service-id: "dynatrace"
```

Omit `dynatrace_api_token_json_key` when the complete secret string is the API
token. Omit `job_names` to forward all Glue jobs in the deployment account and
region. Remove lifecycle states from `alert_states` to ingest them as
`CUSTOM_INFO` instead of problem-opening `CUSTOM_ALERT` events.

Failed EventBridge deliveries and Lambda asynchronous invocations are stored in
an encrypted SQS dead-letter queue after their respective retries. Operational
monitoring should alarm on visible DLQ messages.
