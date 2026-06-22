# Please note: 
#   A shared variable file, called `servicenow_shared_variables.tf`, 
#   contains more variable definition to share the variable 
#   definition with the `dynatrace_servicenow_integration` module 
#   which would come from the AWS secrets from the terragrunt 
#   pipeline, as TF_VARS.

variable "tenant_vars" {
  type = any
}

variable "slack_webhook_urls" {
  type        = map(string)
  description = "A map with slack webhook urls for various modules, appropriately keyed."
  default     = {} # Provided to ignore when the module is skipped in an environment.
  sensitive   = true
}

variable "terragrunt_dir" {
  description = "Original terragrunt working directory outside .terragrunt-cache."
  type        = string
}