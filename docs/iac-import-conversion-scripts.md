# IaC 匯入、轉換腳本介紹

在 scripts 資料夾底下，會看到一些腳本，如下圖：

```
.
├── common.sh
├── filestoe_transform.sh
├── filestore-template
├── gce-template
├── gce_transform.sh
├── gcs-template
├── gcs_transform.sh
├── gke_import.sh
├── memorystore-template
└── memorystore_transform.sh
```

<br>

`common.sh` : 選擇要調整的專案的共用腳本，裡面有每個專案的名稱及 ID 變數設定 (請先調整參數，都改成自己的設定)

`gke_import.sh`：此為 gke 匯入 tfstate 的腳本，會自動將線上的狀態拉到 backend.tf 所設定的地方存放，要執行此腳本，請先閱讀 [什麼是 IaC ? Terraform 介紹 # terraform import](https://blog.pin-yi.me/terraform/#terraform-import)

`gce_transform.sh` : 此為 gce 自動轉換腳本，可以選擇專案，會自動將該專案底下的 gce 套用到 `gce-template`，並產生對應的 terragrunt.hcl 檔案

`filestoe_transform.sh` : 此為 filestore 自動轉換腳本，可以選擇專案，會自動將該專案底下的 filestore 套用到 `filestore-template`，並產生對應的 terragrunt.hcl 檔案

`memorystore_transform.sh` : 此為 memorystore 自動轉換腳本，可以選擇專案，會自動將該專案底下的 memorystore 套用到 `memorystore-template`，並產生對應的 terragrunt.hcl 檔案

`gcs_transform.sh` : 此為 gcs 自動轉換腳本，可以選擇專案，會自動將該專案底下的 gcs 套用到 `gcs-template`，並產生對應的 terragrunt.hcl 檔案
