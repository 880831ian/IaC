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
  description = "GCE_GROUP 名稱 (必填)"
}

variable "description" {
  type        = string
  description = "GCE_GROUP 描述 (選填)"
  default     = ""
}

variable "zone" {
  type        = string
  description = "GCE_GROUP 區域 (必填)"
}

variable "instances" {
  type        = list(string)
  description = "GCE_GROUP 使用機器名稱 (選填)"
  default     = []
}

variable "named_ports" {
  type        = list(object({
    name = string
    port = number
  }))
  description = "GCE_GROUP 連接埠映射 (選填)"
  default     = []
}

variable "network" {
  type        = string
  description = "GCE_GROUP 網路名稱 (必填)"
}