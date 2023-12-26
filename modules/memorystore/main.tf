// https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/redis_instance
resource "google_redis_instance" "instance" {
  provider = google

  project        = var.project_id
  name           = var.name
  display_name   = var.display_name
  tier           = var.tier
  memory_size_gb = var.memory_size_gb
  region         = var.region

  // ================= 以下為 Redis 唯獨備用資源頁面 =================
  replica_count      = var.tier == "STANDARD_HA" ? var.replica_count : null
  read_replicas_mode = var.tier == "STANDARD_HA" ? var.read_replicas_mode : null

  // ================= 以下為 Redis 連線頁面 =================
  authorized_network = "projects/${local.network_project_id}/global/networks/${var.network}"
  connect_mode       = var.connect_mode

  // ================= 以下為 Redis 安全性頁面 =================
  auth_enabled = var.auth_enabled

  // ================= 以下為 Redis 維護頁面 =================
  dynamic "maintenance_policy" {
    for_each = var.maintenance_policy != null ? [var.maintenance_policy] : []
    content {
      weekly_maintenance_window {
        day = maintenance_policy.value["day"]
        start_time {
          hours   = maintenance_policy.value["start_time"]["hours"]
          minutes = maintenance_policy.value["start_time"]["minutes"]
          seconds = maintenance_policy.value["start_time"]["seconds"]
          nanos   = maintenance_policy.value["start_time"]["nanos"]
        }
      }
    }
  }

  // ================= 以下為 Redis 設定頁面 =================
  redis_version = var.redis_version
  redis_configs = var.redis_configs
  labels        = var.labels
}
