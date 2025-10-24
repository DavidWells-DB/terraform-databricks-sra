output "cluster_id" {
  description = "ID of the created classic cluster"
  value       = databricks_cluster.example.id
}

output "cluster_name" {
  description = "Name of the created classic cluster"
  value       = databricks_cluster.example.cluster_name
}

