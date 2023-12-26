output "cluster_id" {
  description = "叢集所在的專案 ID"
  value       = local.cluster_id
}

output "cluster_name" {
  description = "叢集名稱"
  value       = google_container_cluster.primary.name
  depends_on = [
    google_container_cluster.primary,
    google_container_node_pool.pools,
  ]
}

output "cluster_type" {
  description = "叢集類型 (regional / zonal)"
  value       = local.cluster_type
}

output "location" {
  description = "叢集位置 (region if regional cluster, zone if zonal cluster)"
  value       = local.cluster_location
}

output "region" {
  description = "叢集地區性"
  value       = local.cluster_region
}

output "zones" {
  description = "叢集區域"
  value       = local.cluster_zones
}

output "release_channel" {
  description = "GKE 發布頻道"
  value       = var.release_channel
}

output "min_master_version" {
  description = "最小 master kubernetes 版本"
  value       = local.cluster_min_master_version
}

output "master_version" {
  description = "現在 master kubernetes 版本"
  value       = local.cluster_master_version
}

output "master_ipv4_cidr_block" {
  description = "GKE 控制層 IP 範圍"
  value       = var.master_ipv4_cidr_block
}

output "master_authorized_networks_config" {
  description = "授權的主網路清單"
  value       = google_container_cluster.primary.master_authorized_networks_config
}

output "node_pools_names" {
  description = "Node Pool 名稱"
  value       = local.cluster_node_pools_names
}

output "node_pools_versions" {
  description = "Node Pool 名稱與版本"
  value       = local.cluster_node_pools_versions
}

output "service_account" {
  description = "每個節點使用的服務帳戶"
  value       = var.service_account
}

output "workload_identity" {
  description = "Workload Identity pool"
  value       = local.cluster_workload_identity_config
  depends_on = [
    google_container_cluster.primary
  ]
}