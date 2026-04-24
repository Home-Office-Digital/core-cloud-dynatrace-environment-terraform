# core-cloud-dynatrace-environment-terraform
[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit)](https://github.com/pre-commit/pre-commit)


This terraform module is used to create Dynatrace environment specific resources.

## Developer setup

This repository is designed to use pre commit hooks as part of the [pre-commit framework](https://pre-commit.com). To setup please follow the instructions on the pre-commit website to install it locally and then run `pre-commit install` to install the hooks. These are managed in [.pre-commit-config.yaml](.pre-commit-config.yaml)

## Metrics to monitor

By default, services defined in the [default\_metrics.yaml](default_metrics.yaml) will be monitored on all the aws connections specified in the input (from the terragrunt repo).

This set of services can be _topped up_ or _completely replaced_ by including/altering relavant sections as specified in the https://github.com/Home-Office-Digital/core-cloud-dynatrace-terragrunt documentation.

## Management Zones

Management Zones are maintained by the [dynatrace_management_zones module](https://github.com/Home-Office-Digital/core-cloud-dynatrace-environment-terraform/blob/main/dynatrace_management_zones) in the core-cloud-dynatrace-environment-terraform repo.
Zones can be created per-Dynatrace instance by adding a block to the corresponding environment section of the [config.yaml](config.yaml) file.
For example, in order to configure a Management Zone for the "Core Cloud Test" Dynatrace:

```
corecloud_dynatracetest:
  management_zones:
  YourZoneName:
    rules:
      some_rule_name:
        type: "ME"
        enabled: true
        attribute_rule:
          entity_type: "AWS_ACCOUNT"
          attribute_conditions:
            condition:
              key: "AWS_ACCOUNT_ID"
              operator: "NOT_EQUALS"
              string_value: "992382599151"
              case_sensitive: true
```

In the example above, the first entry "YourZoneName" will be used as the literal name for the Zone within the Dynatrace UI.
Inside the 'rules' block, descriptive rule names are recommended for readability of the config file (to explain the intended purpose of the underlying rule).
The rule name provided (in this case "some_rule_name") will not actually be used/visible in the actual Dynatrace Console
Further parameters, such as the type of rule (in this case 'attribute_rule') and the relevant conditions, will map to the possible dropdown/field inputs in the Dynatrace UI.

Similarly to the above attribute_rule example, a dimension rule can be created by setting a "dimension_rule" block inside a rule definition. The dimension-specific parameters are then entered (such as whether it applies to logs, metrics or both) and the conditions (structured similarly to the attribute rule):

```
corecloud_dynatracetest:
  management_zones:
  YourZoneName:
    rules:
      additional_rule:
        type: "DIMENSION"
        enabled: true
        dimension_rule:
          applies_to: "METRIC"
          dimension_conditions:
            condition:
              condition_type: "METRIC_KEY"
              rule_matcher: "BEGINS_WITH"
              value: "cloud.gcp."
```

Setting any 'Rules' for a Management Zone is entirely optional, but opening a "Rules" block will require at least one contained rule to be created, or else the pipeline will fail.

For information on further options and attributes for the Zone and the Rules (whether 'attribute' or 'dimension') contained therein, please refer to the [Dynatrace Documentation](https://docs.dynatrace.com/docs/manage/identity-access-management/permission-management/management-zones) and the base [Terraform for the v2 resource](https://registry.terraform.io/providers/dynatrace-oss/dynatrace/latest/docs/resources/management_zone_v2) to clarify required/optional arguments.


<!-- BEGIN_TF_DOCS -->


## Anomaly detection 
This Terraform module provisions various Dynatrace anomaly detection configurations, including:

dynatrace_aws_anomalies

custom_anomalies

dynatrace_k8s_node_anomalies

dynatrace_k8s_workload_anomalies


Required Inputs
aws_anomaly_settings – Object defining AWS anomaly detection thresholds and toggles.

custom_anomalies_settings – List of custom anomaly detection rules.

k8s_node_anomalies_settings – List of K8s node anomaly rules.

k8s_workload_anomalies_settings – List of K8s workload anomaly rules

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_dynatrace"></a> [dynatrace](#requirement\_dynatrace) | ~> 1.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_dynatrace"></a> [dynatrace](#provider\_dynatrace) | ~> 1.0 |

## Modules

No modules.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_connections"></a> [aws\_connections](#input\_aws\_connections) | A map of AWS Connections to create. The key is the name of the connection. | <pre>map(object({<br/>    account_id = string<br/>    iam_role  = string<br/>    optional_services_top_up = map(object)<br/>    optional_exclusive_services = map(object)<br/>}))</pre> | `{}` | no (Both the the `optional_services_top_up` and `optional_exclusive_services` can either be empty or completely omitted.)|

## Outputs

No outputs.
<!-- END_TF_DOCS -->
