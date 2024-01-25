# IaC 備注

1. GitLab CICD 會使用到 artifacts，有些 cluster 產生的 cache 較大，所以需要調整 gitlab artifacts 的大小，將 Maximum artifacts size (MB) 從 100 調整成 500 (此設定只能由 admin 權限調整)。

2. 由於目前 CICD 除非是有異動到唯一性或不可更改的，例如機器名稱等，才會出現 Destroy，但當我們想要刪除資源時，目前做法是，先手動再本地需移除資源的資料夾下，下 `terragrunt destroy` ，當移除後，再將資料夾刪除，並推版控，來記錄異動，此時 pipeline 噴錯是正常的。

3. 呈第二點，如果像是 GCE 裡面含有多個資源的 (有 `google_compute_instance.instance`、`google_compute_address.internal-address`、` google_compute_address.external-address`)，可以選擇要單除刪除哪個資源，例如我們想保留內外網 IP，可以下 `terragrunt destroy --target="google_compute_instance.instance"` 來移除 VM instance。
