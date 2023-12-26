variable "project_id" {
  type        = string
  description = "Bucket 所在的專案 ID (必填)"
}

variable "name" {
  type        = string
  description = "Bucket 名稱 (必填)"
}

variable "labels" {
  type        = map(string)
  description = "Bucket 標籤，預設為空 (選填)"
  default     = {}
}

variable "location" {
  type        = string
  description = "Bucket 所在地點，可以選 Multi-region、Dual-region、Region，如果選擇 Dual-region 需填寫 custom_placement_config (必填)"
}

variable "custom_placement_config" {
  type = list(object({
    data_locations = list(string)
  }))
  description = "Bucket 自訂位置配置，如果選擇 Dual-region 才需填寫 custom_placement_config (必填)"
  default     = []
}

variable "autoclass" {
  type        = bool
  description = "是否開啟 Bucket 自動儲存類別，預設為 false (選填)"
  default     = false
}

variable "storage_class" {
  type        = string
  description = "Bucket 資料儲存類別，預設為 STANDARD (選填)"
  default     = "STANDARD"
  validation {
    condition     = contains(["STANDARD", "NEARLINE", "COLDLINE", "ARCHIVE"], var.storage_class)
    error_message = "不符合 Bucket 資料儲存類別的值，請輸入 STANDARD 或 NEARLINE 或 COLDLINE 或 ARCHIVE"
  }
}

variable "public_access_prevention" {
  type        = string
  description = "Bucket 開放存取預防機制，預設為 enforced (選填)"
  default     = "enforced"
}

variable "uniform_bucket_level_access" {
  type        = bool
  description = "是否開啟 Bucket 統一儲存桶存取，預設為 true (選填)"
  default     = true
}

variable "force_destroy" {
  type        = bool
  description = "是否強制刪除 Bucket，如果是 false，將無法刪除包含物件的 Bucket，預設為 false (選填)"
  default     = false
}

variable "versioning" {
  type        = bool
  description = "是否開啟 Bucket 版本控制，預設為 false，如果是 true，則不能設定 retention_policy (選填)"
  default     = false
}

variable "retention_policy" {
  type = list(object({
    is_locked        = bool   // 是否鎖定 Bucket 物件，預設為 false，如果為 true，則無法刪除或修改 Bucket 物件 (不可逆)
    retention_period = number // 物件最短保留期限，單位為秒，預設為空
  }))
  description = "Bucket 資料保留政策，可以設定上傳到 Bucket 物件最短保留期限，避免遭到刪除或是修改，如果有設定，則不能設定 versioning，預設為空 (選填)"
  default     = []
}

variable "lifecycle_rule" {
  type = list(object({
    action = list(object({   // 生命週期規則的操作配置
      storage_class = string // 生命週期規則影響的物件，包含 STANDARD、NEARLINE、COLDLINE、ARCHIVE (如果 type 為 SetStorageClass 則為必填)
      type          = string // 生命週期規則的操作類型，包含 Delete 和 SetStorageClass 和 AbortIncompleteMultipartUpload
    }))
    condition = list(object({                   // 生命週期規則的條件配置
      age                        = number       // 存在時間 (天)
      created_before             = string       // 建立日期早於 (YYYY-MM-DD)
      custom_time_before         = string       // 自動時間早於 (YYYY-MM-DD)
      days_since_custom_time     = number       // 自訂時間迄今的天數 (天)
      days_since_noncurrent_time = number       // 非目前時間迄今的天數 (天)      
      matches_prefix             = list(string) // 物件名稱與前置字串相符
      matches_storage_class      = list(string) // 物件儲存類別相符
      matches_suffix             = list(string) // 物件名稱與後置字串相符
      no_age                     = bool         // 沒有存在時間
      noncurrent_time_before     = string       // 非目前時間早於 (YYYY-MM-DD)
      num_newer_versions         = number       // 較新版本的數量 
      with_state                 = string       // 物件狀態，包含 LIVE、ARCHIVED、ANY
    }))
  }))
  description = "Bucket 生命週期規則配置 (選填)，詳細請參考：https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket#action"
  default     = []
}

variable "cors" {
  type = list(object({
    max_age_seconds = number       // 預檢回應中使用的Access-Control-Max-Age 標頭中傳回的值 (單位秒)
    method          = list(string) // 要包含 CORS 回應標頭的 HTTP 方法清單
    origin          = list(string) // 有資格接收 CORS 回應標頭的來源清單
    response_header = list(string) // 除簡單回應標頭之外的 HTTP 標頭列表，用於授予用戶代理跨域共享的權限
  }))
  description = "Bucket 跨來源資源共用 (CORS)配置 (選填)"
  default     = []
}