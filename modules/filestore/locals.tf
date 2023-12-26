locals {
  network_project_id               = var.network_project_id != "" ? var.network_project_id : var.project_id
  location                         = var.tier == "ENTERPRISE" && length(regexall("-", var.location)) == 2 ? substr(var.location, 0, length(var.location) - 2) : var.location
  default_file_shares_capacity_tib = var.tier == "BASIC_SSD" ? 2.5 : 1
  file_shares_capacity_tib         = coalesce(var.file_shares_capacity_tib, local.default_file_shares_capacity_tib)
}