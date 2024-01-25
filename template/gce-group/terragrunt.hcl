terraform {
  source = "${get_path_to_repo_root()}/modules/gce-group" // 此設定不需更改，用來自動抓 modules/gce-group 的內容
}

include {
  path = find_in_parent_folders() // 此設定不需更改，用來抓取對應資料夾各層的設定檔案 (例如：template/terragrunt.hcl)
}

// 以下設定為範例，會列出適合本人使用的變數，請依照需求自行調整，沒有使用請刪除欄位以及空白行，維持程式整潔，後面會標示是否為必填，詳細參數說明可以參考 modules/gce-group/variables.tf 檔案
inputs = {
  name        = "test-group"        // GCE_GROUP 名稱 (必填)
  description = "test-group"        // GCE_GROUP 描述 (選填)
  zone        = "asia-southeast1-b" // GCE_GROUP 區域 (必填)
  instances = [                     // GCE_GROUP 使用機器名稱
    "redis",
    "redis-prod"
  ]
  named_ports = [ // GCE_GROUP 連接埠映射 (選填)
    {
      "name" : "redis-6379",
      "port" : 6379
    },
    {
      "name" : "redis-6378",
      "port" : 6378
    }
  ]
  network_project_id = "XXX"     // 共享 VPC 專案的 ID，如果沒有設定，預設為專案 ID (選填)
  network            = "XXX-vpc" // GCE_GROUP 網路名稱 (必填)
}
