output "log_bucket_name" {
  description = "Audit log delivery S3 bucket name"
  value       = aws_s3_bucket.log_delivery.bucket
}

output "log_delivery_role_arn" {
  description = "IAM role used for audit log delivery"
  value       = aws_iam_role.log_delivery.arn
}

output "storage_configuration_id" {
  description = "Databricks storage configuration ID for audit logs"
  value       = databricks_mws_storage_configurations.log_bucket.storage_configuration_id
}

output "mws_log_delivery_id" {
  description = "Databricks MWS log delivery ID"
  value       = databricks_mws_log_delivery.audit_logs.id
}

