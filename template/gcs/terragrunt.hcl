terraform {
  source = "${get_path_to_repo_root()}/modules/gcs" // 此設定不需更改，用來自動抓 modules/gcs 的內容
}

include {
  path = find_in_parent_folders() // 此設定不需更改，用來抓取對應資料夾各層的設定檔案 (例如：template/terragrunt.hcl)
}

// 以下設定為範例，會列出適合本人使用的變數，請依照需求自行調整，沒有使用請刪除欄位以及空白行，維持程式整潔，後面會標示是否為必填，詳細參數說明可以參考 modules/gke/variables.tf 檔案
inputs = {
  name = "test" // Bucket 所在的專案 ID (必填)
  labels = {            // Bucket 標籤，預設為空 (選填)
    "env" = "test"
  }
  location = "ASIA"           // Bucket 所在地點，可以選 Multi-region、Dual-region、Region，如果選擇 Dual-region 需填寫 custom_placement_config (必填)
  custom_placement_config = [ // Bucket 自訂位置配置，如果選擇 Dual-region 才需填寫 custom_placement_config (必填)
    {
      "data_locations" = [
        "ASIA-EAST1",
        "ASIA-SOUTHEAST1"
      ]
    }
  ]
  autoclass                   = true        // Bucket 是否開啟 自動儲存類別，預設為 false (選填)
  storage_class               = "STANDARD"  // Bucket 資料儲存類別，預設為 STANDARD (選填)
  public_access_prevention    = "inherited" // Bucket 開放存取預防機制，預設為 enforced (選填)
  uniform_bucket_level_access = false       // Bucket 是否開啟統一儲存桶存取，預設為 true (選填)
  versioning                  = false       // Bucket 是否開啟版本控制，預設為 false，如果是 true，則不能設定 retention_policy (選填) 
  retention_policy = [                      // Bucket 資料保留政策，可以設定上傳到 Bucket 物件最短保留期限，避免遭到刪除或是修改，如果有設定，則不能設定 versioning，預設為空 (選填)
    {
      "is_locked"        = false,
      "retention_period" = 43200
    }
  ]
  lifecycle_rule = [ // Bucket 生命週期規則配置 (選填)
    {
      "action" = [
        {
          "storage_class" = "",
          "type"          = "Delete"
        }
      ],
      "condition" = [
        {
          "age"                        = 3,
          "created_before"             = "",
          "custom_time_before"         = "",
          "days_since_custom_time"     = 0,
          "days_since_noncurrent_time" = 0,
          "matches_prefix"             = [],
          "matches_storage_class"      = [],
          "matches_suffix"             = [],
          "no_age"                     = false,
          "noncurrent_time_before"     = "",
          "num_newer_versions"         = 0,
          "with_state"                 = "ANY"
        }
      ]
    }
  ]
  cors = [ // Bucket 跨來源資源共用 (CORS)配置 (選填)
    {
      "max_age_seconds" = 3600,
      "method" = [
        "GET",
        "HEAD",
        "DELETE"
      ],
      "origin" = [
        "*"
      ],
      "response_header" = [
        "Content-Type"
      ]
    }
  ]
}