output "name" {
  value = google_compute_address.address.name
}

output "region" {
  value = google_compute_address.address.region
}

output "type" {
  value = google_compute_address.address.address_type
}

output "ip_address" {
  value = google_compute_address.address.address
}
