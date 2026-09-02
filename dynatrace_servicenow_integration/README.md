This folder contains the module to create/manage the ServiceNow integration and the associated alerting rules.

## Resource vs terraform_data

The module was originally created using the `dynatrace_webhook_notification` terraform resource; however as the `client_secret` attribute within the resource is stored as clear text within the state file, as a security measure, until the issue is resolved/addressed, the more fragile/complex `terraform_data` is deployed. Please refer to the `terraform_data.servicenow_integration` resource within the [main.tf](./main.tf) file and the relevant terraform documentations to learn more.

### Environment variables/terraform_data

The `terraform_data` mentioned above deploys a couple of scripts 

- [integration_helper](./integration_utils/integration_helper) which calls
- [create_integration](./integration_utils/create_integration)

For creating and deleting the integration. 

> [!NOTE]  
> Due to the nature of `terraform_data` which creates and/or replaces (meaning if there is any change the resource will be destroyed and recreated), there will not be an 'update-in-place' like a dedicated terraform resource.

Information from terraform will be passed on to the script as environment variables. Please refer to the `terraform_data.servicenow_integration` resource within the [main.tf](./main.tf) file where environment variables are passed on to the script.

## Known Issues

### Hardcoded integration name

Currently this module handles only one integration and therefore, to prevent any malfunction, have the integration name hard-coded. Though may not be needed at all, if required, must be handled in a separate ticket and make careful modifications to the script.

In futrue, this module, if needed, can be extended to handle multiple external webhook integrations - either using the terraform resource or through the terraform_data.

