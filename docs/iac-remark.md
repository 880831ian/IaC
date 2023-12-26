# IaC 備注

1. GitLab CICD 會使用到 artifacts，有些 cluster 產生的 cache 較大，所以需要調整 gitlab artifacts 的大小，將 Maximum artifacts size (MB) 從 100 調整成 500 (此設定只能由 admin 權限調整)。
