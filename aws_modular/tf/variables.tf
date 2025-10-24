variable "admin_user" {
  description = "Email of the admin user for the workspace and workspace catalog."
  type        = string
}

variable "admin_sp_client_id" {
  description = "Optional: Application (client) ID of a service principal to be granted long-term workspace ADMIN alongside admin_user (if your org uses an SP as the admin principal)."
  type        = string
  default     = null
}

# Terraform Service Principal (used to run this deployment)
variable "terraform_sp_client_id" {
  description = "Application (client) ID of the service principal executing Terraform (executor). Used to grant temporary workspace ADMIN for initial configuration when enabled."
  type        = string
  default     = null
}

variable "grant_terraform_sp_workspace_admin" {
  description = "If true, grant the executor (user or SP) temporary ADMIN on the workspace so workspace-scoped modules can run. Disable after initial apply to remove admin."
  type        = bool
  default     = true
}

variable "executor_user_email" {
  description = "Optional: Email of the user executing Terraform (executor). When grant_terraform_sp_workspace_admin=true and this is set (and terraform_sp_client_id is null), the user is granted temporary workspace ADMIN."
  type        = string
  default     = null
}

variable "executor_identity_check" {
  description = "Optional executor identity assertion: none | must_match_admin_user | must_differ_from_admin_user | must_match_admin_or_executor"
  type        = string
  default     = "none"

  validation {
    condition     = contains(["none", "must_match_admin_user", "must_differ_from_admin_user", "must_match_admin_or_executor"], var.executor_identity_check)
    error_message = "executor_identity_check must be one of: none, must_match_admin_user, must_differ_from_admin_user, must_match_admin_or_executor."
  }
}

variable "artifact_storage_bucket" {
  description = "Artifact storage bucket for VPC endpoint policy."
  type        = map(list(string))
  default = {
    "ap-northeast-1" = ["databricks-prod-artifacts-ap-northeast-1"]
    "ap-northeast-2" = ["databricks-prod-artifacts-ap-northeast-2"]
    "ap-south-1"     = ["databricks-prod-artifacts-ap-south-1"]
    "ap-southeast-1" = ["databricks-prod-artifacts-ap-southeast-1"]
    "ap-southeast-2" = ["databricks-prod-artifacts-ap-southeast-2"]
    "ap-southeast-3" = ["databricks-prod-artifacts-ap-southeast-3"]
    "ca-central-1"   = ["databricks-prod-artifacts-ca-central-1"]
    "eu-central-1"   = ["databricks-prod-artifacts-eu-central-1"]
    "eu-west-1"      = ["databricks-prod-artifacts-eu-west-1"]
    "eu-west-2"      = ["databricks-prod-artifacts-eu-west-2"]
    "eu-west-3"      = ["databricks-prod-artifacts-eu-west-3"]
    "sa-east-1"      = ["databricks-prod-artifacts-sa-east-1"]
    "us-east-1"      = ["databricks-prod-artifacts-us-east-1"]
    "us-east-2"      = ["databricks-prod-artifacts-us-east-2"]
    "us-west-1"      = ["databricks-prod-artifacts-us-west-2"]
    "us-west-2"      = ["databricks-prod-artifacts-us-west-2", "databricks-update-oregon"]
    "us-gov-west-1"  = ["databricks-prod-artifacts-us-gov-west-1"]
  }
}

variable "audit_log_delivery_exists" {
  description = "If audit log delivery is already configured"
  type        = bool
  default     = false
}

variable "aws_account_id" {
  description = "ID of the AWS account."
  type        = string
  sensitive   = true
}

variable "aws_partition" {
  description = "AWS partition to use for ARNs and policies"
  type        = string
  default     = null # Will be computed based on region

  validation {
    condition     = var.aws_partition == null || can(contains(["aws", "aws-us-gov"], var.aws_partition))
    error_message = "Invalid AWS partition. Allowed values are: aws, aws-us-gov."
  }
}

variable "cmk_admin_arn" {
  description = "Amazon Resource Name (ARN) of the CMK admin."
  type        = string
  default     = null
}

variable "compliance_standards" {
  description = "List of compliance standards."
  type        = list(string)
  nullable    = true
}

variable "custom_private_subnet_ids" {
  description = "List of custom private subnet IDs"
  type        = list(string)
  default     = null
}

variable "custom_relay_vpce_id" {
  description = "Custom Relay VPC Endpoint ID"
  type        = string
  default     = null
}

variable "custom_sg_id" {
  description = "Custom security group ID"
  type        = string
  default     = null
}

variable "custom_vpc_id" {
  description = "Custom VPC ID"
  type        = string
  default     = null
}

variable "custom_workspace_vpce_id" {
  description = "Custom Workspace VPC Endpoint ID"
  type        = string
  default     = null
}

