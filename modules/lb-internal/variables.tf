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
  description = "Load balancer 名稱 (必填)"
}

variable "zone" {
  type        = string
  description = "Load balancer 跟 instance_group 區域 (必填)"
}

variable "protocol" {
  type        = string
  description = "Load balancer 後端通訊協定 (選填)"
  default     = "TCP"
  validation {
    condition     = contains(["HTTP", "HTTPS", "TCP"], var.protocol)
    error_message = "不符合 Load balancer 後端通訊協定的值，請輸入 HTTP 或 HTTPS 或 TCP"
  }
}

variable "network" {
  type        = string
  description = "Load balancer 網路名稱 (必填)"
}

variable "backends" {
  description = "Load balancer 後端服務設定 (必填)"
  type        = list(any)
}

variable "logging" {
  type        = bool
  description = "Load balancer 是否紀錄健康檢查日誌，預設是 false (選填)"
  default     = false
}

variable "connection_draining_timeout_sec" {
  type        = string
  description = "Load balancer 關閉連線的時間，預設為 300 秒 (選填)"
  default     = "300"
}

variable "health_check" {
  type = object({
    name                = optional(string)
    region              = bool
    description         = optional(string)
    type                = optional(string)
    port                = number
    proxy_header        = optional(string)
    request             = optional(string)
    response            = optional(string)
    request_path        = optional(string)
    host                = optional(string)
    enable_log          = bool
    check_interval_sec  = optional(number)
    timeout_sec         = optional(number)
    healthy_threshold   = optional(number)
    unhealthy_threshold = optional(number)
  })
  description = "Load balancer 健康檢查設定 (必填)"
  default = {
    name                = ""
    region              = false
    description         = ""
    type                = "TCP"
    port                = 80
    proxy_header        = "NONE"
    request             = ""
    response            = ""
    request_path        = "/"
    host                = ""
    enable_log          = false
    check_interval_sec  = 5
    timeout_sec         = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

variable "forwarding_rules" {
  type = map(object({
    description                     = optional(string)
    ip_version                      = optional(string)
    network                         = string
    subnetwork                      = string
    internal_ip_address_name        = optional(string)       // 靜態 IP 名稱
    internal_ip_address_description = optional(string)       // 靜態 IP 描述
    internal_ip_address             = optional(string)       // 靜態 IP 位址
    ports                           = optional(list(number)) // 多個 Port，最多 5 個
    all_ports                       = optional(bool)         // 是否開啟所有 Port
    global_access                   = optional(bool)         // 是否開啟全域存取
    service_label                   = optional(string)       // 服務標籤
  }))
  description = "Load balancer 健康檢查設定 (必填)"
}
