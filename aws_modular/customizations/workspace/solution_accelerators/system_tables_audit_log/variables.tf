variable "alert_emails" {
  type        = list(string)
  description = "List of emails to notify when alerts are fired"
}

variable "warehouse_id" {
  type        = string
  default     = ""
  description = "Optional Warehouse ID to run queries on. If not provided, new SQL Warehouse is created"
}

variable "quartz_cron_expression" {
  type        = string
  default     = null
  description = "Optional cron expression for job schedule. Defaults to daily at 01:01 UTC."
}