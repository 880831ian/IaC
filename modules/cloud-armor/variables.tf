variable "project_id" {
  type        = string
  description = "cloud armor 所在的專案 ID (必填)"
}

variable "name" {
  type        = string
  description = "cloud armor 名字 (必填)"
}

variable "description" {
  type        = string
  default     = ""
  description = "cloud armor 描述 (選填)"
}

variable "rule_items" {
  type = list(object({
    action        = string
    description   = string
    src_ip_ranges = list(string)
    priority      = number
  }))
  default     = []
  description = "cloud armor 規則 (選填)"
}

variable "deny_all" {
  type        = bool
  default     = true
  description = "預設規則是否為 deny (false 則為 allow all，預設 true)"
}
