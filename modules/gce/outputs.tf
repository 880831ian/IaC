output "instance_id" {
  value = google_compute_instance.instance.instance_id
}

output "instance_name" {
  value = google_compute_instance.instance.name
}

output "ip_region" {
  value = google_compute_address.internal-address.region
}

output "internal_ip_address_name" {
  value = google_compute_address.internal-address.name
}

output "internal_ip_address" {
  value = google_compute_address.internal-address.address
}

output "external_ip_address_name" {
  value = length(google_compute_instance.instance.network_interface[0].access_config) > 0 ? google_compute_address.external-address[0].name : "未開啟外網"
}

output "external_ip_address" {
  value = length(google_compute_instance.instance.network_interface[0].access_config) > 0 ? google_compute_address.external-address[0].address : "未開啟外網"
}