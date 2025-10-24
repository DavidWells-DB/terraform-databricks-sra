# =============================================================================
# Databricks Account Modules
# =============================================================================

# Create Unity Catalog Metastore
module "unity_catalog_metastore_creation" {
  source = "./modules/databricks_account/unity_catalog_metastore_creation"
  providers = {
    databricks = databricks.mws
  }

  region           = var.region
  metastore_exists = var.metastore_exists
  metastore_name   = var.metastore_name
}

# Create Network Connectivity Connection Object
module "network_connectivity_configuration" {
  count    = var.use_existing_network_connectivity_configuration_id == null ? 1 : 0
  source   = "./modules/databricks_account/network_connectivity_configuration"
  providers = {
    databricks = databricks.mws
  }

  region          = var.region
  resource_prefix = var.resource_prefix
}

# Create a Network Policy
module "network_policy" {
  count    = var.use_existing_network_policy_id == null ? 1 : 0
  source   = "./modules/databricks_account/network_policy"
  providers = {
    databricks = databricks.mws
  }

  databricks_account_id = var.databricks_account_id
  resource_prefix       = var.resource_prefix
}

# Create Databricks Workspace
module "databricks_mws_workspace" {
  source = "./modules/databricks_account/workspace"

  providers = {
    databricks = databricks.mws
  }

  # Basic Configuration
  databricks_account_id = var.databricks_account_id
  resource_prefix       = var.resource_prefix
  region                = var.region
  deployment_name       = var.deployment_name

  # Network Configuration
  vpc_id             = local.effective_custom_vpc_id != null ? local.effective_custom_vpc_id : module.vpc[0].vpc_id
  subnet_ids         = local.effective_custom_private_subnet_ids != null ? local.effective_custom_private_subnet_ids : module.vpc[0].private_subnets
  security_group_ids = local.effective_custom_sg_id != null ? [local.effective_custom_sg_id] : [aws_security_group.sg[0].id]
  backend_rest       = local.effective_custom_workspace_vpce_id != null ? local.effective_custom_workspace_vpce_id : aws_vpc_endpoint.backend_rest[0].id
  backend_relay      = local.effective_custom_relay_vpce_id != null ? local.effective_custom_relay_vpce_id : aws_vpc_endpoint.backend_relay[0].id

  # Cross-Account Role
  cross_account_role_arn = local.effective_use_existing_cross_account_role_arn != null ? local.effective_use_existing_cross_account_role_arn : aws_iam_role.cross_account_role[0].arn

  # Root Storage Bucket
  bucket_name = local.effective_use_existing_root_bucket_name != null ? local.effective_use_existing_root_bucket_name : aws_s3_bucket.root_storage_bucket[0].id

  # KMS Keys
  managed_services_key        = local.effective_use_existing_managed_kms_arn != null ? local.effective_use_existing_managed_kms_arn : (var.enable_cmk_managed_services ? aws_kms_key.managed_services[0].arn : null)
  workspace_storage_key       = local.effective_use_existing_workspace_kms_arn != null ? local.effective_use_existing_workspace_kms_arn : (var.enable_cmk_workspace_storage ? aws_kms_key.workspace_storage[0].arn : null)
  managed_services_key_alias  = local.effective_use_existing_managed_kms_alias != null ? local.effective_use_existing_managed_kms_alias : (var.enable_cmk_managed_services ? aws_kms_alias.managed_services_key_alias[0].name : null)
  workspace_storage_key_alias = local.effective_use_existing_workspace_kms_alias != null ? local.effective_use_existing_workspace_kms_alias : (var.enable_cmk_workspace_storage ? aws_kms_alias.workspace_storage_key_alias[0].name : null)

  # Network Connectivity Configuration and Network Policy
  network_connectivity_configuration_id = local.effective_use_existing_ncc_id != null ? local.effective_use_existing_ncc_id : module.network_connectivity_configuration[0].ncc_id
  network_policy_id                     = local.effective_use_existing_network_policy_id != null ? local.effective_use_existing_network_policy_id : module.network_policy[0].network_policy_id

  depends_on = [module.unity_catalog_metastore_creation]
}

# =============================
# Input validations (preconditions)
# =============================


