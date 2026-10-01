# Ephemeral secret proof for Glue API Destination

## Purpose

This note records the Terraform experiment for using an ephemeral AWS Secrets
Manager value with the Glue EventBridge API Destination.

The experiment proves two separate facts:

1. The AWS provider supports the ephemeral resource
   `ephemeral.aws_secretsmanager_secret_version`.
2. Terraform does not allow that ephemeral value to be passed to
   `aws_cloudwatch_event_connection.auth_parameters.api_key.value`.

The production Glue module therefore remains deployable and uses either the
local `DYNATRACE_API_TOKEN` override or the existing Secrets Manager data source.

## Ephemeral resource supported by the AWS provider

Terraform 1.11 or later and the current AWS provider expose this resource:

```hcl
ephemeral "aws_secretsmanager_secret_version" "dynatrace_api_token" {
  secret_id = data.aws_secretsmanager_secret.dynatrace_api_token[0].id
}
```

The value can be read ephemerally:

```hcl
ephemeral.aws_secretsmanager_secret_version.dynatrace_api_token.secret_string
```

The ephemeral value is not intended to be persisted in Terraform state or plan
files by itself.

## Attempted EventBridge integration

The direct API Destination requires the Dynatrace token in the EventBridge
Connection:

```hcl
resource "aws_cloudwatch_event_connection" "dynatrace" {
  authorization_type = "API_KEY"

  auth_parameters {
    api_key {
      key   = "Authorization"
      value = "Api-Token ${ephemeral.aws_secretsmanager_secret_version.dynatrace_api_token.secret_string}"
    }
  }
}
```

Terraform rejected this configuration during validation with:

```text
Error: Invalid use of ephemeral value

Ephemeral values are not valid for "auth_parameters", because it is not an
assignable attribute.
```

## Reason

Terraform ephemerality is end-to-end. An ephemeral value can only flow into a
compatible ephemeral context or a provider-supported write-only argument.

The AWS provider marks the EventBridge API key as sensitive, but not write-only:

```text
auth_parameters.api_key.value
  required: true
  sensitive: true
  write-only: false
```

Sensitive means the value is hidden from normal CLI output. It does not mean the
value is omitted from Terraform state. Because the EventBridge connection is a
normal managed resource, Terraform must pass and track its authorization value.

## Conclusion

An ephemeral Secrets Manager block cannot solve state exposure for this direct
EventBridge Connection implementation. Implementing it in the production module
would make Terraform validation fail.

The supported choices are:

- **Direct API Destination:** simpler architecture, but the connection token may
  be stored in Terraform state. Protect encrypted remote state accordingly.
- **Lambda runtime secret retrieval:** Lambda reads the token at invocation time;
  the token is not passed through a Terraform resource argument.
- **Manually created EventBridge Connection:** AWS manages the connection secret;
  Terraform references the existing ARN and does not manage the credential value.

## References

- [Terraform ephemeral resources](https://developer.hashicorp.com/terraform/plugin/framework/ephemeral-resources)
- [Terraform sensitive data](https://developer.hashicorp.com/terraform/language/state/sensitive-data)
- [AWS provider EventBridge Connection](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_connection)
- [Terraform write-only arguments](https://developer.hashicorp.com/terraform/plugin/framework/resources/write-only-arguments)
