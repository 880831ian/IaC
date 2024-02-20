// https://registry.terraform.io/modules/terraform-google-modules/lb-internal/google
// https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_region_backend_service
resource "google_compute_region_backend_service" "backend" {
  provider = google

  project  = var.project_id
  name     = var.name
  region   = local.region
  protocol = var.protocol

  network = "projects/${local.network_project_id}/global/networks/${var.network}"

  dynamic "backend" {
    for_each = var.backends
    content {
      group       = "https://www.googleapis.com/compute/v1/projects/${var.project_id}/zones/${var.zone}/instanceGroups/${lookup(backend.value, "group", null)}"
      description = lookup(backend.value, "description", null)
      failover    = lookup(backend.value, "failover", null)
    }
  }

  health_checks = concat(google_compute_health_check.tcp[*].self_link, google_compute_health_check.http[*].self_link, google_compute_health_check.https[*].self_link, google_compute_region_health_check.tcp[*].self_link, google_compute_region_health_check.http[*].self_link, google_compute_region_health_check.https[*].self_link)

  log_config {
    enable = var.logging
  }

  connection_draining_timeout_sec = var.connection_draining_timeout_sec

  timeouts {}
}

// https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_region_health_check
resource "google_compute_region_health_check" "tcp" {
  provider = google
  count    = var.health_check["type"] == "TCP" && var.health_check["region"] == true ? 1 : 0

  project = var.project_id
  name    = var.health_check["name"] != null ? var.health_check["name"] : "${var.name}-hc-tcp"

  tcp_health_check {
    port         = var.health_check["port"]
    proxy_header = var.health_check["proxy_header"]
    request      = var.health_check["request"]
    response     = var.health_check["response"]
  }

  dynamic "log_config" {
    for_each = var.health_check["enable_log"] ? [true] : []
    content {
      enable = true
    }
  }

  check_interval_sec  = var.health_check["check_interval_sec"]
  timeout_sec         = var.health_check["timeout_sec"]
  healthy_threshold   = var.health_check["healthy_threshold"]
  unhealthy_threshold = var.health_check["unhealthy_threshold"]

  timeouts {}
}


resource "google_compute_region_health_check" "http" {
  provider = google
  count    = var.health_check["type"] == "HTTP" && var.health_check["region"] == false ? 1 : 0

  project = var.project_id
  name    = var.health_check["name"] != null ? var.health_check["name"] : "${var.name}-hc-http"

  http_health_check {
    port         = var.health_check["port"]
    proxy_header = var.health_check["proxy_header"]
    request_path = var.health_check["request_path"]
    response     = var.health_check["response"]
    host         = var.health_check["host"]
  }

  dynamic "log_config" {
    for_each = var.health_check["enable_log"] ? [true] : []
    content {
      enable = true
    }
  }

  check_interval_sec  = var.health_check["check_interval_sec"]
  timeout_sec         = var.health_check["timeout_sec"]
  healthy_threshold   = var.health_check["healthy_threshold"]
  unhealthy_threshold = var.health_check["unhealthy_threshold"]

  timeouts {}
}

resource "google_compute_region_health_check" "https" {
  provider = google
  count    = var.health_check["type"] == "HTTPS" && var.health_check["region"] == false ? 1 : 0

  project = var.project_id
  name    = var.health_check["name"] != null ? var.health_check["name"] : "${var.name}-hc-https"

  https_health_check {
    port         = var.health_check["port"]
    proxy_header = var.health_check["proxy_header"]
    request_path = var.health_check["request_path"]
    response     = var.health_check["response"]
    host         = var.health_check["host"]
  }

  dynamic "log_config" {
    for_each = var.health_check["enable_log"] ? [true] : []
    content {
      enable = true
    }
  }

  check_interval_sec  = var.health_check["check_interval_sec"]
  timeout_sec         = var.health_check["timeout_sec"]
  healthy_threshold   = var.health_check["healthy_threshold"]
  unhealthy_threshold = var.health_check["unhealthy_threshold"]

  timeouts {}
}