locals {
  _kms_alias_ok = (
    (local.effective_use_existing_workspace_kms_arn == null && local.effective_use_existing_workspace_kms_alias == null) ||
    (local.effective_use_existing_workspace_kms_arn != null && local.effective_use_existing_workspace_kms_alias != null)
  ) && (
    (local.effective_use_existing_managed_kms_arn == null && local.effective_use_existing_managed_kms_alias == null) ||
    (local.effective_use_existing_managed_kms_arn != null && local.effective_use_existing_managed_kms_alias != null)
  )

  _custom_network_complete = var.network_configuration != "custom" ? true : (
    local.effective_custom_vpc_id != null &&
    local.effective_custom_private_subnet_ids != null && length(local.effective_custom_private_subnet_ids) > 0 &&
    local.effective_custom_sg_id != null &&
    local.effective_custom_workspace_vpce_id != null &&
    local.effective_custom_relay_vpce_id != null
  )

  _ip_acl_addresses_ok = !var.enable_ip_access_list || length(var.ip_access_list_addresses) > 0

  _read_only_ext_loc_ok = !var.enable_read_only_external_location || (
    var.read_only_data_bucket != "" && var.read_only_external_location_admin != ""
  )

  _sp_admin_ok = !var.grant_terraform_sp_workspace_admin || (
    (
      var.terraform_sp_client_id != null && var.executor_user_email == null
    ) || (
      var.executor_user_email != null && var.terraform_sp_client_id == null
    )
  )

  # Executor identity assertion (explicit inputs only; avoids env() in plan)
  # If you want strict checks, provide one of executor_user_email or executor_sp_client_id
  # so we can assert intent against admin_user.
  _executor_identity_ok = (
    var.executor_identity_check == "none"
  ) || (
    var.executor_identity_check == "must_match_admin_user" && var.executor_user_email != null && lower(var.executor_user_email) == lower(var.admin_user)
  ) || (
    var.executor_identity_check == "must_differ_from_admin_user" && (
      (var.executor_user_email != null && lower(var.executor_user_email) != lower(var.admin_user)) || var.executor_user_email == null
    )
  ) || (
    var.executor_identity_check == "must_match_admin_or_executor" && (
      (var.executor_user_email != null && lower(var.executor_user_email) == lower(var.admin_user)) ||
      (var.terraform_sp_client_id != null)
    )
  )

  _controlled_egress_ok = (
    var.network_configuration != "isolated" || !var.enable_controlled_egress
  ) || (
    var.network_configuration == "isolated" && var.enable_controlled_egress && length(var.public_subnets_cidr) > 0
  )
}

resource "null_resource" "validate_inputs" {
  triggers = {
    kms_alias_ok = local._kms_alias_ok ? "true" : "false"
  }

  lifecycle {
    precondition {
      condition     = local._kms_alias_ok
      error_message = "When providing KMS ARN via kms{} or individual variables, you must also provide the matching alias."
    }
    precondition {
      condition     = local._sp_admin_ok
      error_message = "When grant_terraform_sp_workspace_admin=true, you must provide exactly one of executor_user_email or executor_sp_client_id."
    }
    precondition {
      condition     = local._executor_identity_ok
      error_message = "Executor identity assertion failed: set executor_identity_check to none, must_match_admin_user, or must_differ_from_admin_user."
    }
    precondition {
      condition     = local._controlled_egress_ok
      error_message = "enable_controlled_egress requires non-empty public_subnets_cidr and applies only in isolated mode."
    }
  }
}

resource "null_resource" "validate_sat_auth" {
  triggers = {
    sat_auth_ok = (var.enable_security_analysis_tool && var.sat_use_sp_auth) ? ((var.sat_client_id != null && var.sat_client_secret != null) ? "true" : "false") : "true"
  }

  lifecycle {
    precondition {
      condition     = var.enable_security_analysis_tool == false || var.sat_use_sp_auth == false || (var.sat_client_id != null && var.sat_client_secret != null)
      error_message = "SAT: When sat_use_sp_auth=true, you must provide sat_client_id and sat_client_secret."
    }
  }
}

resource "null_resource" "validate_network_custom" {
  triggers = {
    custom_network_ok = local._custom_network_complete ? "true" : "false"
  }

  lifecycle {
    precondition {
      condition     = local._custom_network_complete
      error_message = "Custom networking requires network {} (or legacy variables) to include vpc_id, private_subnet_ids, sg_id, workspace_vpce_id, relay_vpce_id."
    }
  }
}

