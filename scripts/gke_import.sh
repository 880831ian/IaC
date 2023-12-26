#! /bin/bash
source ./common.sh

gcloud container clusters list --project ${project_id} --format="table(NAME,LOCATION)"

echo -e "\n"

read -r -e -p "以上為本次要匯入的 GKE Cluster 線上資源，請確認是否繼續進行？(Y/N)：" continue
case $continue in
Y | y) ;;
N | n)
    exit
    ;;
*)
    echo -e "\n${RED}無效參數 ($REPLY)，請重新輸入${WHITE}\n"
    exit
    ;;
esac

gke_output=$(gcloud container clusters list --project ${project_id} --format="value(NAME,LOCATION)")
IFS=$'\n' read -rd '' -a gke_array <<<"$gke_output"

for gke_data in "${gke_array[@]}"; do
    name=$(echo $gke_data | cut -d " " -f 1)
    location=$(echo $gke_data | cut -d " " -f 2)

    mkdir -p ../projects/${project_name}/gke-${name}
    echo -e "#! /bin/bash\n\nterragrunt import google_container_cluster.primary ${project_id}/${location}/${name}" >../projects/${project_name}/gke-${name}/import.sh

    node_pool_output=$(gcloud container node-pools list --cluster=$name --location=$location --project ${project_id} --format="value(NAME,LOCATION)" --sort-by="NAME")
    IFS=$'\n' read -rd '' -a node_pool_array <<<"$node_pool_output"

    for node_pool_data in "${node_pool_array[@]}"; do
        node_pool_name=$(echo $node_pool_data | cut -d " " -f 1)
        echo "terragrunt import 'google_container_node_pool.pools[\"${node_pool_name}\"]' ${project_id}/${location}/${name}/${node_pool_name}" >>../projects/${project_name}/gke-${name}/import.sh
    done
    chmod a+x ../projects/${project_name}/gke-${name}/import.sh

    echo -e "\n${BLUE}匯入 GKE Cluster 線上資源：${GREEN}${name}${WHITE}"
done