# Grouped object inputs (optional). Scalar inputs remain for back-compat.
variable "network" {
  description = "Grouped network inputs for BYO networking"
  type = object({
    vpc_id             = optional(string)
    private_subnet_ids = optional(list(string))
    sg_id              = optional(string)
    workspace_vpce_id  = optional(string)
    relay_vpce_id      = optional(string)
  })
  default = null
}

variable "kms" {
  description = "Grouped KMS inputs for BYO keys"
  type = object({
    workspace_key_arn          = optional(string)
    workspace_key_alias        = optional(string)
    managed_services_key_arn   = optional(string)
    managed_services_key_alias = optional(string)
  })
  default = null
}

variable "existing" {
  description = "Grouped existing resource IDs"
  type = object({
    root_bucket_name = optional(string)
    ncc_id           = optional(string)
    network_policy_id = optional(string)
    cross_account_role_arn = optional(string)
  })
  default = null
}

# Allow supplying an existing cross-account role ARN instead of creating it
variable "use_existing_cross_account_role_arn" {
  description = "Existing cross-account role ARN for Databricks to assume. If provided, the module will not create the role/policy."
  type        = string
  default     = null
}

variable "databricks_account_id" {
  description = "ID of the Databricks account."
  type        = string
  sensitive   = true
}

variable "databricks_gov_shard" {
  description = "Databricks GovCloud shard type (civilian or dod). Only applicable for us-gov-west-1 region."
  type        = string
  default     = null

  validation {
    condition     = var.databricks_gov_shard == null || can(contains(["civilian", "dod"], var.databricks_gov_shard))
    error_message = "Invalid databricks_gov_shard. Allowed values are: null, civilian, dod."
  }
}

variable "databricks_provider_host" {
  description = "Databricks provider host URL"
  type        = string
  default     = null # Will be computed based on databricks_gov_shard

  validation {
    condition     = var.databricks_provider_host == null || can(regex("^https://(accounts|accounts-dod)\\.cloud\\.databricks\\.(com|us|mil)$", var.databricks_provider_host))
    error_message = "Invalid databricks_provider_host. Must be a valid Databricks accounts URL."
  }
}

variable "deployment_name" {
  description = "Deployment name for the workspace. Must first be enabled by a Databricks representative."
  default     = null
  type        = string
  nullable    = true
}

variable "enable_compliance_security_profile" {
  description = "Flag to enable the compliance security profile."
  type        = bool
  sensitive   = true
  default     = false
}

variable "enable_security_analysis_tool" {
  description = "Flag to enable the security analysis tool."
  type        = bool
  sensitive   = true
  default     = false
}

# SAT authentication (optional)
variable "sat_use_sp_auth" {
  description = "Authenticate SAT with Service Principal OAuth tokens instead of username/password"
  type        = bool
  default     = true
}

variable "sat_client_id" {
  description = "Service Principal Application (client) ID for SAT when sat_use_sp_auth is true"
  type        = string
  default     = null
}

variable "sat_client_secret" {
  description = "Service Principal secret for SAT when sat_use_sp_auth is true"
  type        = string
  default     = null
}

# Optional feature/module toggles
variable "enable_uc_catalog_creation" {
  description = "Enable workspace-isolated Unity Catalog catalog creation."
  type        = bool
  default     = true
}

variable "enable_system_tables" {
  description = "Enable System Tables in the workspace (not supported in us-gov-west-1)."
  type        = bool
  default     = true
}

variable "enable_restrictive_root_bucket_policy" {
  description = "Create restrictive policy on the workspace root bucket."
  type        = bool
  default     = true
}

variable "disable_legacy_access_and_dbfs" {
  description = "Disable legacy workspace access mode and legacy DBFS (including DBFS mounts)."
  type        = bool
  default     = true
}

variable "enable_classic_cluster" {
  description = "Create a small classic compute cluster."
  type        = bool
  default     = true
}

variable "enable_user_workspace_assignment" {
  description = "Grant ADMIN on the workspace to the provided admin_user."
  type        = bool
  default     = true
}

# Feature profile (future use): can preset defaults for toggles
variable "features_profile" {
  description = "Optional feature profile to preset defaults (e.g., isolated, byo-min, byo-full)."
  type        = string
  default     = null
  validation {
    condition     = var.features_profile == null || can(contains(["isolated", "byo-min", "byo-full"], var.features_profile))
    error_message = "features_profile must be one of: isolated, byo-min, byo-full."
  }
}

# Hardening toggles
variable "enable_kms_rotation" {
  description = "Enable rotation on created CMKs."
  type        = bool
  default     = true
}

variable "enable_s3_ownership_controls" {
  description = "Enable S3 BucketOwnerEnforced ownership controls on the root bucket."
  type        = bool
  default     = true
}

