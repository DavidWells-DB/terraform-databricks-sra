locals {
  warehouse_id   = var.warehouse_id == "" ? databricks_sql_endpoint.this[0].id : data.databricks_sql_warehouse.this[0].id
  data_source_id = var.warehouse_id == "" ? databricks_sql_endpoint.this[0].data_source_id : data.databricks_sql_warehouse.this[0].data_source_id
}

resource "databricks_sql_endpoint" "this" {
  count            = var.warehouse_id == "" ? 1 : 0
  warehouse_type   = "PRO"
  name             = "System Tables"
  cluster_size     = "Small"
  max_num_clusters = 1
  auto_stop_mins   = 10
}

data "databricks_sql_warehouse" "this" {
  count = var.warehouse_id == "" ? 0 : 1
  id    = var.warehouse_id
}

resource "databricks_query" "query" {
  for_each     = local.queries
  warehouse_id = local.warehouse_id
  display_name = local.data_map[each.value].name
  query_text   = local.data_map[each.value].query
  parent_path  = "${data.databricks_current_user.me.home}/${local.data_map[each.value].parent}"
  description  = local.data_map[each.value].description
}

resource "databricks_alert" "alert" {
  for_each     = local.alerts
  query_id     = databricks_query.query[each.value].id
  display_name = local.data_map[each.value].alert.name
  parent_path  = "${data.databricks_current_user.me.home}/${local.data_map[each.value].alert.parent}"

  condition {
    op = local.data_map[each.value].alert.options.op
    operand {
      column { name = local.data_map[each.value].alert.options.column }
    }
  }
}