mock_provider "dynatrace" {}

variables {
  connection_name = "AIaaSDev"
  client_secret   = "mock-secret"
  tenant_vars = {
    application_id = "11111111-1111-1111-1111-111111111111"
    directory_id   = "22222222-2222-2222-2222-222222222222"
  }
}

run "plan_creates_azure_connection" {
  command = plan

  assert {
    condition     = dynatrace_azure_connection.this.name == "AIaaSDev"
    error_message = "Expected connection name to match connection_name input"
  }

  assert {
    condition     = dynatrace_azure_connection.this.type == "clientSecret"
    error_message = "Expected connection type to be clientSecret"
  }

  assert {
    condition     = dynatrace_azure_connection.this.client_secret[0].application_id == "11111111-1111-1111-1111-111111111111"
    error_message = "Expected application_id to be passed through from tenant_vars"
  }

  assert {
    condition     = dynatrace_azure_connection.this.client_secret[0].directory_id == "22222222-2222-2222-2222-222222222222"
    error_message = "Expected directory_id to be passed through from tenant_vars"
  }

  assert {
    condition     = dynatrace_azure_connection.this.client_secret[0].client_secret == "mock-secret"
    error_message = "Expected client_secret to be passed through from the dedicated client_secret input, not tenant_vars"
  }

  assert {
    condition     = length(dynatrace_azure_connection.this.client_secret[0].consumers) == 0
    error_message = "Expected consumers to default to an empty list when tenant_vars omits it"
  }

  assert {
    condition     = length(dynatrace_hub_extension_v2_config.monitoring_config) == 0
    error_message = "Expected monitoring config to be skipped when principal_object_id is not set in tenant_vars"
  }
}

run "plan_creates_monitoring_config_when_principal_object_id_set" {
  # apply, not plan: value embeds dynatrace_azure_connection.this.id, which is
  # unknown until the connection is actually created.
  command = apply

  variables {
    connection_name = "AIaaSDev"
    client_secret   = "mock-secret"
    tenant_vars = {
      application_id      = "11111111-1111-1111-1111-111111111111"
      directory_id        = "22222222-2222-2222-2222-222222222222"
      consumers            = ["SVC:com.dynatrace.da"]
      principal_object_id = "33333333-3333-3333-3333-333333333333"
      regions              = ["uksouth", "westeurope"]
      deployment_scope     = "SUBSCRIPTION"
    }
  }

  assert {
    condition     = length(dynatrace_hub_extension_v2_config.monitoring_config) == 1
    error_message = "Expected monitoring config to be created when principal_object_id is set"
  }

  assert {
    condition     = dynatrace_hub_extension_v2_config.monitoring_config[0].name == "com.dynatrace.extension.da-azure"
    error_message = "Expected the fixed extension name to be used"
  }

  assert {
    condition     = dynatrace_hub_extension_v2_config.monitoring_config[0].scope == "integration-azure"
    error_message = "Expected the fixed scope to be used"
  }

  assert {
    condition     = jsondecode(dynatrace_hub_extension_v2_config.monitoring_config[0].value).azure.credentials[0].principalObjectId == "33333333-3333-3333-3333-333333333333"
    error_message = "Expected principal_object_id to be passed through into azure.credentials[0].principalObjectId"
  }

  assert {
    condition     = jsondecode(dynatrace_hub_extension_v2_config.monitoring_config[0].value).azure.credentials[0].servicePrincipalId == "11111111-1111-1111-1111-111111111111"
    error_message = "Expected application_id to be passed through into azure.credentials[0].servicePrincipalId"
  }

  assert {
    condition     = tolist(jsondecode(dynatrace_hub_extension_v2_config.monitoring_config[0].value).azure.locationFiltering) == tolist(["uksouth", "westeurope"])
    error_message = "Expected regions to be passed through as locationFiltering"
  }

  assert {
    condition     = jsondecode(dynatrace_hub_extension_v2_config.monitoring_config[0].value).azure.deploymentScope == "SUBSCRIPTION"
    error_message = "Expected deployment_scope override to be passed through"
  }

  assert {
    condition     = length(jsondecode(dynatrace_hub_extension_v2_config.monitoring_config[0].value).featureSets) > 0
    error_message = "Expected featureSets to default to the built-in list when tenant_vars omits it"
  }

  assert {
    condition     = length(dynatrace_azure_connection.this.client_secret[0].consumers) == 1
    error_message = "Expected consumers to be passed through from tenant_vars when set"
  }

  assert {
    condition     = !contains(keys(jsondecode(dynatrace_hub_extension_v2_config.monitoring_config[0].value).azure), "dtLabelsEnrichment")
    error_message = "Expected dtLabelsEnrichment to be omitted entirely when tenant_vars.security_context is not set"
  }
}

run "plan_creates_dt_security_context_enrichment_when_set" {
  command = apply

  variables {
    connection_name = "AIaaSDev"
    client_secret   = "mock-secret"
    tenant_vars = {
      application_id      = "11111111-1111-1111-1111-111111111111"
      directory_id        = "22222222-2222-2222-2222-222222222222"
      principal_object_id = "33333333-3333-3333-3333-333333333333"
      security_context = {
        literal = "aiaas"
      }
    }
  }

  assert {
    condition     = jsondecode(dynatrace_hub_extension_v2_config.monitoring_config[0].value).azure.dtLabelsEnrichment["dt.security_context"].literal == "aiaas"
    error_message = "Expected security_context to be passed through into azure.dtLabelsEnrichment['dt.security_context']"
  }
}

run "monitoring_config_skipped_when_principal_object_id_is_null" {
  command = plan

  variables {
    connection_name = "AIaaSDev"
    client_secret   = "mock-secret"
    tenant_vars = {
      application_id      = "11111111-1111-1111-1111-111111111111"
      directory_id        = "22222222-2222-2222-2222-222222222222"
      principal_object_id = null
    }
  }

  assert {
    condition     = length(dynatrace_hub_extension_v2_config.monitoring_config) == 0
    error_message = "Expected monitoring config to be skipped when principal_object_id is present but null, not just when the key is absent"
  }
}

run "monitoring_config_skipped_when_principal_object_id_is_blank" {
  command = plan

  variables {
    connection_name = "AIaaSDev"
    client_secret   = "mock-secret"
    tenant_vars = {
      application_id      = "11111111-1111-1111-1111-111111111111"
      directory_id        = "22222222-2222-2222-2222-222222222222"
      principal_object_id = "   "
    }
  }

  assert {
    condition     = length(dynatrace_hub_extension_v2_config.monitoring_config) == 0
    error_message = "Expected monitoring config to be skipped when principal_object_id is present but blank"
  }
}

run "client_secret_validation_rejects_empty_value" {
  command = plan

  variables {
    connection_name = "AIaaSDev"
    client_secret   = ""
    tenant_vars = {
      application_id = "11111111-1111-1111-1111-111111111111"
      directory_id   = "22222222-2222-2222-2222-222222222222"
    }
  }

  expect_failures = [
    var.client_secret,
  ]
}
