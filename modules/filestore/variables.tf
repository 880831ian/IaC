variable "project_id" {
  type        = string
  description = "Filestore 所在的專案 ID (必填)"
}

variable "network_project_id" {
  type        = string
  description = "共享 VPC 專案的 ID，如果沒有設定，預設為專案 ID (選填)"
  default     = ""
}

variable "name" {
  type        = string
  description = "Filestore 名稱 (必填)"
}

variable "description" {
  type        = string
  description = "Filestore 描述 (選填)"
  default     = ""
}

variable "location" {
  type        = string
  description = "Filestore 儲存位置，如果 tier 是 ENTERPRISE 則 location 不能填寫單區域，Ex: asia-east1-b  (必填)"
}

variable "tier" {
  type        = string
  description = "Filestore 個體類型 (必填)"
  default     = "ENTERPRISE"
  validation {
    condition     = contains(["BASIC_HDD", "BASIC_SSD", "ENTERPRISE", "ZONAL"], var.tier)
    error_message = "不符合 Filestore 個體類型的值，請輸入 BASIC_HDD 或 BASIC_SSD 或 ENTERPRISE 或是 ZONAL"
  }
}

variable "file_shares_capacity_tib" {
  type        = number
  description = "Filestore 分配容量，預設為 1，除 BASIC_SSD 是 2.5 (單位: TiB) (必填)"
  default     = 1
}

variable "file_shares_name" {
  type        = string
  description = "Filestore 檔案共用區名稱 (必填)"
}

variable "network" {
  type        = string
  description = "Filestore 網路名稱 (必填)"
}

variable "connect_mode" {
  type        = string
  description = "Filestore 連線模式 (選填)"
  default     = "PRIVATE_SERVICE_ACCESS"
  validation {
    condition     = contains(["DIRECT_PEERING", "PRIVATE_SERVICE_ACCESS"], var.connect_mode)
    error_message = "不符合 Filestore 連線模式的值，請輸入 DIRECT_PEERING 或 PRIVATE_SERVICE_ACCESS"
  }
}

variable "labels" {
  type        = map(string)
  description = "Filestore 標籤，預設為空 (選填)"
  default     = {}
}