variable "enable_s3_ephemeral_lifecycle" {
  description = "Enable lifecycle rules to expire ephemeral prefixes in the root bucket."
  type        = bool
  default     = false
}

variable "enable_vpc_flow_logs" {
  description = "Enable VPC Flow Logs for created VPC (ignored in custom networking)."
  type        = bool
  default     = false
}

# Endpoint policy hardening (optional)
variable "enable_endpoint_policy_hardening" {
  description = "Add optional defense-in-depth conditions to VPC endpoint policies (advanced)."
  type        = bool
  default     = false
}

variable "allowed_source_vpce_ids" {
  description = "List of allowed Source VPC endpoint IDs for endpoint policy hardening."
  type        = list(string)
  default     = []
}

variable "allowed_serverless_org_paths" {
  description = "List of allowed Databricks Serverless aws:VpceOrgPaths (advanced)."
  type        = list(string)
  default     = []
}

variable "enable_cluster_policies" {
  description = "Create a baseline Databricks cluster policy."
  type        = bool
  default     = true
}

# CMK toggles (optional): allow disabling use/creation of CMKs
variable "enable_cmk_workspace_storage" {
  description = "Enable CMK for workspace storage (DBFS/root bucket). If false, use SSE-S3 (AES256)."
  type        = bool
  default     = true
}

variable "enable_cmk_managed_services" {
  description = "Enable CMK for managed services in the control plane."
  type        = bool
  default     = true
}

# Optional customizations integration
variable "enable_admin_configuration" {
  description = "Enable workspace admin configuration customization."
  type        = bool
  default     = false
}

variable "enable_ip_access_list" {
  description = "Enable IP access list customization."
  type        = bool
  default     = false
}

variable "ip_access_list_addresses" {
  description = "List of IP addresses for the IP access list customization."
  type        = list(string)
  default     = []
}

variable "enable_audit_log_alerting" {
  description = "Enable System Tables Audit Log Alerting customization."
  type        = bool
  default     = false
}

variable "audit_log_alert_emails" {
  description = "Emails to notify for audit log alerts. Defaults to [admin_user] when empty."
  type        = list(string)
  default     = []
}

variable "audit_log_alert_warehouse_id" {
  description = "Optional SQL warehouse ID to run alerts on. If empty, customization creates one."
  type        = string
  default     = ""
}

variable "enable_read_only_external_location" {
  description = "Enable read-only UC external location customization."
  type        = bool
  default     = false
}

variable "read_only_data_bucket" {
  description = "Bucket name to expose via a read-only UC external location."
  type        = string
  default     = ""
}

variable "read_only_external_location_admin" {
  description = "Principal (email) to grant ALL_PRIVILEGES on the read-only external location."
  type        = string
  default     = ""
}

variable "metastore_exists" {
  description = "If a metastore exists"
  type        = bool
}

variable "metastore_name" {
  description = "Optional name for the Unity Catalog metastore (used when creating a new one)."
  type        = string
  default     = null
}

variable "network_configuration" {
  description = "The type of network set-up for the workspace network configuration."
  type        = string
  nullable    = false

  validation {
    condition     = contains(["custom", "isolated"], var.network_configuration)
    error_message = "Invalid network configuration. Allowed values are: custom, isolated."
  }
}

# Allow supplying existing NCC and Network Policy instead of creating new ones
variable "use_existing_network_connectivity_configuration_id" {
  description = "Existing Network Connectivity Configuration ID to bind to the workspace. If provided, NCC resource creation is skipped."
  type        = string
  default     = null
}

variable "use_existing_network_policy_id" {
  description = "Existing Network Policy ID to attach to the workspace. If provided, network policy creation is skipped."
  type        = string
  default     = null
}

variable "private_subnets_cidr" {
  description = "CIDR blocks for private subnets."
  type        = list(string)
  nullable    = true
}

variable "privatelink_subnets_cidr" {
  description = "CIDR blocks for private link subnets."
  type        = list(string)
  nullable    = true
}

variable "region" {
  description = "AWS region code. (e.g. us-east-1)"
  type        = string
  validation {
    condition     = contains(["ap-northeast-1", "ap-northeast-2", "ap-south-1", "ap-southeast-1", "ap-southeast-2", "ap-southeast-3", "ca-central-1", "eu-central-1", "eu-west-1", "eu-west-2", "eu-west-3", "sa-east-1", "us-east-1", "us-east-2", "us-west-1", "us-west-2", "us-gov-west-1"], var.region)
    error_message = "Valid values for var: region are (ap-northeast-1, ap-northeast-2, ap-south-1, ap-southeast-1, ap-southeast-2, ap-southeast-3, ca-central-1, eu-central-1, eu-west-1, eu-west-2, eu-west-3, sa-east-1, us-east-1, us-east-2, us-west-1, us-west-2, us-gov-west-1)."
  }
}

