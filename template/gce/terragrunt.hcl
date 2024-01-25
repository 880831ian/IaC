terraform {
  source = "${get_path_to_repo_root()}/modules/gce" // 此設定不需更改，用來自動抓 modules/gce 的內容
}

include {
  path = find_in_parent_folders() // 此設定不需更改，用來抓取對應資料夾各層的設定檔案 (例如：template/terragrunt.hcl)
}

// 以下設定為範例，會列出適合本人使用的變數，請依照需求自行調整，沒有使用請刪除欄位以及空白行，維持程式整潔，後面會標示是否為必填，詳細參數說明可以參考 modules/gce/variables.tf 檔案
inputs = {
  name                  = "test"                         // GCE 名稱 (必填)
  zone                  = "asia-southeast1-b"            // GCE 區域 (必填)
  machine_type          = "n2-standard-4"                // GCE 機器規格 (必填)
  enable_display        = false                          // 是否啟用虛擬顯示，預設為關閉 (選填)
  boot_disk_auto_delete = true                           // 是否自動刪除開機磁碟，預設為開啟 (選填)
  boot_disk_device_name = "test"                         // GCE 設定名稱，預設與 name 相同 (選填)
  boot_disk_image       = "debian-11-bullseye-v20231212" // GCE 映像檔，預設為空 (選填)
  boot_disk_size        = 100                            // GCE 開機磁碟大小，預設為 10 (單位: GB) (選填)
  boot_disk_type        = "pd-standard"                  // GCE 開機磁碟類型，預設為 pd-balanced (選填)
  boot_disk_mode        = "READ_WRITE"                   // GCE 開機磁碟模式，預設為 READ_WRITE (選填)
  network               = "testdev"                      // GCE 網路名稱 (必填)
  subnetwork            = "sub-testdev"                  // GCE 子網路名稱 (必填)

  // GCE 保留 IP 設定，以下內網預設保留 (外網需開啟 nat_ip_enabled 才可保留)
  // 1. 第一次建立，可以輸入想要的名稱、描述，會自動保留，若留空則會自動產生
  // 2. 內、外網 IP 第一次建立時，可以不用輸入，但如果想要調整 IP 名稱，請記得一定要補上 IP address !!!
  // 3. 如果需要修改名稱或是 IP，請先參考 https://github.com/880831ian/IaC/blob/master/docs/iac-fqa.md
  internal_ip_address_name        = "test-1"          // 內網 IP 名稱，預設為 ${name}-internal (選填)
  internal_ip_address_description = "內網描述"            // 內網 IP 描述，預設為空 (選填)
  internal_ip_address             = "10.0.0.1"        // 內網 IP，預設為空 (選填)
  nat_ip_enabled                  = true              // 是否啟用外網 IP，預設為關閉 (選填)
  external_ip_address_name        = "test-2"          // 外網 IP 名稱，需要設定，請先開啟 nat_ip_enabled，預設為 ${name}-external (選填)
  external_ip_address_description = "外網描述"            // 外網 IP 描述，需要設定，請先開啟 nat_ip_enabled，預設為空 (選填)
  external_ip_address             = "123.123.123.123" // 外網 IP，需要設定，請先開啟 nat_ip_enabled，預設為空 (選填)
  external_network_tier           = "PREMIUM"         // 外網 IP 網路層級，需要設定，請先開啟 nat_ip_enabled，預設為 PREMIUM (選填)

  attached_disk_enabled     = false         // 是否啟用附加磁碟，預設為關閉 (選填)
  attached_disk_device_name = "attach_test" // GCE 附加磁碟名稱，預設為空 (選填)
  attached_disk_mode        = "READ_WRITE"  // GCE 附加磁碟模式，預設為 READ_WRITE (選填)
  attached_disk_source      = ""            // GCE 附加磁碟來源，預設為空 (選填)
  labels = {                                // GCE 標籤，預設為空 (選填)
    "env" : "prod",
  }
  network_tags = [ // GCE 網路標記，預設為空 (選填)
    "vpc-allow-ssh"
  ]
  metadata                = {}                                            // GCE 中繼資料，預設為空 (選填)
  resource_policies       = []                                            // 附加到機器的資源策略的 self_links 清單，預設為空 (選填)                                             // GCE 資源原則，預設為空 (選填)
  service_account_enabled = true                                          // 是否啟用服務帳戶，預設為開啟 (選填)
  service_account_email   = "XXXXX-compute@developer.gserviceaccount.com" // GCE 服務帳戶電子郵件，預設為空 (選填)
  service_account_scopes = [                                              // GCE 服務帳戶範圍，預設請參考 variables.tf (選填)
    "https://www.googleapis.com/auth/devstorage.read_only",
    "https://www.googleapis.com/auth/logging.write",
    "https://www.googleapis.com/auth/monitoring.write",
    "https://www.googleapis.com/auth/pubsub",
    "https://www.googleapis.com/auth/service.management.readonly",
    "https://www.googleapis.com/auth/servicecontrol",
    "https://www.googleapis.com/auth/trace.append"
  ]
  deletion_protection       = false // 是否啟用刪除保護，預設為關閉 (選填)
  allow_stopping_for_update = true  // 是否允許自動停止後更新，預設為關閉 (選填)
}
