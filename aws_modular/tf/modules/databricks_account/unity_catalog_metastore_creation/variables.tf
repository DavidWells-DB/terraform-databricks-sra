variable "metastore_exists" {
  description = "If a metastore exists."
  type        = string
}

variable "region" {
  description = "AWS region code."
  type        = string
}

variable "metastore_name" {
  description = "Optional name for the Unity Catalog metastore."
  type        = string
  default     = null
}