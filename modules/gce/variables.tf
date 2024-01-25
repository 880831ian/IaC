variable "project_id" {
  type        = string
  description = "GCE 所在的專案 ID (必填)"
}

variable "network_project_id" {
  type        = string
  description = "共享 VPC 專案的 ID，如果沒有設定，預設為專案 ID (選填)"
  default     = ""
}

variable "name" {
  type        = string
  description = "GCE 名稱 (必填)"
}

variable "zone" {
  type        = string
  description = "GCE 區域 (必填)"
}

variable "machine_type" {
  type        = string
  description = "GCE 機器類型 (必填)"
}

variable "enable_display" {
  type        = bool
  description = "是否啟用虛擬顯示，預設為關閉 (選填)"
  default     = false
}

variable "boot_disk_auto_delete" {
  type        = bool
  description = "是否自動刪除開機磁碟，預設為開啟 (選填)"
  default     = true
}

variable "boot_disk_device_name" {
  type        = string
  description = "GCE 設定名稱，預設與 name 相同 (選填)"
  default     = ""
}

variable "boot_disk_image" {
  type        = string
  description = "GCE 映像檔，預設為空 (選填)"
  default     = ""
}

variable "boot_disk_size" {
  type        = number
  description = "GCE 開機磁碟大小，預設為 10 (單位: GB) (選填)"
  default     = 10
}

variable "boot_disk_type" {
  type        = string
  description = "GCE 開機磁碟類型，預設為 pd-balanced (選填)"
  default     = "pd-balanced"
  validation {
    condition     = contains(["pd-standard", "pd-balanced", "pd-ssd"], var.boot_disk_type)
    error_message = "不符合開機磁碟類型的值，請輸入 pd-standard 或 pd-balanced 或 pd-ssd"
  }
}

variable "boot_disk_mode" {
  type        = string
  description = "GCE 開機磁碟模式，預設為 READ_WRITE (選填)"
  default     = "READ_WRITE"
  validation {
    condition     = contains(["READ_WRITE", "READ_ONLY"], var.boot_disk_mode)
    error_message = "不符合開機磁碟模式的值，請輸入 READ_WRITE 或 READ_ONLY"
  }
}

variable "attached_disk_enabled" {
  type        = bool
  description = "是否啟用附加磁碟，預設為關閉 (選填)"
  default     = false
}

variable "attached_disk_device_name" {
  type        = string
  description = "GCE 附加磁碟名稱，預設為空 (選填)"
  default     = ""
}

variable "attached_disk_mode" {
  type        = string
  description = "GCE 附加磁碟模式，預設為 READ_WRITE (選填)"
  default     = "READ_WRITE"
  validation {
    condition     = contains(["READ_WRITE", "READ_ONLY"], var.attached_disk_mode)
    error_message = "不符合附加磁碟模式的值，請輸入 READ_WRITE 或 READ_ONLY"
  }
}

variable "attached_disk_source" {
  type        = string
  description = "GCE 附加磁碟來源，預設為空 (選填)"
  default     = ""
}

variable "network" {
  type        = string
  description = "GCE 網路名稱 (必填)"
}

variable "subnetwork" {
  type        = string
  description = "GCE 子網路名稱 (必填)"
}

variable "nat_ip_enabled" {
  type        = bool
  description = "是否啟用外網 IP，預設為關閉 (選填)"
  default     = false
}

variable "labels" {
  type        = map(string)
  description = "GCE 標籤，預設為空 (選填)"
  default     = {}
}

variable "network_tags" {
  type        = list(string)
  description = "GCE 網路標記，預設為空 (選填)"
  default     = []
}

variable "metadata" {
  type        = map(string)
  description = "GCE 中繼資料，預設為空 (選填)"
  default     = {}
}

variable "resource_policies" {
  type        = list(string)
  description = "附加到機器的資源策略的 self_links 清單，預設為空 (選填)"
  default     = []
}

variable "service_account_enabled" {
  type        = bool
  description = "是否啟用服務帳戶，預設為開啟 (選填)"
  default     = true
}

variable "service_account_email" {
  type        = string
  description = "GCE 服務帳戶電子郵件，預設為空 (選填)"
  default     = ""
}

variable "service_account_scopes" {
  type        = list(string)
  description = "GCE 服務帳戶範圍，預設請參考 variables.tf (選填)"
  default = [
    "https://www.googleapis.com/auth/devstorage.read_only",
    "https://www.googleapis.com/auth/logging.write",
    "https://www.googleapis.com/auth/monitoring.write",
    "https://www.googleapis.com/auth/service.management.readonly",
    "https://www.googleapis.com/auth/servicecontrol",
    "https://www.googleapis.com/auth/trace.append"
  ]
}

variable "deletion_protection" {
  type        = bool
  description = "是否啟用刪除保護，預設為關閉 (選填)"
  default     = false
}

variable "allow_stopping_for_update" {
  type        = bool
  description = "是否允許自動停止後更新，預設為關閉 (選填)"
  default     = false
}

# ====================
variable "internal_ip_address_name" {
  type        = string
  description = "內網 IP 名稱，預設為 [GCE Name]-internal (選填)"
  default     = ""
}

variable "internal_ip_address_description" {
  type        = string
  description = "內網 IP 描述，預設為空 (選填)"
  default     = ""
}

variable "internal_ip_address" {
  type        = string
  description = "內網 IP，預設為空 (選填)"
  default     = ""
}

variable "external_ip_address_name" {
  type        = string
  description = "外網 IP 名稱，需要設定，請先開啟 nat_ip_enabled，預設為 [GCE Name]-external (選填)"
  default     = ""
}

variable "external_ip_address_description" {
  type        = string
  description = "外網 IP 描述，預設為空 (選填)"
  default     = ""
}

variable "external_ip_address" {
  type        = string
  description = "外網 IP，預設為空 (選填)"
  default     = ""
}

variable "external_network_tier" {
  type        = string
  description = "外網 IP 網路層級，預設為 PREMIUM (選填)"
  default     = "PREMIUM"
  validation {
    condition     = contains(["PREMIUM", "STANDARD"], var.external_network_tier)
    error_message = "不符合 IP 外網網路層級的值，請輸入 PREMIUM 或 STANDARD"
  }
}