# Terraform Documentation: https://registry.terraform.io/providers/databricks/databricks/latest/docs/guides/unity-catalog

# Optional data source - only run if the metastore exists
data "databricks_metastore" "this" {
  count  = var.metastore_exists ? 1 : 0
  name   = var.metastore_name != null ? var.metastore_name : "${var.region}-unity-catalog"
}

resource "databricks_metastore" "this" {
  count         = var.metastore_exists ? 0 : 1
  name          = var.metastore_name != null ? var.metastore_name : "${var.region}-unity-catalog"
  region        = var.region
  force_destroy = true
}