# Region name configuration
# This variable allows mapping regions to multiple name properties:
# - primary_name: The main region name (required)
# - secondary_name: An optional secondary region name (e.g., for DoD)
# - region_type: Optional region type (defaults to "commercial", can be "govcloud")
#
# Example usage:
# var.region_name_config["us-gov-west-1"].primary_name   # Get primary name (civilian)
# var.region_name_config["us-gov-west-1"].secondary_name # Get secondary name (DoD)
# var.region_name_config["us-gov-west-1"].region_type    # Get region type
variable "region_name_config" {
  description = "Region name configuration with multiple properties per region"
  type = map(object({
    primary_name   = string
    secondary_name = optional(string)
    region_type    = optional(string, "commercial")
  }))
  default = {
    "ap-northeast-1" = {
      primary_name = "tokyo"
    }
    "ap-northeast-2" = {
      primary_name = "seoul"
    }
    "ap-south-1" = {
      primary_name = "mumbai"
    }
    "ap-southeast-1" = {
      primary_name = "singapore"
    }
    "ap-southeast-2" = {
      primary_name = "sydney"
    }
    "ap-southeast-3" = {
      primary_name = "jakarta"
    }
    "ca-central-1" = {
      primary_name = "canada"
    }
    "eu-central-1" = {
      primary_name = "frankfurt"
    }
    "eu-west-1" = {
      primary_name = "ireland"
    }
    "eu-west-2" = {
      primary_name = "london"
    }
    "eu-west-3" = {
      primary_name = "paris"
    }
    "sa-east-1" = {
      primary_name = "saopaulo"
    }
    "us-east-1" = {
      primary_name = "nvirginia"
    }
    "us-east-2" = {
      primary_name = "ohio"
    }
    "us-west-2" = {
      primary_name = "oregon"
    }
    "us-west-1" = {
      primary_name = "oregon"
    }
    "us-gov-west-1" = {
      primary_name   = "pendleton"
      secondary_name = "pendleton-dod"
      region_type    = "govcloud"
    }
  }
}

variable "resource_prefix" {
  description = "Prefix for the resource names."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-.]{1,26}$", var.resource_prefix))
    error_message = "Invalid resource prefix. Allowed 26 characters containing only a-z, 0-9, -, ."
  }
}

# Secure Cluster Connectivity Relay configuration
# This variable allows mapping regions to multiple endpoint properties:
# - primary_endpoint: The main endpoint service name (required)
# - secondary_endpoint: An optional secondary endpoint service name
# - region_type: Optional region type (defaults to "commercial", can be "govcloud")
#
# Example usage:
# var.scc_relay_config["us-gov-west-1"].primary_endpoint   # Get primary endpoint
# var.scc_relay_config["us-gov-west-1"].secondary_endpoint # Get secondary endpoint (if exists)
# var.scc_relay_config["us-gov-west-1"].region_type        # Get region type
variable "scc_relay_config" {
  description = "Secure Cluster Connectivity Relay configuration with multiple properties per region"
  type = map(object({
    primary_endpoint   = string
    secondary_endpoint = optional(string)
    region_type        = optional(string, "commercial")
  }))
  default = {
    "ap-northeast-1" = {
      primary_endpoint = "com.amazonaws.vpce.ap-northeast-1.vpce-svc-02aa633bda3edbec0"
    }
    "ap-northeast-2" = {
      primary_endpoint = "com.amazonaws.vpce.ap-northeast-2.vpce-svc-0dc0e98a5800db5c4"
    }
    "ap-south-1" = {
      primary_endpoint = "com.amazonaws.vpce.ap-south-1.vpce-svc-03fd4d9b61414f3de"
    }
    "ap-southeast-1" = {
      primary_endpoint = "com.amazonaws.vpce.ap-southeast-1.vpce-svc-0557367c6fc1a0c5c"
    }
    "ap-southeast-2" = {
      primary_endpoint = "com.amazonaws.vpce.ap-southeast-2.vpce-svc-0b4a72e8f825495f6"
    }
    "ap-southeast-3" = {
      primary_endpoint = "com.amazonaws.vpce.ap-southeast-3.vpce-svc-025ca447c232c6a1b"
    }
    "ca-central-1" = {
      primary_endpoint = "com.amazonaws.vpce.ca-central-1.vpce-svc-0c4e25bdbcbfbb684"
    }
    "eu-central-1" = {
      primary_endpoint = "com.amazonaws.vpce.eu-central-1.vpce-svc-08e5dfca9572c85c4"
    }
    "eu-west-1" = {
      primary_endpoint = "com.amazonaws.vpce.eu-west-1.vpce-svc-09b4eb2bc775f4e8c"
    }
    "eu-west-2" = {
      primary_endpoint = "com.amazonaws.vpce.eu-west-2.vpce-svc-05279412bf5353a45"
    }
    "eu-west-3" = {
      primary_endpoint = "com.amazonaws.vpce.eu-west-3.vpce-svc-005b039dd0b5f857d"
    }
    "sa-east-1" = {
      primary_endpoint = "com.amazonaws.vpce.sa-east-1.vpce-svc-0e61564963be1b43f"
    }
    "us-east-1" = {
      primary_endpoint = "com.amazonaws.vpce.us-east-1.vpce-svc-00018a8c3ff62ffdf"
    }
    "us-east-2" = {
      primary_endpoint = "com.amazonaws.vpce.us-east-2.vpce-svc-090a8fab0d73e39a6"
    }
    "us-west-2" = {
      primary_endpoint = "com.amazonaws.vpce.us-west-2.vpce-svc-0158114c0c730c3bb"
    }
    "us-west-1" = {
      primary_endpoint = "com.amazonaws.vpce.us-west-1.vpce-svc-04cb91f9372b792fe"
    }
    "us-gov-west-1" = {
      primary_endpoint   = "com.amazonaws.vpce.us-gov-west-1.vpce-svc-05f27abef1a1a3faa"
      secondary_endpoint = "com.amazonaws.vpce.us-gov-west-1.vpce-svc-05c210a2feea23ad7"
      region_type        = "govcloud"
    }
  }
}

