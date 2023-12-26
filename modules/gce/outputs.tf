output "instance_id" {
  value = google_compute_instance.instance.instance_id
}

output "instance_name" {
  value = google_compute_instance.instance.name
}

output "instance_ip_address" {
  value = length(google_compute_instance.instance.network_interface[0].access_config) > 0 ? google_compute_instance.instance.network_interface[0].access_config[0].nat_ip : "網路 access_config 未設定"
}