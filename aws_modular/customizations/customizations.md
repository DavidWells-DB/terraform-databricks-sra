# Customizations

Customizations are **Terraform code** available to support the baseline deployment of the **Security Reference Architecture (SRA) - Terraform Templates**.

Customizations are sectioned by providers:
- **Workspace**: Databricks workspace provider.

The current customizations available are:

| Provider                    | Customization                 | Summary |
|-----------------------------|-------------------------------|---------|
| **Workspace** | **Workspace Admin Configurations** | Workspace administration configurations can be enabled to align with security best practices. The Terraform resource is experimental and optional, with documentation on each configuration provided in the Terraform file. |
| **Workspace** | **IP Access Lists** | IP Access can be enabled to restrict console access to a subset of IPs. **NOTE:** Ensure IPs are accurate to prevent lockout scenarios. |
| **Workspace** | **Security Analysis Tool (SAT)** | The Security Analysis Tool evaluates a customer’s Databricks account and workspace security configurations, providing recommendations that align with Databricks’ best practices. This can be enabled within the workspace. |
| **Workspace** | **Audit Log Alerting** | Based on this [blog post](https://www.databricks.com/blog/improve-lakehouse-security-monitoring-using-system-tables-databricks-unity-catalog), Audit Log Alerting creates 40+ SQL alerts to monitor incidents following a Zero Trust Architecture (ZTA) model. **NOTE:** This configuration creates a cluster, a job, and queries within your environment. |
| **Workspace** | **Read-Only External Location** | Creates a read-only external location in Unity Catalog for a specified bucket, as well as the corresponding AWS IAM role. |

---

## Using customizations with the main template

- Use the core template flags in `aws/tf` to choose between creating or reusing resources:
  - Network: `network_configuration` = "custom" or "isolated"; optionally set `custom_vpc_id`, `custom_private_subnet_ids`, `custom_sg_id`, `custom_workspace_vpce_id`, `custom_relay_vpce_id`.
  - Governance/Network: reuse existing `use_existing_network_connectivity_configuration_id`, `use_existing_network_policy_id`.
  - Storage/KMS: reuse `use_existing_root_bucket_name`, `use_existing_workspace_storage_kms_key_arn|alias`, `use_existing_managed_services_kms_key_arn|alias`.
  - IAM: reuse `use_existing_cross_account_role_arn`.
  - Feature toggles: `enable_uc_catalog_creation`, `enable_system_tables`, `enable_restrictive_root_bucket_policy`, `enable_disable_legacy_settings`, `enable_classic_cluster`, `enable_user_workspace_assignment`, `enable_security_analysis_tool`.

- Helpful outputs from the core template for wiring customizations:
  - `effective_workspace_id`, `effective_workspace_url`
  - `effective_root_bucket_name`, `effective_cross_account_role_arn`
  - `effective_ncc_id`, `effective_network_policy_id`

- SAT note: if `enable_security_analysis_tool = true`, ensure your network policy allowlists PyPI as required for package install.