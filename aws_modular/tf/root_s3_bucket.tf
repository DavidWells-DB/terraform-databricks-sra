# EXPLANATION: Create the workspace root bucket

resource "aws_s3_bucket" "root_storage_bucket" {
  count         = var.use_existing_root_bucket_name == null ? 1 : 0
  bucket        = "${var.resource_prefix}-workspace-root-storage"
  force_destroy = true
  tags = {
    Name    = "${var.resource_prefix}-workspace-root-storage"
    Project = var.resource_prefix
  }
}

resource "aws_s3_bucket_versioning" "root_bucket_versioning" {
  count  = var.use_existing_root_bucket_name == null ? 1 : 0
  bucket = aws_s3_bucket.root_storage_bucket[0].id
  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "root_storage_bucket" {
  count  = var.use_existing_root_bucket_name == null ? 1 : 0
  bucket = aws_s3_bucket.root_storage_bucket[0].bucket
  rule {
    bucket_key_enabled = true
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.use_existing_workspace_storage_kms_key_arn != null ? var.use_existing_workspace_storage_kms_key_arn : aws_kms_key.workspace_storage[0].arn
    }
  }
  depends_on = [aws_kms_alias.workspace_storage_key_alias]
}

resource "aws_s3_bucket_public_access_block" "root_storage_bucket" {
  count                   = var.use_existing_root_bucket_name == null ? 1 : 0
  bucket                  = aws_s3_bucket.root_storage_bucket[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
  depends_on              = [aws_s3_bucket.root_storage_bucket]
}

resource "aws_s3_bucket_ownership_controls" "root_storage_bucket" {
  count  = var.use_existing_root_bucket_name == null && local.effective_enable_s3_ownership_controls ? 1 : 0
  bucket = aws_s3_bucket.root_storage_bucket[0].id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

data "databricks_aws_bucket_policy" "this" {
  count                    = var.create_root_bucket_policy ? 1 : 0
  databricks_e2_account_id = var.databricks_account_id
  aws_partition            = local.assume_role_partition
  bucket                   = var.use_existing_root_bucket_name != null ? var.use_existing_root_bucket_name : aws_s3_bucket.root_storage_bucket[0].bucket
}

resource "aws_s3_bucket_policy" "root_bucket_policy" {
  count      = var.create_root_bucket_policy ? 1 : 0
  bucket     = var.use_existing_root_bucket_name != null ? var.use_existing_root_bucket_name : aws_s3_bucket.root_storage_bucket[0].id
  policy     = data.databricks_aws_bucket_policy.this[0].json
  depends_on = [aws_s3_bucket_public_access_block.root_storage_bucket]

  lifecycle {
    ignore_changes = [policy]
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "root_storage_ephemeral" {
  count  = var.use_existing_root_bucket_name == null && local.effective_enable_s3_ephemeral_lifecycle ? 1 : 0
  bucket = aws_s3_bucket.root_storage_bucket[0].id

  rule {
    id     = "expire-ephemeral"
    status = "Enabled"
    filter {
      prefix = "local_disk0/tmp/"
    }
    expiration {
      days = 7
    }
  }
  rule {
    id     = "expire-tmp"
    status = "Enabled"
    filter {
      prefix = "tmp/"
    }
    expiration {
      days = 14
    }
  }
}