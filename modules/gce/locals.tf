locals {
  network_project_id = var.network_project_id != "" ? var.network_project_id : var.project_id
  region             = join("-", slice(split("-", var.zone), 0, 2))
}