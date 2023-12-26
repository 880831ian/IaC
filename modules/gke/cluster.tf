// https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_cluster
resource "google_container_cluster" "primary" {
  provider = google

  // ================= 以下為 Cluster 基本設定頁面 =================
  name           = var.name             // 叢集名稱
  project        = var.project_id       // 叢集所在的 project id
  location       = local.location       // 叢集所在的地區
  node_locations = local.node_locations // 叢集節點所在的地區

  // GKE 發布頻道
  dynamic "release_channel" {
    for_each = local.release_channel

    content {
      channel = release_channel.value.channel
    }
  }

  // GKE Master 最低版本
  min_master_version = var.release_channel == null || var.release_channel == "UNSPECIFIED" ? local.master_version : var.kubernetes_version == "latest" ? null : var.kubernetes_version

  // ================= 以下為 Cluster 自動化設定頁面 =================
  // 維護政策
  dynamic "maintenance_policy" {
    for_each = local.enable_maintenance ? [1] : []

    content {
      dynamic "recurring_window" {
        for_each = local.cluster_maintenance_window_is_recurring
        content {
          start_time = var.maintenance_start_time
          end_time   = var.maintenance_end_time
          recurrence = var.maintenance_recurrence
        }
      }
    }
  }

  // ================= 以下為 Cluster 網路設定頁面 =================
  network    = "projects/${local.network_project_id}/global/networks/${var.network}"
  subnetwork = "projects/${local.network_project_id}/regions/${local.region}/subnetworks/${var.subnetwork}"

  // 私人叢集設定
  dynamic "private_cluster_config" {
    for_each = var.enable_private_nodes ? [{
      enable_private_nodes    = var.enable_private_nodes,
      enable_private_endpoint = var.enable_private_endpoint
      master_ipv4_cidr_block  = var.master_ipv4_cidr_block
    }] : []

    content {
      enable_private_endpoint = private_cluster_config.value.enable_private_endpoint
      enable_private_nodes    = private_cluster_config.value.enable_private_nodes
      master_ipv4_cidr_block  = private_cluster_config.value.master_ipv4_cidr_block
    }
  }

  // 預設 snat 設定，預設開啟
  default_snat_status {
    disabled = false
  }

  // 節點的預設最大 Pod 數量
  default_max_pods_per_node = var.default_max_pods_per_node

  // 叢集分配 VPC IP 的設定
  ip_allocation_policy {
    cluster_secondary_range_name  = var.ip_range_pods
    services_secondary_range_name = var.ip_range_services
  }

  addons_config {
    // HTTP (L7) 負載平衡控制器外掛程式的狀態，預設開啟
    http_load_balancing {
      disabled = false
    }

    // Horizo​​ntal Pod Autoscaling 外掛程式的狀態，預設開啟
    horizontal_pod_autoscaling {
      disabled = false
    }

    // GCSFuse CSI 驅動程式插件的狀態，預設關閉
    dynamic "gcs_fuse_csi_driver_config" {
      for_each = local.gcs_fuse_csi_driver_config

      content {
        enabled = gcs_fuse_csi_driver_config.value.enabled
      }
    }
  }

  // 授權的主網路清單
  dynamic "master_authorized_networks_config" {
    for_each = local.master_authorized_networks_config
    content {
      dynamic "cidr_blocks" {
        for_each = master_authorized_networks_config.value.cidr_blocks
        content {
          cidr_block   = lookup(cidr_blocks.value, "cidr_block", "")
          display_name = lookup(cidr_blocks.value, "display_name", "")
        }
      }
    }
  }

  // dns 設定
  dynamic "dns_config" {
    for_each = var.cluster_dns_provider == "CLOUD_DNS" ? [1] : []
    content {
      cluster_dns       = var.cluster_dns_provider
      cluster_dns_scope = var.cluster_dns_scope
    }
  }

  // ================= 以下為 Cluster 安全設定頁面 =================
  dynamic "binary_authorization" {
    for_each = var.enable_binary_authorization ? [var.enable_binary_authorization] : []
    content {
      evaluation_mode = "DISABLED"
    }
  }

  enable_shielded_nodes = true // 開啟 Shielded GKE Node

  // Workload Identity 設定
  dynamic "workload_identity_config" {
    for_each = var.enable_workload_identity ? [1] : []

    content {
      workload_pool = local.cluster_workload_identity_config
    }
  }

  // ================= 以下為 Cluster Metadata 設定頁面 =================
  description     = var.description             // 叢集描述
  resource_labels = var.cluster_resource_labels // 叢集的 GCE 資源標籤

  // ================= 以下為 Cluster Features 設定頁面 =================
  // 日誌設定
  dynamic "logging_config" {
    for_each = length(var.logging_enabled_components) > 0 ? [1] : []

    content {
      enable_components = var.logging_enabled_components
    }
  }

  // 監控設定
  dynamic "monitoring_config" {
    for_each = length(var.monitoring_enabled_components) > 0 || var.monitoring_enable_managed_prometheus ? [1] : []

    content {
      enable_components = var.monitoring_enabled_components
      managed_prometheus {
        enabled = var.monitoring_enable_managed_prometheus
      }
    }
  }

  // 刪除預設的 default-pool node_pool
  remove_default_node_pool = var.remove_default_node_pool
  initial_node_count       = 1

  // 保護 cluster 不被刪除 可以使用 deletion_protection = false 關閉保護
  deletion_protection = var.deletion_protection

  lifecycle {
    ignore_changes = [node_pool, initial_node_count, resource_labels["asmv"], resource_labels["mesh_id"]]
  }

  timeouts {
    create = lookup(var.timeouts, "create", "90m")
    update = lookup(var.timeouts, "update", "90m")
    delete = lookup(var.timeouts, "delete", "90m")
  }
}
