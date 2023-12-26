variable "project_id" {
  type        = string
  description = "Memorystore 所在的專案 ID (必填)"
}

variable "network_project_id" {
  type        = string
  description = "共享 VPC 專案的 ID，如果沒有設定，預設為專案 ID (選填)"
  default     = ""
}

variable "name" {
  type        = string
  description = "Memorystore 名稱 (必填)"
}

variable "display_name" {
  type        = string
  description = "Memorystore 顯示名稱 (選填)"
  default     = null
}

variable "tier" {
  type        = string
  description = "Memorystore 個體類型 (選填)"
  default     = "STANDARD_HA"
  validation {
    condition     = contains(["BASIC", "STANDARD_HA"], var.tier)
    error_message = "不符合 Memorystore 個體類型的值，請輸入 BASIC 或 STANDARD_HA"
  }
}

variable "memory_size_gb" {
  type        = number
  description = "Memorystore memory 分配容量，預設為 5 (單位: GiB) (選填)"
  default     = 5
}

variable "region" {
  type        = string
  description = "Memorystore 所在的地區性 (必填)"
}

variable "replica_count" {
  type        = number
  description = "Memorystore replicas 數量，預設為 2，如果 tier 是 BASIC，則不用設定 (選填)"
  default     = 2
}

variable "read_replicas_mode" {
  type        = string
  description = "Memorystore 讀取 replicas 模式，如果 tier 是 BASIC，則不用設定 (選填)"
  default     = "READ_REPLICAS_ENABLED"
  validation {
    condition     = contains(["READ_REPLICAS_DISABLED", "READ_REPLICAS_ENABLED"], var.read_replicas_mode)
    error_message = "不符合 Memorystore 讀取 replicas 模式的值，請輸入 READ_REPLICAS_DISABLED 或 READ_REPLICAS_ENABLED"
  }
}

variable "network" {
  type        = string
  description = "Memorystore 網路名稱 (必填)"
}

variable "connect_mode" {
  type        = string
  description = "Memorystore 連線模式 (選填)"
  default     = "PRIVATE_SERVICE_ACCESS"
  validation {
    condition     = contains(["DIRECT_PEERING", "PRIVATE_SERVICE_ACCESS"], var.connect_mode)
    error_message = "不符合 Memorystore 連線模式的值，請輸入 DIRECT_PEERING 或 PRIVATE_SERVICE_ACCESS"
  }
}

variable "auth_enabled" {
  type        = bool
  description = "是否啟用 Memorystore Redis 的身份驗證，預設為 true (選填)"
  default     = true
}

variable "maintenance_policy" {
  type = object({
    day = string
    start_time = object({
      hours   = number
      minutes = number
      seconds = number
      nanos   = number
    })
  })
  description = "Memorystore Redis 維護排程 (選填)"
  default = {
    day = "TUESDAY" // 週三早上 6 點 - 7 點 (UTC+8)
    start_time = {
      hours   = 22
      minutes = 0
      seconds = 0
      nanos   = 0
    }
  }
}

variable "redis_version" {
  type        = string
  description = "Memorystore Redis 版本 (選填)"
  default     = "REDIS_5_0"
  validation {
    condition     = contains(["REDIS_5_0", "REDIS_6_X", "REDIS_7_0"], var.redis_version)
    error_message = "不符合 Memorystore Redis 版本的值，請輸入 REDIS_5_0 或 REDIS_6_X 或 REDIS_7_0"
  }
}

variable "redis_configs" {
  type        = map(any)
  description = "Memorystore Redis 設定參數 (https://cloud.google.com/memorystore/docs/redis/reference/rest/v1/projects.locations.instances#Instance.FIELDS.redis_configs) (選填)"
  default = {
    "maxmemory-policy" = "volatile-lru" // 很重要
  }
}

variable "labels" {
  type        = map(string)
  description = "Memorystore 標籤，預設為空 (選填)"
  default     = {}
}
