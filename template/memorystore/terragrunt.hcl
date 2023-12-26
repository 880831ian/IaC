terraform {
  source = "${get_path_to_repo_root()}/modules/memorystore" // 此設定不需更改，用來自動抓 modules/memorystore 的內容
}

include {
  path = find_in_parent_folders() // 此設定不需更改，用來抓取對應資料夾各層的設定檔案 (例如：template/terragrunt.hcl)
}

// 以下設定為範例，會列出適合本人使用的變數，請依照需求自行調整，沒有使用請刪除欄位以及空白行，維持程式整潔，後面會標示是否為必填，詳細參數說明可以參考 modules/memorystore/variables.tf 檔案
inputs = {
  name               = "redis"                  // Memorystore 名稱 (必填)
  display_name       = "redis"                  // Memorystore 顯示名稱 (選填)
  tier               = "STANDARD_HA"            // Memorystore 個體類型 (選填)
  memory_size_gb     = 5                        // Memorystore memory 分配容量，預設為 5 (單位: GiB) (選填)
  region             = "asia-east1"             // Memorystore 所在的地區性 (必填)
  replica_count      = 1                        // Memorystore replicas 數量，預設為 2，如果 tier 是 BASIC，則不用設定 (選填)
  read_replicas_mode = "READ_REPLICAS_ENABLED"  // Memorystore 讀取 replicas 模式，如果 tier 是 BASIC，則不用設定 (選填)
  network            = "bbin-testdev"           // Memorystore 網路名稱 (必填)
  connect_mode       = "PRIVATE_SERVICE_ACCESS" // Memorystore 連線模式 (選填)"
  auth_enabled       = true                     // Memorystore 是否啟用身分驗證，預設為 true (選填)
  maintenance_policy = {                        // Memorystore Redis 維護排程 (選填)
    day = "TUESDAY"
    start_time = {
      "hours"   = 22
      "minutes" = 0
      "nanos"   = 0
      "seconds" = 0
    }
  }
  redis_version = "REDIS_5_0" // Memorystore Redis 版本，預設為 REDIS_5_0 (選填)
  redis_configs = {           // Memorystore Redis 設定參數 (選填)
    maxmemory-policy = "allkeys-lru"
  }
  labels = { // Memorystore 標籤，預設為空 (選填)
    env = "test"
  }
}
