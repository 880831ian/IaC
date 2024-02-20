output "backend_name" {
  value = google_compute_region_backend_service.backend.name
}

output "backend_service_backends" {
  value = [for b in google_compute_region_backend_service.backend.backend : regex("instanceGroups/(.+)$", b.group)[0]]
}

output "health_check" {
  value = [
    for hc_type, hc in {
      "tcp"   = length(google_compute_health_check.tcp) > 0 ? google_compute_health_check.tcp : google_compute_region_health_check.tcp,
      "http"  = length(google_compute_health_check.http) > 0 ? google_compute_health_check.http : google_compute_region_health_check.http,
      "https" = length(google_compute_health_check.https) > 0 ? google_compute_health_check.https : google_compute_region_health_check.https
      } : {
      type                = hc_type
      name                = hc[0].name
      port                = hc[0].type == "TCP" ? hc[0].tcp_health_check[0].port : hc[0].type == "HTTP" ? hc[0].http_health_check[0].port : hc[0].https_health_check[0].port
      proxy_header        = hc[0].type == "TCP" ? hc[0].tcp_health_check[0].proxy_header : hc[0].type == "HTTP" ? hc[0].http_health_check[0].proxy_header : hc[0].https_health_check[0].proxy_header
      request             = hc[0].type == "TCP" ? hc[0].tcp_health_check[0].request : hc[0].type == "HTTP" ? hc[0].http_health_check[0].request : hc[0].https_health_check[0].request
      response            = hc[0].type == "TCP" ? hc[0].tcp_health_check[0].response : hc[0].type == "HTTP" ? hc[0].http_health_check[0].response : hc[0].https_health_check[0].response
      request_path        = hc[0].type == "TCP" ? "" : hc[0].type == "HTTP" ? hc[0].http_health_check[0].request_path : hc[0].https_health_check[0].request_path
      host                = hc[0].type == "TCP" ? "" : hc[0].type == "HTTP" ? hc[0].http_health_check[0].host : hc[0].https_health_check[0].host
      enable_log          = hc[0].log_config[0].enable
      check_interval_sec  = hc[0].check_interval_sec
      timeout_sec         = hc[0].timeout_sec
      healthy_threshold   = hc[0].healthy_threshold
      unhealthy_threshold = hc[0].unhealthy_threshold
    }
    if length(hc) > 0
  ]
}


output "forwarding_rules" {
  value = {
    for rule_key, rule_value in google_compute_forwarding_rule.frontend : rule_key => {
      name       = rule_value.name
      ip_name    = google_compute_address.internal-address[rule_key].name
      ip_address = google_compute_address.internal-address[rule_key].address
      ports      = rule_value.ports
      all_ports  = rule_value.all_ports
    }
  }
}