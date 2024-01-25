// https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_address
resource "google_compute_address" "address" {
  provider = google

  project      = var.project_id
  name         = var.name
  description  = var.description
  region       = var.region
  address_type = var.address_type
  address      = var.ip_address
  network_tier = var.address_type == "EXTERNAL" ? coalesce(var.network_tier, "PREMIUM") : var.address_type == "INTERNAL" ? null : null
  subnetwork   = var.address_type == "INTERNAL" ? "projects/${local.network_project_id}/regions/${var.region}/subnetworks/${var.subnetwork}" : null
  labels       = var.labels

  timeouts {}
}