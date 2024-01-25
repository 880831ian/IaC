# IaC 架構

```
.
├── .gitignore
├── .gitlab-ci.yml
├── README.md
├── docs
│   ├── iac-cicd-framework.md
│   ├── iac-fqa.md
│   ├── iac-framework.md
│   ├── iac-import-conversion-scripts.md
│   ├── iac-introduce.md
│   └── iac-remark.md
├── generate_job.sh
├── modules
│   ├── filestore
│   │   ├── locals.tf
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   ├── variables.tf
│   │   └── versions.tf
│   ├── gce
│   │   ├── locals.tf
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   ├── variables.tf
│   │   └── versions.tf
│   ├── gce-group
│   │   ├── locals.tf
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── versions.tf
│   ├── gcs
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   ├── variables.tf
│   │   └── versions.tf
│   ├── gke
│   │   ├── cluster.tf
│   │   ├── main.tf
│   │   ├── node_pool.tf
│   │   ├── outputs.tf
│   │   ├── variables.tf
│   │   ├── variables_defaults.tf
│   │   └── versions.tf
│   ├── ip
│   │   ├── locals.tf
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   └── memorystore
│       ├── locals.tf
│       ├── main.tf
│       ├── outputs.tf
│       ├── variables.tf
│       └── versions.tf
├── projects
│   ├── [專案名稱]
│   │   ├── filestore-XXX
│   │   ├── gce-XXX
│   │   ├── gce-group-XXX
│   │   ├── gcs-XXX
│   │   ├── gke-XXX
│   │   ├── memorystore-XXX
│   │   ├── ip-XXX
│   │   └── terragrunt.hcl
│   └── [專案名稱]
│       ├── gce-XXX
│       ├── gce-group-XXX
│       ├── gcs-XXX
│       ├── gke-XXX
│       ├── memorystore-XXX
│       ├── ip-XXX
│       └── terragrunt.hcl
├── scripts
│   ├── common.sh
│   ├── filestoe_transform.sh
│   ├── filestore-template
│   ├── gce-group-template
│   ├── gce-group_transform.sh
│   ├── gce-template
│   ├── gce_transform.sh
│   ├── gcs-template
│   ├── gcs_transform.sh
│   ├── gke_import.sh
│   ├── ip-template
│   ├── ip_transform.sh
│   ├── memorystore-template
│   └── memorystore_transform.sh
└── template
    ├── filestore
    │   └── terragrunt.hcl
    ├── gce
    │   └── terragrunt.hcl
    ├── gce-group
    │   └── terragrunt.hcl
    ├── gcs
    │   └── terragrunt.hcl
    ├── gke
    │   └── terragrunt.hcl
    ├── memorystore
    │   └── terragrunt.hcl
    └── terragrunt.hcl
```

<br>

`.gitignore` : 不要把 `*.terragrunt-cache/`、`.terraform.lock.hcl`、`.DS_Store` 檔案紀錄在版控

`.gitlab-ci.yml` : GitLab CICD 設定檔案，會使用到 generate_job.sh 來產生子 Job

`generate_job.sh`：GitLab CICD 動態產生子 Job 設定檔，詳細可以參考 [IaC CICD 架構](https://github.com/880831ian/IaC/blob/master/docs/iac-cicd-framework.md)

`docs/`：存放 IaC 相關文件

`modules/`：存放 resource 的 module 檔案，會依照 resource 名稱來區分，例如：gke、gce、gce-group、gcs、filestore、memorystore、ip

`projects/`：存放專案的資料夾，第一層依照 GCP 專案名稱命名 (請調整 scripts/common.sh)，第二層會依照 resource 來當作資料夾開頭，例如 gke-[cluster 名稱]、gce-[機器名稱]、filestore-[名稱]、memorystore-[名稱]，並放置共用的設定檔 terragrunt.hcl

`scripts/` ：存放匯入 tfstate 狀態檔的腳本，以及服務轉換的腳本 (沒有 gke，因為設定值太多)

`template/`：存放範例程式，會依照 resource 來做資料夾命名，裡面的設定檔案可以直接複製拿來當一開始建立資源的模板
