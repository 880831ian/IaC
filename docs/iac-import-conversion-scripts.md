# IaC 匯入、轉換腳本介紹

在 scripts 資料夾底下，會看到一些腳本，如下圖：

```
.
├── common.sh
├── filestore-template
├── filestore_transform.sh
├── gce-group-template
├── gce-group_transform.sh
├── gce-template
├── gce_transform.sh
├── gcs-template
├── gcs_transform.sh
├── gke_import.sh
├── ip-template
├── ip_transform.sh
├── lb-internal-template
├── lb-internal_transform.sh
├── memorystore-template
└── memorystore_transform.sh
```

<br>

目前腳本大多使用多線程方式進行轉換，線程預設為 20 (代表會一次跑 20 個 import)，可以依照電腦性能以及網路速度調整 common.sh 腳本內的 JOB_COUNT 參數設定，另外使用多線程需安裝 parallel，如沒有安裝會跳出安裝請求，由於每次都會檢查是否安裝 parallel，如想跳過檢查步驟直接執行腳本，請在後面帶入 keep 參數，例如： ./gce_transform.sh keep 就可以跳過檢查流程。

<br>

## 使用注意事項：

1. 如果遇到資源轉換卡住，可以先檢查 GCS 存放 tfstate 檔案是否有 lock 沒有刪除，可以刪除後再重試

<br>

## 檔案說明：

`common.sh` : 選擇要調整的專案的共用腳本，裡面有每個專案的名稱及 ID 變數設定 (請先調整參數，都改成自己的設定)

`filestoe_transform.sh` : 此為 filestore 自動轉換腳本，可以選擇專案，會自動將該專案底下的 filestore 套用到 filestore-template，並產生對應的 terragrunt.hcl 檔案

`gce-group_transform.sh` : 此為 gce-group 自動轉換腳本，可以選擇專案，會自動將該專案底下的 gce-group 套用到 gce-group-template，並產生對應的 terragrunt.hcl 檔案

`gce_transform.sh` : 此為 gce 自動轉換腳本，可以選擇專案，會自動將該專案底下的 gce 套用到 gce-template，並產生對應的 terragrunt.hcl 檔案

`gcs_transform.sh` : 此為 gcs 自動轉換腳本，可以選擇專案，會自動將該專案底下的 gcs 套用到 gcs-template，並產生對應的 terragrunt.hcl 檔案

`gke_import.sh`：此為 gke 匯入 tfstate 的腳本，會自動將線上的狀態拉到 pid-terraform-state 中存放，要執行此腳本，請先閱讀 [什麼是 IaC ? Terraform 介紹 # terraform import](https://blog.pin-yi.me/terraform/#terraform-import)

`ip_transform.sh` : 此為 ip 自動轉換腳本，可以選擇專案，會自動將該專案底下的 ip 套用到 ip-template，並產生對應的 terragrunt.hcl 檔案

`lb-internal_transform.sh` : 此為 lb-internal 自動轉換腳本，可以選擇專案，會自動將該專案底下的 lb-internal 套用到 lb-internal-template，並產生對應的 terragrunt.hcl 檔案

`memorystore_transform.sh` : 此為 memorystore 自動轉換腳本，可以選擇專案，會自動將該專案底下的 memorystore 套用到 memorystore-template，並產生對應的 terragrunt.hcl 檔案