resource "null_resource" "validate_customizations" {
  triggers = {
    ip_acl_ok       = local._ip_acl_addresses_ok ? "true" : "false"
    ext_loc_ok      = local._read_only_ext_loc_ok ? "true" : "false"
  }

  lifecycle {
    precondition {
      condition     = local._ip_acl_addresses_ok
      error_message = "enable_ip_access_list = true requires at least one entry in ip_access_list_addresses."
    }
    precondition {
      condition     = local._read_only_ext_loc_ok
      error_message = "enable_read_only_external_location = true requires read_only_data_bucket and read_only_external_location_admin."
    }
  }
}

# Unity Catalog Assignment
module "unity_catalog_metastore_assignment" {
  source = "./modules/databricks_account/unity_catalog_metastore_assignment"
  providers = {
    databricks = databricks.mws
  }

  metastore_id = module.unity_catalog_metastore_creation.metastore_id
  workspace_id = module.databricks_mws_workspace.workspace_id

  depends_on = [module.unity_catalog_metastore_creation, module.databricks_mws_workspace]
}

# User Workspace Assignment (Admin)
module "user_assignment" {
  count  = var.enable_user_workspace_assignment ? 1 : 0
  source = "./modules/databricks_account/user_assignment"
  providers = {
    databricks = databricks.mws
  }

  workspace_id     = module.databricks_mws_workspace.workspace_id
  workspace_access = var.admin_user
  sp_client_id     = var.terraform_sp_client_id
  grant_sp_admin   = var.grant_terraform_sp_workspace_admin
  executor_user_email = var.executor_user_email
  admin_sp_client_id  = var.admin_sp_client_id

  depends_on = [module.unity_catalog_metastore_assignment, module.databricks_mws_workspace]
}

# Audit Log Delivery
module "log_delivery" {
  count  = var.audit_log_delivery_exists ? 0 : 1
  source = "./modules/databricks_account/audit_log_delivery"
  providers = {
    databricks = databricks.mws
  }

  databricks_account_id = var.databricks_account_id
  resource_prefix       = var.resource_prefix
  aws_assume_partition  = local.assume_role_partition
}

# =============================================================================
# Databricks Workspace Modules
# =============================================================================

# Creates a Workspace Isolated Catalog
module "unity_catalog_catalog_creation" {
  count  = var.enable_uc_catalog_creation ? 1 : 0
  source = "./modules/databricks_workspace/unity_catalog_catalog_creation"
  providers = {
    databricks = databricks.created_workspace
  }

  aws_account_id               = var.aws_account_id
  aws_iam_partition            = local.computed_aws_partition
  aws_assume_partition         = local.assume_role_partition
  unity_catalog_iam_arn        = local.unity_catalog_iam_arn
  resource_prefix              = var.resource_prefix
  uc_catalog_name              = "${var.resource_prefix}-catalog-${module.databricks_mws_workspace.workspace_id}"
  cmk_admin_arn                = var.cmk_admin_arn == null ? "arn:${local.computed_aws_partition}:iam::${var.aws_account_id}:root" : var.cmk_admin_arn
  workspace_id                 = module.databricks_mws_workspace.workspace_id
  user_workspace_catalog_admin = var.admin_user
  executor_user_email          = var.executor_user_email != null ? var.executor_user_email : ""
  admin_sp_client_id           = var.admin_sp_client_id
  terraform_sp_client_id       = var.terraform_sp_client_id

  depends_on = [module.unity_catalog_metastore_assignment, module.user_assignment]
}

# System Table Schemas Enablement
module "system_table" {
  count  = var.enable_system_tables && var.region != "us-gov-west-1" ? 1 : 0
  source = "./modules/databricks_workspace/system_schema"
  providers = {
    databricks = databricks.created_workspace
  }
  depends_on = [module.unity_catalog_metastore_assignment, module.user_assignment]
}

# Restrictive Root Buckt Policy
module "restrictive_root_bucket" {
  count  = var.enable_restrictive_root_bucket_policy ? 1 : 0
  source = "./modules/databricks_workspace/restrictive_root_bucket"
  providers = {
    aws = aws
  }

  databricks_account_id = var.databricks_account_id
  aws_partition         = local.computed_aws_partition
  databricks_gov_shard  = var.databricks_gov_shard
  workspace_id          = module.databricks_mws_workspace.workspace_id
  region_name           = var.databricks_gov_shard == "dod" ? var.region_name_config[var.region].secondary_name : var.region_name_config[var.region].primary_name
  root_s3_bucket        = var.use_existing_root_bucket_name != null ? var.use_existing_root_bucket_name : "${var.resource_prefix}-workspace-root-storage"
}

