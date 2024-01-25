terraform {
  source = "${get_path_to_repo_root()}/modules/filestore" // 此設定不需更改，用來自動抓 modules/filestore 的內容
}

include {
  path = find_in_parent_folders() // 此設定不需更改，用來抓取對應資料夾各層的設定檔案 (例如：template/terragrunt.hcl)
}

// 以下設定為範例，會列出適合本人使用的變數，請依照需求自行調整，沒有使用請刪除欄位以及空白行，維持程式整潔，後面會標示是否為必填，詳細參數說明可以參考 modules/filestore/variables.tf 檔案
inputs = {
  name                     = "storage"      // Filestore 名稱 (必填)
  location                 = "asia-east1-b" // Filestore 儲存位置，如果 tier 是 ENTERPRISE 則 location 不能填寫單區域，Ex: asia-east1-b  (必填)
  description              = "測試"          // Filestore 描述 (選填)
  tier                     = "BASIC_HDD"    // Filestore 個體類型 (必填)
  file_shares_name         = "share"        // Filestore 檔案共用區名稱 (必填)
  file_shares_capacity_tib = 1              // Filestore 分配容量，預設為 1，除 BASIC_SSD 是 2.5 (單位: TiB) (必填)"
  network                  = "testdev"      // Filestore 網路名稱 (必填)
  labels = {                                // Filestore 標籤，預設為空 (選填)
    "env" = "test"
  }
}
