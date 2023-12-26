// https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/filestore_instance
resource "google_filestore_instance" "instance" {
  provider = google

  project     = var.project_id
  name        = var.name
  location    = local.location
  description = var.description
  tier        = var.tier

  file_shares {
    name        = var.file_shares_name
    capacity_gb = local.file_shares_capacity_tib * 1024
  }

  networks {
    network      = "projects/${local.network_project_id}/global/networks/${var.network}"
    modes        = ["MODE_IPV4"]
    connect_mode = var.connect_mode
  }

  labels = var.labels
}