# Ephemeral Secrets Manager proof

This example contains a real Terraform `ephemeral` block for the AWS provider.
It reads a Secrets Manager value during Terraform execution without declaring a
managed secret-version resource in state.

It intentionally does not connect the ephemeral value to the production
`aws_cloudwatch_event_connection` resource. Terraform rejects that connection
because `auth_parameters.api_key.value` is sensitive but not write-only.

## Run locally

```bash
cd glue_job_events/examples/ephemeral-secret

export AWS_REGION=eu-west-2
export SECRET_ID=cc-dynatrace-api-token

terraform init
terraform plan -var="secret_id=$SECRET_ID"
terraform state list
```

The plan reads the secret and evaluates the check. `terraform state list` should
not contain an `aws_secretsmanager_secret_version` resource because the read is
ephemeral.

Do not print the secret value or commit it to source control. The AWS identity
running the command needs permission to read the secret and decrypt its KMS key.
