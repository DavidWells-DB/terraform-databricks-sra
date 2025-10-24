output "cluster_policy_id" {
  description = "ID of the baseline cluster policy"
  value       = databricks_cluster_policy.baseline.id
}

output "cluster_policy_name" {
  description = "Name of the baseline cluster policy"
  value       = databricks_cluster_policy.baseline.name
}


