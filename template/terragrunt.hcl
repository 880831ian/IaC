remote_state {
  backend = "gcs" // 使用 GCS 作為 remote backend
  generate = {
    path      = "backend.tf" // 產生 backend.tf
    if_exists = "overwrite" // 如果 backend.tf 已存在，則覆蓋
  }
  config = {
    bucket = "GCS 名稱" // GCS bucket 名稱
    prefix = "專案ID/${path_relative_to_include()}" // GCS bucket 路徑
  }
}

inputs = { // 可以設定一些共用變數，例如 project_id, network_project_id 等
  project_id         = "gcp-XXX-XXX"  // 專案 ID
  network_project_id = "gcp-XXX-XXX" // 網路專案 ID，用來設定 VPC 網路
}