variable "sg_egress_ports" {
  description = "List of egress ports for security groups."
  type        = list(string)
}

# Optional Internet egress (isolated mode only)
variable "enable_controlled_egress" {
  description = "Enable controlled internet egress for isolated mode (creates IGW and NAT)."
  type        = bool
  default     = false
}

# Deprecated: prefer enable_controlled_egress
variable "enable_internet_gateway" {
  description = "[Deprecated] Use enable_controlled_egress instead."
  type        = bool
  default     = false
}

variable "enable_nat_gateway" {
  description = "[Deprecated] Use enable_controlled_egress instead."
  type        = bool
  default     = false
}

variable "single_nat_gateway" {
  description = "Use a single NAT gateway (true) or one per AZ (false) when enable_nat_gateway = true."
  type        = bool
  default     = true
}

variable "public_subnets_cidr" {
  description = "CIDR blocks for public subnets (required when controlled egress is enabled)."
  type        = list(string)
  default     = []
}

variable "allowed_outbound_cidrs" {
  description = "Allowed destination CIDRs for internet egress SG rules (applies when controlled egress is enabled)."
  type        = list(string)
  default     = []
}

variable "allowed_outbound_tcp_ports" {
  description = "Allowed TCP destination ports for internet egress SG rules (applies when controlled egress is enabled)."
  type        = list(number)
  default     = []
}

variable "allowed_outbound_udp_ports" {
  description = "Allowed UDP destination ports for internet egress SG rules (applies when controlled egress is enabled)."
  type        = list(number)
  default     = []
}

variable "shared_datasets_bucket" {
  description = "Shared datasets bucket for VPC endpoint policy."
  type        = map(string)
  default = {
    "ap-northeast-1" = "databricks-datasets-tokyo"
    "ap-northeast-2" = "databricks-datasets-seoul"
    "ap-south-1"     = "databricks-datasets-mumbai"
    "ap-southeast-1" = "databricks-datasets-singapore"
    "ap-southeast-2" = "databricks-datasets-sydney"
    "ap-southeast-3" = "databricks-datasets-oregon"
    "ca-central-1"   = "databricks-datasets-montreal"
    "eu-central-1"   = "databricks-datasets-frankfurt"
    "eu-west-1"      = "databricks-datasets-ireland"
    "eu-west-2"      = "databricks-datasets-london"
    "eu-west-3"      = "databricks-datasets-paris"
    "sa-east-1"      = "databricks-datasets-saopaulo"
    "us-east-1"      = "databricks-datasets-virginia"
    "us-east-2"      = "databricks-datasets-ohio"
    "us-west-1"      = "databricks-datasets-oregon"
    "us-west-2"      = "databricks-datasets-oregon"
    "us-gov-west-1"  = "databricks-datasets-pendleton"
  }
}