# Disable legacy settings like Hive Metastore, Disables Databricks Runtime prior to 13.3 LTS, DBFS, DBFS Mounts,etc.
module "disable_legacy_settings" {
  count  = var.disable_legacy_access_and_dbfs ? 1 : 0
  source = "./modules/databricks_workspace/disable_legacy_settings"
  providers = {
    databricks = databricks.created_workspace
  }
}

# Enable Compliance Security Profile (CSP) on the Databricks Workspace.
module "compliance_security_profile" {
  count  = var.enable_compliance_security_profile ? 1 : 0
  source = "./modules/databricks_workspace/compliance_security_profile"

  providers = {
    databricks = databricks.created_workspace
  }

  compliance_standards = var.compliance_standards
}

# Create Create Cluster
module "cluster_configuration" {
  count  = var.enable_classic_cluster ? 1 : 0
  source = "./modules/databricks_workspace/classic_cluster"
  providers = {
    databricks = databricks.created_workspace
  }

  enable_compliance_security_profile = var.enable_compliance_security_profile
  resource_prefix                    = var.resource_prefix
  region                             = var.region

  depends_on = [module.databricks_mws_workspace, module.user_assignment]
}

# =============================================================================
# Security Analysis Tool  - PyPI must be enabled in network policy resource to function.
# =============================================================================

module "security_analysis_tool" {
  count  = var.enable_security_analysis_tool && var.region != "us-gov-west-1" ? 1 : 0
  source = "./modules/security_analysis_tool"

  providers = {
    databricks = databricks.created_workspace
  }

  # Authentication Variables
  databricks_account_id = var.databricks_account_id
  client_id             = var.sat_client_id
  client_secret         = var.sat_client_secret
  use_sp_auth           = var.sat_use_sp_auth

  # Databricks Variables
  analysis_schema_name = replace("${var.resource_prefix}-catalog-${module.databricks_mws_workspace.workspace_id}.SAT", "-", "_")
  workspace_id         = module.databricks_mws_workspace.workspace_id

  # Configuration Variables
  proxies           = {}
  run_on_serverless = true

  depends_on = [module.unity_catalog_catalog_creation, module.user_assignment]
}

# =============================================================================
# Workspace Cluster Policy (baseline)
# =============================================================================

module "cluster_policy" {
  count  = local.effective_enable_cluster_policies ? 1 : 0
  source = "./modules/databricks_workspace/cluster_policy"
  providers = {
    databricks = databricks.created_workspace
  }

  resource_prefix = var.resource_prefix
  depends_on = [module.user_assignment]
}

# =============================================================================
# Optional Customizations (integrated via flags)
# =============================================================================

# Workspace Admin Configurations
module "admin_configuration" {
  count  = var.enable_admin_configuration ? 1 : 0
  source = "../customizations/workspace/admin_configuration"
  providers = {
    databricks = databricks.created_workspace
  }
  depends_on = [module.user_assignment]
}

# IP Access List
module "ip_access_list" {
  count  = var.enable_ip_access_list ? 1 : 0
  source = "../customizations/workspace/ip_access_list"
  providers = {
    databricks = databricks.created_workspace
  }

  ip_addresses = var.ip_access_list_addresses
  depends_on   = [module.user_assignment]
}

# System Tables Audit Log Alerting
module "system_tables_audit_log" {
  count  = var.enable_audit_log_alerting ? 1 : 0
  source = "../customizations/workspace/solution_accelerators/system_tables_audit_log"
  providers = {
    databricks = databricks.created_workspace
  }

  alert_emails = length(var.audit_log_alert_emails) > 0 ? var.audit_log_alert_emails : [var.admin_user]
  warehouse_id = var.audit_log_alert_warehouse_id

  depends_on = [module.databricks_mws_workspace, module.unity_catalog_metastore_assignment, module.user_assignment]
}

# Read-Only External Location
module "uc_external_location_read_only" {
  count  = var.enable_read_only_external_location ? 1 : 0
  source = "../customizations/workspace/uc_external_location_read_only"
  providers = {
    databricks = databricks.created_workspace
    aws        = aws
  }

  databricks_account_id             = var.databricks_account_id
  aws_account_id                    = var.aws_account_id
  resource_prefix                   = var.resource_prefix
  read_only_data_bucket             = var.read_only_data_bucket
  read_only_external_location_admin = var.read_only_external_location_admin

  depends_on = [module.databricks_mws_workspace, module.unity_catalog_metastore_assignment, module.user_assignment]
}