// https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket
resource "google_storage_bucket" "bucket" {

  // ================= 以下為為值區命名頁面 =================
  project = var.project_id
  name    = var.name
  labels  = var.labels

  // ================= 以下為選取資料的儲存位置頁面 =================
  location = var.location
  dynamic "custom_placement_config" {
    for_each = var.custom_placement_config
    content {
      data_locations = lookup(custom_placement_config.value, "data_locations", null)
    }
  }

  // ================= 以下為資料選擇儲存空間級別頁面 =================
  autoclass {
    enabled = var.autoclass
  }
  storage_class = var.storage_class

  // ================= 以下為控制物件的存取權頁面 =================
  public_access_prevention    = var.public_access_prevention
  uniform_bucket_level_access = var.uniform_bucket_level_access
  force_destroy               = var.force_destroy

  // ================= 以下為保護物件資料頁面 =================
  dynamic "versioning" {
    for_each = var.versioning == null ? [] : [var.versioning]
    content {
      enabled = var.versioning
    }
  }

  dynamic "retention_policy" {
    for_each = var.retention_policy
    content {
      is_locked        = lookup(retention_policy.value, "is_locked", null)
      retention_period = lookup(retention_policy.value, "retention_period", null)
    }
  }

  // ================= 以下為保護物件資料頁面 =================
  dynamic "lifecycle_rule" {
    for_each = var.lifecycle_rule
    content {
      action {
        storage_class = lifecycle_rule.value.action[0].storage_class
        type          = lifecycle_rule.value.action[0].type
      }
      condition {
        age                        = lifecycle_rule.value.condition[0].age
        created_before             = lifecycle_rule.value.condition[0].created_before
        custom_time_before         = lifecycle_rule.value.condition[0].custom_time_before
        days_since_custom_time     = lifecycle_rule.value.condition[0].days_since_custom_time
        days_since_noncurrent_time = lifecycle_rule.value.condition[0].days_since_noncurrent_time
        matches_prefix             = lifecycle_rule.value.condition[0].matches_prefix
        matches_storage_class      = lifecycle_rule.value.condition[0].matches_storage_class
        matches_suffix             = lifecycle_rule.value.condition[0].matches_suffix
        no_age                     = lifecycle_rule.value.condition[0].no_age
        noncurrent_time_before     = lifecycle_rule.value.condition[0].noncurrent_time_before
        num_newer_versions         = lifecycle_rule.value.condition[0].num_newer_versions
        with_state                 = lifecycle_rule.value.condition[0].with_state
      }
    }
  }

  dynamic "cors" {
    for_each = var.cors
    content {
      origin          = lookup(cors.value, "origin", null)
      method          = lookup(cors.value, "method", null)
      response_header = lookup(cors.value, "response_header", null)
      max_age_seconds = lookup(cors.value, "max_age_seconds", null)
    }
  }

  timeouts {
  }
}
