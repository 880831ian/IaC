#! /bin/bash
source ./common.sh

output=$(gcloud compute instance-groups unmanaged list --project ${project_id} --filter="NOT name ~ ^k8s AND NOT name ~ mig AND NOT name ~ template" --format="table(NAME,ZONE)" --sort-by="NAME")

if [ -z "$output" ]; then
    echo -e "${RED}該專案無此資源 (GCE-GROUP) ，請重新選擇專案${WHITE}\n"
    exit
else
    echo "$output"
fi

echo -e "\n"

read -r -e -p "以上為本次要匯入的 GCE-GROUP Instances 線上資源，請確認是否繼續進行？(Y/N)：" continue
case $continue in
Y | y)
    echo -e "\n${GREEN}開始轉換 GCE-GROUP Instances 線上資源 ... (請稍等) ◟(ꉺᴗꉺ๑)◝ ... ${WHITE}\n"
    url="https://console.cloud.google.com/compute/instanceGroups/list?project=${project_id}"
    echo -e "可以先按住 Command 鍵開啟 GCE-GROUP Instances 資源連結，檢查服務是否轉換正常 👉 \033]8;;${url}\a點我開啟瀏覽器\033]8;;\a\n"
    ;;
N | n)
    exit
    ;;
*)
    echo -e "\n${RED}無效參數 ($REPLY)，請重新輸入${WHITE}\n"
    exit
    ;;
esac

gce_group_output=$(gcloud compute instance-groups unmanaged list --project ${project_id} --filter="NOT name ~ ^k8s AND NOT name ~ mig AND NOT name ~ template" --format="csv(NAME,ZONE)" --sort-by="NAME")
gce_group_output=$(echo "$gce_group_output" | sed '1d') # 移除標題列
IFS=$'\n' read -rd '' -a gce_group_array <<<"$gce_group_output"

function process_instance_group() {
    local gce_group_data=$1
    local project_id=$2
    local project_name=$3

    export name=$(echo $gce_group_data | cut -d "," -f 1)
    export zone=$(echo $gce_group_data | cut -d "," -f 2)

    echo -e "\n\033[1;32m====================================================================================================\033[0m"
    echo -e "\n\033[1;34m匯入 GCE-GROUP Instances 線上資源：\033[1;32m${name}\033[0m\n"

    mkdir -p ../projects/${project_name}/gce-group-${name}
    cd ../projects/${project_name}/gce-group-${name}

    echo "resource \"google_compute_instance_group\" \"group\" {}" >main.tf

    until
        export TF_PLUGIN_TIMEOUT=4h
        terraform init 1>/dev/null
    do
        echo -e "\n\033[1;33mterraform init 失敗，Delay 3 秒後重試 ....\033[0m"
        sleep 3
    done

    until terraform import google_compute_instance_group.group $project_id/$zone/$name 1>/dev/null; do
        echo -e "\n\033[1;33mterraform import google_compute_instance_group.group 失敗，Delay 3 秒後重試 ....\033[0m"
        sleep 3
    done

    export description=$(cat terraform.tfstate | jq -r '.resources[].instances[].attributes.description')
    if [ "$description" == "" ]; then # 與預設值相同，則不顯示
        export description="default_setting"
    fi

    export instances=$(cat terraform.tfstate | jq -r '.resources[].instances[].attributes.instances | map(sub(".*\/"; ""))')
    if [ "$instances" == "[]" ]; then # 與預設值相同，則不顯示
        export instances="default_setting"
    fi

    export named_ports=$(cat terraform.tfstate | jq -r '.resources[].instances[].attributes.named_port')
    if [ "$named_ports" == [] ]; then # 與預設值相同，則不顯示
        export named_ports="default_setting"
    fi

    export network_project_id=$(cat terraform.tfstate | jq -r '.resources[].instances[].attributes.network' | sed -n 's/.*projects\/\([^\/]*\).*/\1/p')
    if [ "$network_project_id" != "$project_id" ]; then # 與預設值相同，則不顯示
        export network_project_id="default_setting"
    fi

    export network=$(cat terraform.tfstate | jq -r '.resources[].instances[].attributes.network' | sed 's/.*networks\/\([^\/]*\).*/\1/')

    rm -rf *.tf .terraform*
    envsubst <../../../scripts/gce-group-template >terragrunt.hcl

    # 移除與預設值相同的參數
    awk '!/default_setting/' terragrunt.hcl >temp_file && mv temp_file terragrunt.hcl

    until echo "yes" | terragrunt plan; do
        echo -e "\n\033[1;33mterragrunt plan 失敗，Delay 3 秒後重試 ....\033[0m"
        sleep 3
    done

    rm -rf terraform.tfstate terraform.tfstate.backup .terraform* .terragrunt-cache

    terragrunt hclfmt

    cd ../../../scripts
}

export -f process_instance_group
instance_group_params=$(printf "%s\n" "${gce_group_array[@]}")
echo "$instance_group_params" | parallel --no-notice --jobs ${JOB_COUNT} process_instance_group {} ${project_id} ${project_name}
