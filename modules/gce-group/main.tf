// https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_group
resource "google_compute_instance_group" "group" {
  provider = google

  project     = var.project_id
  name        = var.name
  zone        = var.zone
  description = var.description
  instances   = local.full_instance_paths
  dynamic "named_port" {
    for_each = var.named_ports
    content {
      name = named_port.value.name
      port = named_port.value.port
    }
  }
  network     = "projects/${local.network_project_id}/global/networks/${var.network}"

  timeouts {}
}
