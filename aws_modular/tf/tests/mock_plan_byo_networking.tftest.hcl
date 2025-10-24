# Mock providers
mock_provider "aws" {}
mock_provider "databricks" {
  alias = "mws"
}

# Variables: BYO networking
variables {
  aws_account_id                   = "123456789012"
  databricks_account_id            = "12345678-90ab-cdef-1234-567890abcdef"
  region                           = "us-west-2"
  resource_prefix                  = "byo-network-test"
  admin_user                       = "workspace-admin@example.com"
  network_configuration            = "custom"
  custom_vpc_id                    = "vpc-0123456789abcdef0"
  custom_private_subnet_ids        = ["subnet-0aaa", "subnet-0bbb"]
  custom_sg_id                     = "sg-0123456789abcdef0"
  custom_workspace_vpce_id         = "vpce-0aaaa"
  custom_relay_vpce_id             = "vpce-0bbbb"
  use_existing_cross_account_role_arn = "arn:aws:iam::123456789012:role/DatabricksCrossAccount"
  use_existing_root_bucket_name    = "byo-root-bucket"
  use_existing_workspace_storage_kms_key_arn   = "arn:aws:kms:us-west-2:123456789012:key/abcd"
  use_existing_workspace_storage_kms_key_alias = "alias/workspace-storage"
  use_existing_managed_services_kms_key_arn    = "arn:aws:kms:us-west-2:123456789012:key/efgh"
  use_existing_managed_services_kms_key_alias  = "alias/managed-services"
  use_existing_network_connectivity_configuration_id = "ncc-1234"
  use_existing_network_policy_id   = "np-1234"
  metastore_exists                 = false
}

run "plan_test" {
  command = plan
}

