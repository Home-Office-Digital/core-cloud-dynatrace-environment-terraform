# The following variable must come from the
# AWS secret from inside the terragrunt pipeline
# and would be passed as a TF_VAR from the pipeline.
# See azure_account_configuration/README.md for the secret's expected shape.
variable "azure_client_secrets" {
  description = "Map of Azure connection name -> client secret, keyed the same way as tenant_vars.azure_connections. Sourced from AWS Secrets Manager, never committed to tenant_vars.yaml."
  type        = map(string)
  default     = {} # Provided to ignore when no tenant declares azure_connections.
  sensitive   = true
}
