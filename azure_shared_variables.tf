# Comes from AWS Secrets Manager via TF_VAR from the pipeline, not tenant_vars.yaml.
variable "azure_client_secrets" {
  description = "Map of Azure connection name -> client secret, keyed like tenant_vars.azure_connections."
  type        = map(string)
  default     = {}
  sensitive   = true
}
