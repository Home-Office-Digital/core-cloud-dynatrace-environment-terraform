# Comes from AWS Secrets Manager via TF_VAR from the pipeline, not tenant_vars.yaml.
variable "azure_connection_secrets" {
  description = "Map of Azure connection name -> {application_id, directory_id, principal_object_id, client_secret}, keyed like tenant_vars.azure_connections."
  type = map(object({
    application_id      = string
    directory_id         = string
    principal_object_id  = optional(string)
    client_secret        = string
  }))
  default   = {}
  sensitive = true
}
