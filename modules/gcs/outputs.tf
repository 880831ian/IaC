output "name" {
  description = "Bucket 名稱"
  value       = google_storage_bucket.bucket.name
}

output "location" {
  description = "Bucket 所在地點，可以選 Multi-region、Dual-region、Region，如果選擇 Dual-region 需填寫 custom_placement_config"
  value       = google_storage_bucket.bucket.location
}

output "storage_class" {
  description = "Bucket 資料儲存類別"
  value       = google_storage_bucket.bucket.storage_class
}
