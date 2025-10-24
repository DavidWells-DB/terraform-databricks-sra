# Terraform Documentation: https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/service_principal

data "databricks_user" "workspace_access" {
  user_name = var.workspace_access
}

resource "databricks_mws_permission_assignment" "workspace_access" {
  workspace_id = var.workspace_id
  principal_id = data.databricks_user.workspace_access.id
  permissions  = ["ADMIN"]

  lifecycle {
    ignore_changes = [principal_id]
  }
}

# Optionally grant ADMIN to a Service Principal (the Terraform runner)
data "databricks_service_principal" "tf_runner" {
  count        = var.grant_sp_admin && var.sp_client_id != null ? 1 : 0
  application_id = var.sp_client_id
}

resource "databricks_mws_permission_assignment" "tf_runner_admin" {
  count        = var.grant_sp_admin && var.sp_client_id != null ? 1 : 0
  workspace_id = var.workspace_id
  principal_id = data.databricks_service_principal.tf_runner[0].id
  permissions  = ["ADMIN"]
}

output "tf_runner_admin_principal_id" {
  value       = var.grant_sp_admin && var.sp_client_id != null ? data.databricks_service_principal.tf_runner[0].id : null
  description = "Principal ID of the Terraform runner SP if granted admin"
}

# Optionally grant ADMIN to a User (the Terraform runner)
data "databricks_user" "tf_runner_user" {
  count     = var.executor_user_email != null && var.grant_sp_admin ? 1 : 0
  user_name = var.executor_user_email
}

resource "databricks_mws_permission_assignment" "tf_runner_user_admin" {
  count        = var.executor_user_email != null && var.grant_sp_admin ? 1 : 0
  workspace_id = var.workspace_id
  principal_id = data.databricks_user.tf_runner_user[0].id
  permissions  = ["ADMIN"]
}

# Optionally grant long-term ADMIN to an Admin SP alongside admin_user
data "databricks_service_principal" "admin_sp" {
  count         = var.admin_sp_client_id != null ? 1 : 0
  application_id = var.admin_sp_client_id
}

resource "databricks_mws_permission_assignment" "admin_sp" {
  count        = var.admin_sp_client_id != null ? 1 : 0
  workspace_id = var.workspace_id
  principal_id = data.databricks_service_principal.admin_sp[0].id
  permissions  = ["ADMIN"]
}