# System table bucket configuration
# This variable allows mapping regions to multiple bucket properties:
# - primary_bucket: The main bucket name (required)
# - secondary_bucket: An optional secondary bucket name (e.g., for DoD)
# - region_type: Optional region type (defaults to "commercial", can be "govcloud")
#
# Example usage:
# var.system_table_bucket_config["us-gov-west-1"].primary_bucket   # Get primary bucket (civilian)
# var.system_table_bucket_config["us-gov-west-1"].secondary_bucket # Get secondary bucket (DoD)
# var.system_table_bucket_config["us-gov-west-1"].region_type      # Get region type
variable "system_table_bucket_config" {
  description = "System table bucket configuration with multiple properties per region"
  type = map(object({
    primary_bucket   = string
    secondary_bucket = optional(string)
    region_type      = optional(string, "commercial")
  }))
  default = {
    "ap-northeast-1" = {
      primary_bucket = "system-tables-prod-ap-northeast-1-uc-metastore-bucket"
    }
    "ap-northeast-2" = {
      primary_bucket = "system-tables-prod-ap-northeast-2-uc-metastore-bucket"
    }
    "ap-south-1" = {
      primary_bucket = "system-tables-prod-ap-south-1-uc-metastore-bucket"
    }
    "ap-southeast-1" = {
      primary_bucket = "system-tables-prod-ap-southeast-1-uc-metastore-bucket"
    }
    "ap-southeast-2" = {
      primary_bucket = "system-tables-prod-ap-southeast-2-uc-metastore-bucket"
    }
    "ap-southeast-3" = {
      primary_bucket = "system-tables-prod-ap-southeast-3-uc-metastore-bucket"
    }
    "ca-central-1" = {
      primary_bucket = "system-tables-prod-ca-central-1-uc-metastore-bucket"
    }
    "eu-central-1" = {
      primary_bucket = "system-tables-prod-eu-central-1-uc-metastore-bucket"
    }
    "eu-west-1" = {
      primary_bucket = "system-tables-prod-eu-west-1-uc-metastore-bucket"
    }
    "eu-west-2" = {
      primary_bucket = "system-tables-prod-eu-west-2-uc-metastore-bucket"
    }
    "eu-west-3" = {
      primary_bucket = "system-tables-prod-eu-west-3-uc-metastore-bucket"
    }
    "sa-east-1" = {
      primary_bucket = "system-tables-prod-sa-east-1-uc-metastore-bucket"
    }
    "us-east-1" = {
      primary_bucket = "system-tables-prod-us-east-1-uc-metastore-bucket"
    }
    "us-east-2" = {
      primary_bucket = "system-tables-prod-us-east-2-uc-metastore-bucket"
    }
    "us-west-1" = {
      primary_bucket = "system-tables-prod-us-west-1-uc-metastore-bucket"
    }
    "us-west-2" = {
      primary_bucket = "system-tables-prod-us-west-2-uc-metastore-bucket"
    }
    "us-gov-west-1" = {
      primary_bucket   = "system-tables-prod-us-gov-west-1-gov-uc-metastore-bucket"
      secondary_bucket = "system-tables-prod-us-dod-west-1-gov-uc-metastore-bucket"
      region_type      = "govcloud"
    }
  }
}

# Log storage bucket configuration
# This variable allows mapping regions to multiple bucket properties:
# - primary_bucket: The main bucket name (required)
# - secondary_bucket: An optional secondary bucket name (e.g., for DoD)
# - region_type: Optional region type (defaults to "commercial", can be "govcloud")
#
# Example usage:
# var.log_storage_bucket_config["us-gov-west-1"].primary_bucket   # Get primary bucket (civilian)
# var.log_storage_bucket_config["us-gov-west-1"].secondary_bucket # Get secondary bucket (DoD)
# var.log_storage_bucket_config["us-gov-west-1"].region_type      # Get region type
variable "log_storage_bucket_config" {
  description = "Log storage bucket configuration with multiple properties per region"
  type = map(object({
    primary_bucket   = string
    secondary_bucket = optional(string)
    region_type      = optional(string, "commercial")
  }))
  default = {
    "ap-northeast-1" = {
      primary_bucket = "databricks-prod-storage-tokyo"
    }
    "ap-northeast-2" = {
      primary_bucket = "databricks-prod-storage-seoul"
    }
    "ap-south-1" = {
      primary_bucket = "databricks-prod-storage-mumbai"
    }
    "ap-southeast-1" = {
      primary_bucket = "databricks-prod-storage-singapore"
    }
    "ap-southeast-2" = {
      primary_bucket = "databricks-prod-storage-sydney"
    }
    "ap-southeast-3" = {
      primary_bucket = "databricks-prod-storage-jakarta"
    }
    "ca-central-1" = {
      primary_bucket = "databricks-prod-storage-montreal"
    }
    "eu-central-1" = {
      primary_bucket = "databricks-prod-storage-frankfurt"
    }
    "eu-west-1" = {
      primary_bucket = "databricks-prod-storage-ireland"
    }
    "eu-west-2" = {
      primary_bucket = "databricks-prod-storage-london"
    }
    "eu-west-3" = {
      primary_bucket = "databricks-prod-storage-paris"
    }
    "sa-east-1" = {
      primary_bucket = "databricks-prod-storage-saopaulo"
    }
    "us-east-1" = {
      primary_bucket = "databricks-prod-storage-virginia"
    }
    "us-east-2" = {
      primary_bucket = "databricks-prod-storage-ohio"
    }
    "us-west-1" = {
      primary_bucket = "databricks-prod-storage-oregon"
    }
    "us-west-2" = {
      primary_bucket = "databricks-prod-storage-oregon"
    }
    "us-gov-west-1" = {
      primary_bucket   = "databricks-prod-storage-pendleton"
      secondary_bucket = "databricks-prod-storage-pendleton-dod"
      region_type      = "govcloud"
    }
  }
}

