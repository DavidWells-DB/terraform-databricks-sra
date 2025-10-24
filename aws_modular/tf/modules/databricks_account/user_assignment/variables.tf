variable "workspace_id" {
  description = "workspace ID of deployed workspace."
  type        = string
}

variable "workspace_access" {
  type        = string
  description = "data source for the workspace access."
}

variable "sp_client_id" {
  type        = string
  description = "Optional service principal client ID to be granted ADMIN temporarily."
  default     = null
}

variable "grant_sp_admin" {
  type        = bool
  description = "Whether to grant the provided service principal ADMIN on the workspace."
  default     = false
}

variable "executor_user_email" {
  type        = string
  description = "Optional user email to be granted ADMIN temporarily when executor is a user."
  default     = null
}

variable "admin_sp_client_id" {
  type        = string
  description = "Optional service principal client ID to be granted long-term ADMIN alongside admin_user."
  default     = null
}
