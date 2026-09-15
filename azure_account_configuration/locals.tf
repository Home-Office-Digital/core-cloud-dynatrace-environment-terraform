locals {
  # coalesce() itself errors when every argument is null/empty - try() catches that case.
  monitoring_config_enabled = try(trimspace(coalesce(var.principal_object_id, "")) != "", false)

  default_azure_feature_sets = [
    "microsoft_apimanagement.service_essential",
    "microsoft_app.containerapps_essential",
    "microsoft_cache.redis_essential",
    "microsoft_cache.redisenterprise_essential",
    "microsoft_cognitiveservices.accounts_aiservices_essential",
    "microsoft_cognitiveservices.accounts_openai_essential",
    "microsoft_compute.virtualmachines_essential",
    "microsoft_compute.virtualmachinescalesets_essential",
    "microsoft_devices.iothubs_essential",
    "microsoft_documentdb.databaseaccounts_essential",
    "microsoft_eventhub.namespaces_essential",
    "microsoft_logic.workflows_essential",
    "microsoft_network.applicationgateways_essential",
    "microsoft_network.loadbalancers_essential",
    "microsoft_servicebus.namespaces_essential",
    "microsoft_sql.servers.databases_essential",
    "microsoft_storage.storageaccounts.blobservices_essential",
    "microsoft_storage.storageaccounts.fileservices_essential",
    "microsoft_storage.storageaccounts.queueservices_essential",
    "microsoft_storage.storageaccounts.tableservices_essential",
    "microsoft_storage.storageaccounts_essential",
    "microsoft_web.sites_app_essential",
    "microsoft_web.sites_functionapp_essential",
    "microsoft_web.sites_functionapp_workflowapp_essential",
  ]
}
