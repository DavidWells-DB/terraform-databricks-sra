output "effective_workspace_id" {
  description = "Workspace ID."
  value       = module.databricks_mws_workspace.workspace_id
}

output "effective_workspace_url" {
  description = "Workspace URL."
  value       = module.databricks_mws_workspace.workspace_url
}

output "effective_root_bucket_name" {
  description = "Root bucket name used for the workspace."
  value       = var.use_existing_root_bucket_name != null ? var.use_existing_root_bucket_name : aws_s3_bucket.root_storage_bucket[0].bucket
}

output "effective_cross_account_role_arn" {
  description = "Cross-account role ARN used by Databricks."
  value       = var.use_existing_cross_account_role_arn != null ? var.use_existing_cross_account_role_arn : aws_iam_role.cross_account_role[0].arn
}

output "effective_ncc_id" {
  description = "Network Connectivity Configuration ID used by the workspace."
  value       = var.use_existing_network_connectivity_configuration_id != null ? var.use_existing_network_connectivity_configuration_id : module.network_connectivity_configuration[0].ncc_id
}

output "effective_network_policy_id" {
  description = "Network Policy ID used by the workspace."
  value       = var.use_existing_network_policy_id != null ? var.use_existing_network_policy_id : module.network_policy[0].network_policy_id
}

# Networking (isolated mode) - expose IDs for downstream composition
output "isolated_vpc_id" {
  description = "VPC ID when created in isolated mode. Null in custom mode."
  value       = var.network_configuration != "custom" ? module.vpc[0].vpc_id : null
}

output "isolated_private_subnets" {
  description = "Private subnets when created in isolated mode. Null in custom mode."
  value       = var.network_configuration != "custom" ? module.vpc[0].private_subnets : null
}

output "isolated_security_group_id" {
  description = "Security group ID when created in isolated mode. Null in custom mode."
  value       = var.network_configuration != "custom" ? aws_security_group.sg[0].id : null
}

output "isolated_backend_rest_vpce_id" {
  description = "Backend REST VPC endpoint ID when created in isolated mode. Null in custom mode."
  value       = var.network_configuration != "custom" ? aws_vpc_endpoint.backend_rest[0].id : null
}

output "isolated_backend_relay_vpce_id" {
  description = "Backend Relay VPC endpoint ID when created in isolated mode. Null in custom mode."
  value       = var.network_configuration != "custom" ? aws_vpc_endpoint.backend_relay[0].id : null
}

# KMS effective ARNs/Aliases for downstream use
output "effective_workspace_kms_arn" {
  description = "Effective workspace storage KMS ARN (existing or created)."
  value       = local.effective_use_existing_workspace_kms_arn != null ? local.effective_use_existing_workspace_kms_arn : (var.enable_cmk_workspace_storage ? aws_kms_key.workspace_storage[0].arn : null)
}

output "effective_workspace_kms_alias" {
  description = "Effective workspace storage KMS alias (existing or created)."
  value       = local.effective_use_existing_workspace_kms_alias != null ? local.effective_use_existing_workspace_kms_alias : (var.enable_cmk_workspace_storage ? aws_kms_alias.workspace_storage_key_alias[0].name : null)
}

output "effective_managed_services_kms_arn" {
  description = "Effective managed services KMS ARN (existing or created)."
  value       = local.effective_use_existing_managed_kms_arn != null ? local.effective_use_existing_managed_kms_arn : (var.enable_cmk_managed_services ? aws_kms_key.managed_services[0].arn : null)
}

output "effective_managed_services_kms_alias" {
  description = "Effective managed services KMS alias (existing or created)."
  value       = local.effective_use_existing_managed_kms_alias != null ? local.effective_use_existing_managed_kms_alias : (var.enable_cmk_managed_services ? aws_kms_alias.managed_services_key_alias[0].name : null)
}

# Cluster policy output
output "cluster_policy_id" {
  description = "Baseline cluster policy ID when enabled. Null if disabled."
  value       = var.enable_cluster_policies ? module.cluster_policy[0].cluster_policy_id : null
}

