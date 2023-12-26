output "name" {
  description = "Memorystore 名稱"
  value       = google_redis_instance.instance.name
}

output "host" {
  description = "Memorystore IP 位址"
  value       = google_redis_instance.instance.host
}

output "read_endpoint" {
  description = "Memorystore 讀取 IP 位址"
  value       = google_redis_instance.instance.read_endpoint
}

output "region" {
  description = "Memorystore 所在區域"
  value       = google_redis_instance.instance.region
}

output "current_location_id" {
  description = "Memorystore 目前所在區域 ID"
  value       = google_redis_instance.instance.current_location_id
}

output "auth_string" {
  description = "Memorystore 密碼"
  value       = nonsensitive(google_redis_instance.instance.auth_string)
}
