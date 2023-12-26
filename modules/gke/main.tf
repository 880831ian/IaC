locals {
  // 專案 ID
  cluster_id = google_container_cluster.primary.id

  // 判斷 regional 是否是 true，如果是 location 就使用 region 的值，否則就使用 zones 的第一個值
  location = var.regional ? var.region : var.zones[0]
  // 判斷 regional 是否是 true，如果是 region 就使用 region 的值，否則就使用 zones 的第一個值，會將 - 之後的值給移除
  region = var.regional ? var.region : join("-", slice(split("-", var.zones[0]), 0, 2))

  node_locations = var.regional ? coalescelist(compact(var.zones), try(sort(random_shuffle.available_zones[0].result), [])) : slice(var.zones, 1, length(var.zones))
  // 版本
  master_version_regional = var.kubernetes_version != "latest" ? var.kubernetes_version : data.google_container_engine_versions.region.latest_master_version
  master_version_zonal    = var.kubernetes_version != "latest" ? var.kubernetes_version : data.google_container_engine_versions.zone.latest_master_version
  master_version          = var.regional ? local.master_version_regional : local.master_version_zonal
  // Node Pool 名稱
  node_pool_names = [for np in toset(var.node_pools) : np.name]
  // Node Pool 相關設定
  node_pools = zipmap(local.node_pool_names, tolist(toset(var.node_pools)))
  // 更新頻道
  release_channel = var.release_channel != null ? [{ channel : var.release_channel }] : []
  // 判斷 network vpc 是否放在其他專案，如果是就使用 network_project_id，否則就使用 project_id
  network_project_id = var.network_project_id != "" ? var.network_project_id : var.project_id
  // 區域數量
  zone_count = length(var.zones)
  // 判斷 cluster 使用的區域是不是 regional，如果是就顯示 regional zonal
  cluster_type = var.regional ? "regional" : "zonal"
  // 如果是 release_channel 不是 UNSPECIFIED 就設定為 true，否則就設定為 false
  default_auto_upgrade = var.release_channel != "UNSPECIFIED" ? true : false

  // 判斷 gcs_fuse_csi_driver 是否啟用，如果是就設定 enabled 為 true，否則就設定為空陣列
  gcs_fuse_csi_driver_config = var.gcs_fuse_csi_driver ? [{ enabled = true }] : []

  cluster_output_regional_zones = google_container_cluster.primary.node_locations
  cluster_output_zones          = local.cluster_output_regional_zones
  cluster_zones                 = sort(local.cluster_output_zones)

  cluster_output_master_version     = google_container_cluster.primary.master_version
  cluster_output_min_master_version = google_container_cluster.primary.min_master_version

  master_authorized_networks_config = length(var.master_authorized_networks) == 0 ? [] : [{
    cidr_blocks : var.master_authorized_networks
  }]

  cluster_output_node_pools_names = concat(
    [for np in google_container_node_pool.pools : np.name],
  )

  cluster_output_node_pools_versions = merge(
    { for np in google_container_node_pool.pools : np.name => np.version },
  )

  cluster_location                 = google_container_cluster.primary.location
  cluster_region                   = var.regional ? var.region : join("-", slice(split("-", local.cluster_location), 0, 2))
  cluster_master_version           = local.cluster_output_master_version
  cluster_min_master_version       = local.cluster_output_min_master_version
  cluster_node_pools_names         = local.cluster_output_node_pools_names
  cluster_node_pools_versions      = local.cluster_output_node_pools_versions
  cluster_workload_identity_config = var.enable_workload_identity ? "${var.project_id}.svc.id.goog" : ""

  // 判斷 release_channel 是否不是 UNSPECIFIED，如果是就看 enable_maintenance 設定，否則就設定為 false  
  enable_maintenance                      = var.release_channel != "UNSPECIFIED" ? var.enable_maintenance : false
  cluster_maintenance_window_is_recurring = var.maintenance_start_time != "" && var.maintenance_recurrence != "" && var.maintenance_end_time != "" ? [1] : []
}

/******************************************
  Get available container engine versions
 *****************************************/
data "google_container_engine_versions" "region" {
  location = local.location
  project  = var.project_id
}

data "google_container_engine_versions" "zone" {
  location = local.zone_count == 0 ? data.google_compute_zones.available[0].names[0] : var.zones[0]
  project  = var.project_id
}

/******************************************
  Get available zones in region
 *****************************************/
data "google_compute_zones" "available" {
  count = local.zone_count == 0 ? 1 : 0

  provider = google

  project = var.project_id
  region  = local.region
}

resource "random_shuffle" "available_zones" {
  count = local.zone_count == 0 ? 1 : 0

  input        = data.google_compute_zones.available[0].names
  result_count = 3
}