variable "aws_account_id" {
  type = string
}

variable "databricks_account_id" {
  type = string
}

variable "read_only_data_bucket" {
  type = string
}

variable "read_only_external_location_admin" {
  type = string
}

variable "resource_prefix" {
  type = string
}

variable "external_location_name" {
  type        = string
  description = "Name for the external location"
  default     = "external-location"
}

variable "storage_credential_name" {
  type        = string
  description = "Name for the storage credential"
  default     = null
}