variable "vpc_cidr_range" {
  description = "CIDR range for the VPC."
  type        = string
}

# Root bucket customization
variable "use_existing_root_bucket_name" {
  description = "Existing S3 bucket name to use as the workspace root bucket. If provided, bucket creation is skipped."
  type        = string
  default     = null
}

variable "create_root_bucket_policy" {
  description = "Whether to create/attach the Databricks bucket policy to the root bucket (applies for both created and existing bucket)."
  type        = bool
  default     = true
}

# KMS customization for workspace storage and managed services
variable "use_existing_workspace_storage_kms_key_arn" {
  description = "Existing KMS key ARN to use for workspace storage encryption. If provided, KMS key creation is skipped."
  type        = string
  default     = null
}

variable "use_existing_managed_services_kms_key_arn" {
  description = "Existing KMS key ARN to use for managed services encryption. If provided, KMS key creation is skipped."
  type        = string
  default     = null
}

variable "use_existing_workspace_storage_kms_key_alias" {
  description = "Existing KMS key alias ARN or name for the workspace storage key (required if supplying an existing key)."
  type        = string
  default     = null
}

variable "use_existing_managed_services_kms_key_alias" {
  description = "Existing KMS key alias ARN or name for the managed services key (required if supplying an existing key)."
  type        = string
  default     = null
}

# Workspace API PrivateLink Endpoint configuration
# This variable allows mapping regions to multiple endpoint properties:
# - primary_endpoint: The main endpoint service name (required)
# - secondary_endpoint: An optional secondary endpoint service name
# - region_type: Optional region type (defaults to "commercial", can be "govcloud")
#
# Example usage:
# var.workspace_config["us-gov-west-1"].primary_endpoint   # Get primary endpoint
# var.workspace_config["us-gov-west-1"].secondary_endpoint # Get secondary endpoint (if exists)
# var.workspace_config["us-gov-west-1"].region_type        # Get region type
variable "workspace_config" {
  description = "Workspace API PrivateLink Endpoint configuration with multiple properties per region"
  type = map(object({
    primary_endpoint   = string
    secondary_endpoint = optional(string)
    region_type        = optional(string, "commercial")
  }))
  default = {
    "ap-northeast-1" = {
      primary_endpoint = "com.amazonaws.vpce.ap-northeast-1.vpce-svc-02691fd610d24fd64"
    }
    "ap-northeast-2" = {
      primary_endpoint = "com.amazonaws.vpce.ap-northeast-2.vpce-svc-0babb9bde64f34d7e"
    }
    "ap-south-1" = {
      primary_endpoint = "com.amazonaws.vpce.ap-south-1.vpce-svc-0dbfe5d9ee18d6411"
    }
    "ap-southeast-1" = {
      primary_endpoint = "com.amazonaws.vpce.ap-southeast-1.vpce-svc-02535b257fc253ff4"
    }
    "ap-southeast-2" = {
      primary_endpoint = "com.amazonaws.vpce.ap-southeast-2.vpce-svc-0b87155ddd6954974"
    }
    "ap-southeast-3" = {
      primary_endpoint = "com.amazonaws.vpce.ap-southeast-3.vpce-svc-07a698e7e9ccfd04a"
    }
    "ca-central-1" = {
      primary_endpoint = "com.amazonaws.vpce.ca-central-1.vpce-svc-0205f197ec0e28d65"
    }
    "eu-central-1" = {
      primary_endpoint = "com.amazonaws.vpce.eu-central-1.vpce-svc-081f78503812597f7"
    }
    "eu-west-1" = {
      primary_endpoint = "com.amazonaws.vpce.eu-west-1.vpce-svc-0da6ebf1461278016"
    }
    "eu-west-2" = {
      primary_endpoint = "com.amazonaws.vpce.eu-west-2.vpce-svc-01148c7cdc1d1326c"
    }
    "eu-west-3" = {
      primary_endpoint = "com.amazonaws.vpce.eu-west-3.vpce-svc-008b9368d1d011f37"
    }
    "sa-east-1" = {
      primary_endpoint = "com.amazonaws.vpce.sa-east-1.vpce-svc-0bafcea8cdfe11b66"
    }
    "us-east-1" = {
      primary_endpoint = "com.amazonaws.vpce.us-east-1.vpce-svc-09143d1e626de2f04"
    }
    "us-east-2" = {
      primary_endpoint = "com.amazonaws.vpce.us-east-2.vpce-svc-041dc2b4d7796b8d3"
    }
    "us-west-2" = {
      primary_endpoint = "com.amazonaws.vpce.us-west-2.vpce-svc-0129f463fcfbc46c5"
    }
    "us-west-1" = {
      primary_endpoint = "com.amazonaws.vpce.us-west-1.vpce-svc-09bb6ca26208063f2"
    }
    "us-gov-west-1" = {
      primary_endpoint   = "com.amazonaws.vpce.us-gov-west-1.vpce-svc-0f25e28401cbc9418"
      secondary_endpoint = "com.amazonaws.vpce.us-gov-west-1.vpce-svc-08fddf710780b2a54"
      region_type        = "govcloud"
    }
  }
}

