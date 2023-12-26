output "filestore_name" {
  value = google_filestore_instance.instance.name
}

output "filestore_ip_address" {
  value = length(google_filestore_instance.instance.networks[0].ip_addresses[0]) > 0 ? google_filestore_instance.instance.networks[0].ip_addresses[0] : "網路未設定"
}

output "filestore_tier" {
  value = google_filestore_instance.instance.tier
}

output "file_shares_name" {
  value = google_filestore_instance.instance.file_shares[0].name
}

output "file_shares_capacity_tib" {
  value = google_filestore_instance.instance.file_shares[0].capacity_gb / 1024
}