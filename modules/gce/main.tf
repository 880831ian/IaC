// https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance
resource "google_compute_instance" "instance" {
  provider = google

  project        = var.project_id
  name           = var.name
  zone           = var.zone
  machine_type   = var.machine_type
  enable_display = var.enable_display

  boot_disk {
    auto_delete = var.boot_disk_auto_delete
    device_name = var.boot_disk_device_name
    initialize_params {
      image  = var.boot_disk_image
      labels = var.labels
      size   = var.boot_disk_size
      type   = var.boot_disk_type
    }
    mode = var.boot_disk_mode
  }

  dynamic "service_account" {
    for_each = var.service_account_enabled ? [1] : []
    content {
      email  = var.service_account_email
      scopes = var.service_account_scopes
    }
  }

  tags = var.network_tags

  network_interface {
    network    = "projects/${local.network_project_id}/global/networks/${var.network}"
    subnetwork = "projects/${local.network_project_id}/regions/${local.region}/subnetworks/${var.subnetwork}"

    dynamic "access_config" {
      for_each = var.nat_ip_enabled ? [1] : []
      content {
      }
    }
  }

  dynamic "attached_disk" {
    for_each = var.attached_disk_enabled ? [1] : []
    content {
      device_name = var.attached_disk_device_name
      mode        = var.attached_disk_mode
      source      = var.attached_disk_source
    }
  }

  metadata                  = var.metadata
  resource_policies         = var.resource_policies
  deletion_protection       = var.deletion_protection
  allow_stopping_for_update = var.allow_stopping_for_update

  lifecycle {
    ignore_changes = [metadata["ssh-keys"]]
  }

  timeouts {}
}