# Combined locals block for all computed values
locals {
  # Computed AWS partition based on region
  computed_aws_partition = var.aws_partition != null ? var.aws_partition : (
    var.region == "us-gov-west-1" ? "aws-us-gov" : "aws"
  )

  # Computed Databricks provider host based on GovCloud shard
  computed_databricks_provider_host = var.databricks_provider_host != null ? var.databricks_provider_host : (
    var.databricks_gov_shard == "dod" ? "https://accounts-dod.cloud.databricks.mil" : (
      var.databricks_gov_shard == "civilian" ? "https://accounts.cloud.databricks.us" : "https://accounts.cloud.databricks.com"
    )
  )

  # Compute the correct Databricks account ID based on GovCloud shard
  databricks_aws_account_id = var.databricks_gov_shard == "civilian" ? "044793339203" : (
    var.databricks_gov_shard == "dod" ? "170661010020" : "414351767826"
  )

  # Compute the correct Databricks account ID for artifact buckets
  # Both GovCloud civilian and DoD shards use the same account ID for artifact buckets
  databricks_artifact_and_sample_data_account_id = var.databricks_gov_shard == "civilian" || var.databricks_gov_shard == "dod" ? "282567162347" : "414351767826"

  # Compute the correct Databricks account ID for EC2 images
  # GovCloud regions use a different account ID for AMIs
  databricks_ec2_image_account_id = var.region == "us-gov-west-1" ? "044732911619" : "601306020600"

  # Compute the correct AWS partition for assume role policies
  # Different partitions based on region and GovCloud shard type
  assume_role_partition = var.region == "us-gov-west-1" ? (
    var.databricks_gov_shard == "dod" ? "aws-us-gov-dod" : "aws-us-gov"
  ) : "aws"

  # Compute the correct Unity Catalog IAM ARN based on region and GovCloud shard type
  unity_catalog_iam_arn = var.region == "us-gov-west-1" ? (
    var.databricks_gov_shard == "dod" ? "arn:aws-us-gov:iam::170661010020:role/unity-catalog-prod-UCMasterRole-1DI6DL6ZP26AS" : "arn:aws-us-gov:iam::044793339203:role/unity-catalog-prod-UCMasterRole-1QRFA8SGY15OJ"
  ) : "arn:aws:iam::414351767826:role/unity-catalog-prod-UCMasterRole-14S5ZJVKOTYTL"

  # Backward compatibility variables - provide the same interface as the old simple map variables
  scc_relay = {
    for region, config in var.scc_relay_config : region => (
      region == "us-gov-west-1" && var.databricks_gov_shard == "dod" && config.secondary_endpoint != null ?
      config.secondary_endpoint : config.primary_endpoint
    )
  }

  workspace = {
    for region, config in var.workspace_config : region => (
      region == "us-gov-west-1" && var.databricks_gov_shard == "dod" && config.secondary_endpoint != null ?
      config.secondary_endpoint : config.primary_endpoint
    )
  }

  region_name = {
    for region, config in var.region_name_config : region => (
      region == "us-gov-west-1" && var.databricks_gov_shard == "dod" && config.secondary_name != null ?
      config.secondary_name : config.primary_name
    )
  }

  system_table_bucket = {
    for region, config in var.system_table_bucket_config : region => (
      region == "us-gov-west-1" && var.databricks_gov_shard == "dod" && config.secondary_bucket != null ?
      config.secondary_bucket : config.primary_bucket
    )
  }

  log_storage_bucket = {
    for region, config in var.log_storage_bucket_config : region => (
      region == "us-gov-west-1" && var.databricks_gov_shard == "dod" && config.secondary_bucket != null ?
      config.secondary_bucket : config.primary_bucket
    )
  }
}