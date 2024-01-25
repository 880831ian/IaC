// https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_node_pool
resource "google_container_node_pool" "pools" {
  provider = google

  for_each       = local.node_pools                      // 依照 node_pools 陣列帶入資料
  cluster        = google_container_cluster.primary.name // 叢集名稱
  project        = var.project_id                        // 叢集所在的專案 ID
  name           = each.key                              // Node Pool 名稱
  location       = local.location                        // 叢集所在的地區
  node_locations = lookup(each.value, "node_locations", "") != "" ? split(",", each.value["node_locations"]) : null

  version = lookup(each.value, "auto_upgrade", local.default_auto_upgrade) ? "" : lookup(
    each.value,
    "version",
    google_container_cluster.primary.min_master_version,
  )

  initial_node_count = lookup(each.value, "autoscaling", true) ? lookup(
    each.value,
    "total_min_count",
    lookup(each.value, "min_count", 1)
  ) : null

  // node 的數量，如果是 autoscaling 就不用設定，如果想固定數量就要設定 node_count
  node_count = lookup(each.value, "autoscaling", true) ? null : lookup(each.value, "node_count", 1)

  // Node Pool 的自動擴展設定
  dynamic "autoscaling" {
    for_each = lookup(each.value, "autoscaling", true) ? [each.value] : []
    content {
      // 先判斷有沒有設定 total_min_count 和 total_max_count，如果有設定就不用設定 min_count 和 max_count
      min_node_count = contains(keys(autoscaling.value), "total_min_count") ? null : lookup(autoscaling.value, "min_count", 1)
      max_node_count = contains(keys(autoscaling.value), "total_max_count") ? null : lookup(autoscaling.value, "max_count", 5)

      // Spot VM location_policy 預設值為 ANY (讓 Spot VM 被搶佔的風險降低)
      // https://cloud.google.com/kubernetes-engine/docs/concepts/cluster-autoscaler#default_values
      location_policy = lookup(each.value, "spot", false) ? "ANY" : "BALANCED"

      total_min_node_count = lookup(autoscaling.value, "total_min_count", null)
      total_max_node_count = lookup(autoscaling.value, "total_max_count", null)
    }
  }

  // Node Pool 的自動修復、自動升級設定
  // auto_upgrade 若沒有設定，會在 main.tf 裡面判斷，並帶入 auto_upgrade 的預設值
  management {
    auto_repair = lookup(each.value, "auto_repair", true)

    // 會先檢查 default_auto_upgrade 是否為 false，如果不是則會檢查有沒有設定 auto_upgrade，如果沒有設定，auto_upgrade = true
    auto_upgrade = local.default_auto_upgrade == false ? false : lookup(each.value, "auto_upgrade", true)
  }

  // Node Pool 的升級策略
  upgrade_settings {
    strategy        = lookup(each.value, "strategy", "SURGE")
    max_surge       = lookup(each.value, "strategy", "SURGE") == "SURGE" ? lookup(each.value, "max_surge", 1) : null
    max_unavailable = lookup(each.value, "strategy", "SURGE") == "SURGE" ? lookup(each.value, "max_unavailable", 0) : null

    // blue/green 升級策略的設定
    // 若需要使用 blue/green 升級策略，則需要設定 strategy ＝ BLUE_GREEN
    dynamic "blue_green_settings" {
      for_each = lookup(each.value, "strategy", "SURGE") == "BLUE_GREEN" ? [1] : []
      content {
        node_pool_soak_duration = lookup(each.value, "node_pool_soak_duration", null)

        standard_rollout_policy {
          batch_soak_duration = lookup(each.value, "batch_soak_duration", null)
          batch_percentage    = lookup(each.value, "batch_percentage", null)
          batch_node_count    = lookup(each.value, "batch_node_count", null)
        }
      }
    }
  }

  // Node Pool 的設定
  node_config {
    image_type      = lookup(each.value, "image_type", "COS_CONTAINERD") // Node Pool 的映像檔類型
    machine_type    = lookup(each.value, "machine_type", "e2-medium")    // Node Pool 的機器類型
    disk_size_gb    = lookup(each.value, "disk_size_gb", 100)            // Node Pool 使用的 disk 大小 (單位 gb)
    disk_type       = lookup(each.value, "disk_type", "pd-balanced")     // Node Pool 使用的 disk 類型  
    service_account = lookup(each.value, "service_account", "default")   // Node Pool 所使用的服務帳戶
    preemptible     = lookup(each.value, "preemptible", false)           // Node Pool 是否可被搶佔
    spot            = lookup(each.value, "spot", false)                  // Node Pool 是否使用 spot instance

    // Node Pool 的 oauth scopes 設定
    oauth_scopes = concat(
      local.node_pools_oauth_scopes["all"],
      local.node_pools_oauth_scopes[each.value["name"]],
    )

    // Node Pool 的 label 設定
    labels = merge(
      local.node_pools_labels["all"],
      local.node_pools_labels[each.value["name"]],
    )

    // Node Pool 的 metadata 設定
    metadata = merge(
      local.node_pools_metadata["all"],
      local.node_pools_metadata[each.value["name"]],
      {
        "disable-legacy-endpoints" = true
      }
    )

    // Node Pool 的污點設定
    dynamic "taint" {
      for_each = concat(
        local.node_pools_taints["all"],
        local.node_pools_taints[each.value["name"]],
      )
      content {
        effect = taint.value.effect
        key    = taint.value.key
        value  = taint.value.value
      }
    }

    // Node Pool 的 tag 設定
    tags = concat(
      local.node_pools_tags["all"],
      local.node_pools_tags[each.value["name"]],
    )
  }

  // 每個節點的最大pod數量
  max_pods_per_node = lookup(each.value, "max_pods_per_node", 64)

  lifecycle {
    ignore_changes = [
      initial_node_count
    ]
  }

  timeouts {
    create = lookup(var.timeouts, "create", "60m")
    update = lookup(var.timeouts, "update", "60m")
    delete = lookup(var.timeouts, "delete", "60m")
  }
}