// https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_health_check
resource "google_compute_health_check" "tcp" {
  provider = google
  count    = var.health_check["type"] == "TCP" && var.health_check["region"] == false ? 1 : 0

  project = var.project_id
  name    = var.health_check["name"] != null ? var.health_check["name"] : "${var.name}-hc-tcp"

  tcp_health_check {
    port         = var.health_check["port"]
    proxy_header = var.health_check["proxy_header"]
    request      = var.health_check["request"]
    response     = var.health_check["response"]
  }

  dynamic "log_config" {
    for_each = var.health_check["enable_log"] ? [true] : []
    content {
      enable = true
    }
  }

  check_interval_sec  = var.health_check["check_interval_sec"]
  timeout_sec         = var.health_check["timeout_sec"]
  healthy_threshold   = var.health_check["healthy_threshold"]
  unhealthy_threshold = var.health_check["unhealthy_threshold"]

  timeouts {}
}

resource "google_compute_health_check" "http" {
  provider = google
  count    = var.health_check["type"] == "HTTP" && var.health_check["region"] == false ? 1 : 0

  project = var.project_id
  name    = var.health_check["name"] != null ? var.health_check["name"] : "${var.name}-hc-http"

  http_health_check {
    port         = var.health_check["port"]
    proxy_header = var.health_check["proxy_header"]
    request_path = var.health_check["request_path"]
    response     = var.health_check["response"]
    host         = var.health_check["host"]
  }

  dynamic "log_config" {
    for_each = var.health_check["enable_log"] ? [true] : []
    content {
      enable = true
    }
  }

  check_interval_sec  = var.health_check["check_interval_sec"]
  timeout_sec         = var.health_check["timeout_sec"]
  healthy_threshold   = var.health_check["healthy_threshold"]
  unhealthy_threshold = var.health_check["unhealthy_threshold"]

  timeouts {}
}

resource "google_compute_health_check" "https" {
  provider = google
  count    = var.health_check["type"] == "HTTPS" && var.health_check["region"] == false ? 1 : 0

  project = var.project_id
  name    = var.health_check["name"] != null ? var.health_check["name"] : "${var.name}-hc-https"

  https_health_check {
    port         = var.health_check["port"]
    proxy_header = var.health_check["proxy_header"]
    request_path = var.health_check["request_path"]
    response     = var.health_check["response"]
    host         = var.health_check["host"]
  }

  dynamic "log_config" {
    for_each = var.health_check["enable_log"] ? [true] : []
    content {
      enable = true
    }
  }

  check_interval_sec  = var.health_check["check_interval_sec"]
  timeout_sec         = var.health_check["timeout_sec"]
  healthy_threshold   = var.health_check["healthy_threshold"]
  unhealthy_threshold = var.health_check["unhealthy_threshold"]

  timeouts {}
}

// https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_forwarding_rule
resource "google_compute_forwarding_rule" "frontend" {
  for_each = var.forwarding_rules
  provider = google

  project               = var.project_id
  name                  = each.key
  region                = local.region
  description           = each.value.description
  network               = "projects/${local.network_project_id}/global/networks/${each.value.network}"
  subnetwork            = "projects/${local.network_project_id}/regions/${local.region}/subnetworks/${each.value.subnetwork}"
  ip_protocol           = google_compute_region_backend_service.backend.protocol
  load_balancing_scheme = "INTERNAL"
  ip_version            = each.value.ip_version != null ? each.value.ip_version : null
  ip_address            = google_compute_address.internal-address[each.key].address
  ports                 = each.value.ports
  all_ports             = each.value.all_ports
  allow_global_access   = each.value.global_access
  backend_service       = google_compute_region_backend_service.backend.id
  service_label         = each.value.service_label

  depends_on = [
    google_compute_address.internal-address,
  ]

  timeouts {}
}

// https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_address
resource "google_compute_address" "internal-address" {
  provider = google
  for_each = var.forwarding_rules

  project      = var.project_id
  name         = each.value.internal_ip_address_name != "" ? each.value.internal_ip_address_name : "${var.name}-lb-internal"
  description  = each.value.internal_ip_address_description
  region       = local.region
  address_type = "INTERNAL"
  address      = each.value.internal_ip_address
  subnetwork   = "projects/${local.network_project_id}/regions/${local.region}/subnetworks/${each.value.subnetwork}"

  timeouts {}
}