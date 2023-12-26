terraform {
  source = "${get_path_to_repo_root()}/modules/gke" // 此設定不需更改，用來自動抓 modules/gke 的內容
}

include {
  path = find_in_parent_folders() // 此設定不需更改，用來抓取對應資料夾各層的設定檔案 (例如：template/terragrunt.hcl)
}

// 以下設定為範例，會列出適合本人使用的變數，請依照需求自行調整，沒有使用請刪除欄位以及空白行，維持程式整潔，後面會標示是否為必填，詳細參數說明可以參考 modules/gke/variables.tf 檔案
inputs = {
  name = "test" // 叢集名稱 (必填)

  // 以下為 GKE 區域設定
  // 如果是多區域 region，則需設定 regional = true，並且設定 region，還可以指定 zone，若不指定 zone，則會自動選擇該區域可用的三個 zone
  // 如果是單區域 zone，則需設定 regional = false，並且設定 zone
  regional = true             // 是否為 Regional GKE，預設為 false (為 Zonal GKE)，如果是 true，需填寫 region 來指定區域 (選填)
  region   = "asia-east1"     // 多區域叢集，如果是 Regional GKE，則必填
  zones    = ["asia-east1-b"] // 單區域叢集，如果是 Zonal GKE，則必填，如果是 Regional GKE，想要指定 zone，也可以在這邊設定 (選填)

  release_channel           = "UNSPECIFIED"     // GKE 發布頻道，預設為 STABLE (選填)
  kubernetes_version        = "1.26.6-gke.1700" // GKE 版本，預設為 latest，如果是 latest，會自動抓該區域的最新版本，也可以自行輸入想要的版本 (選填)
  master_ipv4_cidr_block    = "172.16.0.1/28"   // 使用的主網路 IP 範圍，由 SR 提供 (必填)
  network                   = "bbin-test"       // 使用的 VPC 網路名稱，由 SR 提供 (必填)
  subnetwork                = "bbin-test-ian"   // 使用的 VPC 子網路名稱，由 SR 提供 (必填)
  default_max_pods_per_node = 32                // 每個節點的最大pod數量，預設為 64 (選填)

  // 以下為維護時間設定(可以理解成能更新 GKE 跟 Node Pool 版本的時間)，如果不希望自動更新，則需設定 enable_maintenance = false
  enable_maintenance     = false                     // 是否啟用維護，預設為 true，需設定以下維護時間 (選填) 
  maintenance_start_time = "2023-01-01T02:00:00Z"    // 維護開始時間，預設為 22:00 (UTC+8) (選填) 
  maintenance_end_time   = "2023-01-01T09:00:00Z"    // 維護結束時間，預設為 05:00 (UTC+8) (選填) 
  maintenance_recurrence = "FREQ=WEEKLY;BYDAY=TU,TH" // 維護週期，預設為每天 (選填) 

  master_authorized_networks = [ // 授權的主網路清單
    {
      cidr_block   = "0.0.0.0/0"
      display_name = "Google Cloud Build"
    }
  ]
  cluster_dns_provider = "CLOUD_DNS"     // 叢集預設 DNS 提供者，預設為 PROVIDER_UNSPECIFIED (選填)
  cluster_dns_scope    = "CLUSTER_SCOPE" // 叢集 DNS 記錄的存取範圍，預設為 DNS_SCOPE_UNSPECIFIED (選填)
  cluster_resource_labels = {            // 叢集 GCE 的資源標籤，使用 Key Value 的方式，預設為空 (選填)
    dept    = "pid"
    env     = "prod"
    product = "bbin"
  }
  monitoring_enabled_components        = ["SYSTEM_COMPONENTS"] // GKE 指標元件，預設為 ["SYSTEM_COMPONENTS"] (選填)
  monitoring_enable_managed_prometheus = true                  // 是否啟用 GMP (Google Managed Prometheus) 監控，預設為 false (選填)
  remove_default_node_pool             = true                  // 是否移除預設的 Node Pool，只有在首次建立 GKE 有用，預設為 false (選填)

  // 以下為 Node Pool 設定，這邊沒有寫在變數檔案，請直接參考 modules/gke/node_pool.tf 檔案
  node_pools = [
    {
      name              = "ian"            // Node Pool 名稱 (必填)
      machine_type      = "n2d-standard-8" // 機器類型，預設為 e2-medium (必填)
      disk_size_gb      = 40               // disk 大小，預設為 100 GB (選填)
      disk_type         = "pd-standard"    // disk 類型，預設為 pd-balanced (選填) 
      service_account   = "bbin-test"      // 服務帳戶，預設為 default (選填)
      spot              = false            // 是否使用 spot instance，預設為 false (選填)
      max_pods_per_node = 32               // 每個節點的最大pod數量，預設為 64 (選填)
      max_surge         = 3                // 更新時最大的擴展數量，預設為 1 (選填)

      // 以下為 node 數量設定 (包含 autoscaling)，如果不需要可以不用設定
      // 如果不想啟用 autoscaling，則需設定 autoscaling = false，(autoscaling 預設為 true) ，並指定 node_count 數量
      autoscaling = false
      node_count  = 7

      // 如果想啟用 autoscaling，只需要設定 min_count、max_count、total_min_count、total_max_count 任意一個即可
      min_count       = 1  // NodePool 中每個區域的最小節點數，預設為 1 (選填)
      max_count       = 5  // NodePool 中每個區域的最小節點數，預設為 5 (選填)
      total_min_count = 5  // NodePool 中節點的最小總數，預設為 1 (選填)
      total_max_count = 16 // NodePool 中節點的最小總數，預設為 1 (選填)      
    }
  ]

  // 以下為 Node Pool (label、metadata、taint、tag) 設定，如果不需要可以不用設定
  node_pools_labels = {
    // 如果希望所有 Node Pool 都吃到相同的 labels，可以使用下方 all 來設定
    all = {
      "label key" = "label value"
    }

    // 如果希望有特例的 Node Pool，可以參考下方來設定
    ian = { // 輸入要使用的 Node Pool 名稱
      "label key" = "label value"
    }
  }

  node_pools_metadata = {
    // 如果希望所有 Node Pool 都吃到相同的 metadata，可以使用下方 all 來設定
    all = {
      "disable-legacy-endpoints" = "true"
    }

    // 如果希望有特例的 Node Pool，可以參考下方來設定
    ian = { // 輸入要使用的 Node Pool 名稱
      "disable-legacy-endpoints" = "true"
    }
  }

  node_pools_taints = {
    // 如果希望所有 Node Pool 都吃到相同的 taint，可以使用下方 all 來設定
    all = [
      {
        key    = "node-type"
        value  = "default"
        effect = "NO_SCHEDULE"
      }
    ]

    // 如果希望有特例的 Node Pool，可以參考下方來設定
    default-api-pool = [ // 輸入要使用的 Node Pool 名稱
      {
        key    = "node-type"
        value  = "default"
        effect = "NO_SCHEDULE"
      }
    ]
  }

  node_pools_tags = {
    // 如果希望所有 Node Pool 都吃到相同的 tag，可以使用下方 all 來設定
    all = ["prometheus"]

    // 如果希望有特例的 Node Pool，可以參考下方來設定
    ian = ["test"] // 輸入要使用的 Node Pool 名稱
  }
}
