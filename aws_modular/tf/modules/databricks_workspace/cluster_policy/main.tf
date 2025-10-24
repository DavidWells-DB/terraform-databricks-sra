resource "databricks_cluster_policy" "baseline" {
  name       = "Baseline Cluster Policy"
  definition = jsonencode({
    "spark_version" : {
      "type" : "fixed",
      "value" : "13.3.x-scala2.12",
      "hidden" : false
    },
    "autotermination_minutes" : {
      "type" : "range",
      "minValue" : 10,
      "maxValue" : 120,
      "defaultValue" : 30
    },
    "spark_conf.spark.databricks.cluster.profile" : {
      "type" : "fixed",
      "value" : "singleNode"
    },
    "custom_tags.SRA" : {
      "type" : "fixed",
      "value" : "${var.resource_prefix}"
    }
  })
}

