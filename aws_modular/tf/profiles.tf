locals {
  profile_defaults = {
    isolated = {
      enable_cluster_policies       = true
      enable_vpc_flow_logs          = true
      enable_kms_rotation           = true
      enable_s3_ownership_controls  = true
      enable_s3_ephemeral_lifecycle = false
    }
    byo-min = {
      enable_cluster_policies       = true
      enable_vpc_flow_logs          = false
      enable_kms_rotation           = true
      enable_s3_ownership_controls  = true
      enable_s3_ephemeral_lifecycle = false
    }
    byo-full = {
      enable_cluster_policies       = true
      enable_vpc_flow_logs          = false
      enable_kms_rotation           = true
      enable_s3_ownership_controls  = true
      enable_s3_ephemeral_lifecycle = false
    }
  }

  use_profile = var.features_profile != null

  effective_enable_cluster_policies       = local.use_profile ? local.profile_defaults[var.features_profile].enable_cluster_policies : var.enable_cluster_policies
  effective_enable_vpc_flow_logs          = local.use_profile ? local.profile_defaults[var.features_profile].enable_vpc_flow_logs : var.enable_vpc_flow_logs
  effective_enable_kms_rotation           = local.use_profile ? local.profile_defaults[var.features_profile].enable_kms_rotation : var.enable_kms_rotation
  effective_enable_s3_ownership_controls  = local.use_profile ? local.profile_defaults[var.features_profile].enable_s3_ownership_controls : var.enable_s3_ownership_controls
  effective_enable_s3_ephemeral_lifecycle = local.use_profile ? local.profile_defaults[var.features_profile].enable_s3_ephemeral_lifecycle : var.enable_s3_ephemeral_lifecycle

  # Effective BYO values from grouped or scalar inputs
  effective_custom_vpc_id             = var.network != null && try(var.network.vpc_id, null) != null ? var.network.vpc_id : var.custom_vpc_id
  effective_custom_private_subnet_ids = var.network != null && try(var.network.private_subnet_ids, null) != null ? var.network.private_subnet_ids : var.custom_private_subnet_ids
  effective_custom_sg_id              = var.network != null && try(var.network.sg_id, null) != null ? var.network.sg_id : var.custom_sg_id
  effective_custom_workspace_vpce_id  = var.network != null && try(var.network.workspace_vpce_id, null) != null ? var.network.workspace_vpce_id : var.custom_workspace_vpce_id
  effective_custom_relay_vpce_id      = var.network != null && try(var.network.relay_vpce_id, null) != null ? var.network.relay_vpce_id : var.custom_relay_vpce_id

  effective_use_existing_root_bucket_name = var.existing != null && try(var.existing.root_bucket_name, null) != null ? var.existing.root_bucket_name : var.use_existing_root_bucket_name
  effective_use_existing_ncc_id           = var.existing != null && try(var.existing.ncc_id, null) != null ? var.existing.ncc_id : var.use_existing_network_connectivity_configuration_id
  effective_use_existing_network_policy_id = var.existing != null && try(var.existing.network_policy_id, null) != null ? var.existing.network_policy_id : var.use_existing_network_policy_id
  effective_use_existing_cross_account_role_arn = var.existing != null && try(var.existing.cross_account_role_arn, null) != null ? var.existing.cross_account_role_arn : var.use_existing_cross_account_role_arn

  effective_use_existing_workspace_kms_arn   = var.kms != null && try(var.kms.workspace_key_arn, null) != null ? var.kms.workspace_key_arn : var.use_existing_workspace_storage_kms_key_arn
  effective_use_existing_workspace_kms_alias = var.kms != null && try(var.kms.workspace_key_alias, null) != null ? var.kms.workspace_key_alias : var.use_existing_workspace_storage_kms_key_alias
  effective_use_existing_managed_kms_arn     = var.kms != null && try(var.kms.managed_services_key_arn, null) != null ? var.kms.managed_services_key_arn : var.use_existing_managed_services_kms_key_arn
  effective_use_existing_managed_kms_alias   = var.kms != null && try(var.kms.managed_services_key_alias, null) != null ? var.kms.managed_services_key_alias : var.use_existing_managed_services_kms_key_alias
}

