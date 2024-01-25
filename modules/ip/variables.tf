variable "project_id" {
  type        = string
  description = "GCP 專案 ID"
}

variable "network_project_id" {
  type        = string
  description = "共享 VPC 專案的 ID，如果沒有設定，預設為專案 ID (選填)"
  default     = ""
}

variable "name" {
  type        = string
  description = "IP 位址名稱 (必填)"
}

variable "description" {
  type        = string
  description = "IP 位址描述 (選填)"
  default     = ""
}

variable "region" {
  type        = string
  description = "IP 位址地區 (必填)"
}

variable "address_type" {
  type        = string
  description = "IP 位址類型 (必填)"
}

variable "ip_address" {
  type        = string
  description = "IP 位址 (選填)"
  default     = ""
}

variable "subnetwork" {
  type        = string
  description = "IP 位址子網路，只有 address_type 是 INTERNAL，才需要填寫 (選填)"
  default     = ""
}

variable "network_tier" {
  type        = string
  description = "IP 網路層級"
  default     = "PREMIUM"
  validation {
    condition     = contains(["PREMIUM", "STANDARD"], var.network_tier)
    error_message = "不符合 IP 網路層級的值，請輸入 PREMIUM 或 STANDARD"
  }
}

variable "labels" {
  type        = map(string)
  description = "IP 位址標籤，預設為空 (選填)"
  default     = {}
}