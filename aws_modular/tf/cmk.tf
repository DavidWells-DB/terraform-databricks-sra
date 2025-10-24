# EXPLANATION: The customer-managed keys for workspace and managed services

locals {
  cmk_admin_value = var.cmk_admin_arn == null ? "arn:${local.computed_aws_partition}:iam::${var.aws_account_id}:root" : var.cmk_admin_arn
}

resource "aws_kms_key" "workspace_storage" {
  count       = var.enable_cmk_workspace_storage && var.use_existing_workspace_storage_kms_key_arn == null ? 1 : 0
  description = "KMS key for databricks workspace storage"
  enable_key_rotation = local.effective_enable_kms_rotation
  policy = jsonencode({
    Version : "2012-10-17",
    "Id" : "key-policy-workspace-storage",
    Statement : [
      {
        "Sid" : "Enable IAM User Permissions",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : [local.cmk_admin_value]
        },
        "Action" : "kms:*",
        "Resource" : "*"
      },
      {
        "Sid" : "Allow Databricks to use KMS key for DBFS",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "arn:${local.computed_aws_partition}:iam::${local.databricks_aws_account_id}:root"
        },
        "Action" : [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        "Resource" : "*",
        "Condition" : {
          "StringEquals" : {
            "aws:PrincipalTag/DatabricksAccountId" : [var.databricks_account_id]
          }
        }
      },
      {
        "Sid" : "Allow Databricks to use KMS key for EBS",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : var.use_existing_cross_account_role_arn != null ? var.use_existing_cross_account_role_arn : aws_iam_role.cross_account_role[0].arn
        },
        "Action" : [
          "kms:Decrypt",
          "kms:GenerateDataKey*",
          "kms:CreateGrant",
          "kms:DescribeKey"
        ],
        "Resource" : "*",
        "Condition" : {
          "ForAnyValue:StringLike" : {
            "kms:ViaService" : "ec2.*.amazonaws.com"
          }
        }
      }
    ]
  })
  depends_on = [aws_iam_role.cross_account_role]

  tags = {
    Name    = "${var.resource_prefix}-workspace-storage-key"
    Project = var.resource_prefix
  }
}


resource "aws_kms_alias" "workspace_storage_key_alias" {
  count        = var.enable_cmk_workspace_storage && var.use_existing_workspace_storage_kms_key_arn == null ? 1 : 0
  name         = "alias/${var.resource_prefix}-workspace-storage-key"
  target_key_id = aws_kms_key.workspace_storage[0].id
}

# CMK for Managed Services

resource "aws_kms_key" "managed_services" {
  count       = var.enable_cmk_managed_services && var.use_existing_managed_services_kms_key_arn == null ? 1 : 0
  description = "KMS key for managed services"
  enable_key_rotation = local.effective_enable_kms_rotation
  policy = jsonencode({ Version : "2012-10-17",
    "Id" : "key-policy-managed-services",
    Statement : [
      {
        "Sid" : "Enable IAM User Permissions",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : [local.cmk_admin_value]
        },
        "Action" : "kms:*",
        "Resource" : "*"
      },
      {
        "Sid" : "Allow Databricks to use KMS key for managed services in the control plane",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "arn:${local.computed_aws_partition}:iam::${local.databricks_aws_account_id}:root"
        },
        "Action" : [
          "kms:Encrypt",
          "kms:Decrypt"
        ],
        "Resource" : "*",
        "Condition" : {
          "StringEquals" : {
            "aws:PrincipalTag/DatabricksAccountId" : [var.databricks_account_id]
          }
        }
      }
    ]
    }
  )

  tags = {
    Project = var.resource_prefix
    Name    = "${var.resource_prefix}-managed-services-key"
  }
}

resource "aws_kms_alias" "managed_services_key_alias" {
  count        = var.enable_cmk_managed_services && var.use_existing_managed_services_kms_key_arn == null ? 1 : 0
  name         = "alias/${var.resource_prefix}-managed-services-key"
  target_key_id = aws_kms_key.managed_services[0].key_id
}