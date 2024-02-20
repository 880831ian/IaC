#! /bin/bash
source ./common.sh

output=$(gcloud filestore instances list --project ${project_id} --format="table(INSTANCE_NAME,LOCATION)" --sort-by="INSTANCE_NAME")

if [ -z "$output" ]; then
    echo -e "${RED}該專案無此資源 (Filestore) ，請重新選擇專案${WHITE}\n"
    exit
else
    echo "$output"
fi

echo -e "\n"

read -r -e -p "以上為本次要匯入的 Filestore Instances 線上資源，請確認是否繼續進行？(Y/N)：" continue
case $continue in
Y | y)
    echo -e "\n${GREEN}開始轉換 Filestore Instances 線上資源 ... (請稍等) ◟(ꉺᴗꉺ๑)◝ ... ${WHITE}\n"
    url="https://console.cloud.google.com/filestore/instances?project=${project_id}"
    echo -e "可以先按住 Command 鍵開啟 Filestore Instances 資源連結，檢查服務是否轉換正常 👉 \033]8;;${url}\a點我開啟瀏覽器\033]8;;\a\n"
    ;;
N | n)
    exit
    ;;
*)
    echo -e "\n${RED}無效參數 ($REPLY)，請重新輸入${WHITE}\n"
    exit
    ;;
esac

filestore_output=$(gcloud filestore instances list --project ${project_id} --format="csv(INSTANCE_NAME,LOCATION)" --sort-by="INSTANCE_NAME")
filestore_output=$(echo "$filestore_output" | sed '1d') # 移除標題列
IFS=$'\n' read -rd '' -a filestore_array <<<"$filestore_output"

function process_filestore() {
    local filestore_data=$1
    local project_id=$2
    local project_name=$3

    export name=$(echo $filestore_data | cut -d "," -f 1)
    export location=$(echo $filestore_data | cut -d "," -f 2)

    echo -e "\n\033[1;32m====================================================================================================\033[0m"
    echo -e "\n\033[1;34m匯入 Filestore Instances 線上資源：\033[1;32m${name}\033[0m\n"

    mkdir -p ../projects/${project_name}/filestore-${name}
    cd ../projects/${project_name}/filestore-${name}

    echo "resource \"google_filestore_instance\" \"instance\" {}" >main.tf

    until
        export TF_PLUGIN_TIMEOUT=4h
        terraform init 1>/dev/null
    do
        echo -e "\n\033[1;33mterraform init 失敗，Delay 3 秒後重試 ....\033[0m"
        sleep 3
    done

    until terraform import google_filestore_instance.instance ${project_id}/${location}/${name} 1>/dev/null; do
        echo -e "\n\033[1;33mterraform import google_filestore_instance.instance 失敗，Delay 3 秒後重試 ....\033[0m"
        sleep 3
    done

    export description=$(cat terraform.tfstate | jq -r '.resources[].instances[].attributes.description')
    if [ "$description" == "" ]; then # 與預設值相同，則不顯示
        export description="default_setting"
    fi

    export tier=$(cat terraform.tfstate | jq -r '.resources[].instances[].attributes.tier')
    export file_shares_name=$(cat terraform.tfstate | jq -r '.resources[].instances[].attributes.file_shares[].name')

    export file_shares_capacity_tib=$(echo "scale=1; $(cat terraform.tfstate | jq -r '.resources[].instances[].attributes.file_shares[].capacity_gb') / 1024" | bc)
    if [[ "$file_shares_capacity_tib" =~ \.0$ ]]; then
        export file_shares_capacity_tib=$(echo "$file_shares_capacity_tib" | sed 's/\.0$//')
    fi

    export network=$(cat terraform.tfstate | jq -r '.resources[].instances[].attributes.networks[].network' | sed 's/.*networks\/\([^\/]*\).*/\1/')

    export connect_mode=$(cat terraform.tfstate | jq -r '.resources[].instances[].attributes.networks[].connect_mode')
    if [ "$connect_mode" == "PRIVATE_SERVICE_ACCESS" ]; then
        export connect_mode="default_setting" # 與預設值相同，則不顯示
    fi

    export labels=$(cat terraform.tfstate | jq -r '.resources[].instances[].attributes.labels')
    if [ "$labels" == "{}" ]; then
        export labels="default_setting" # 與預設值相同，則不顯示
    fi

    rm -rf *.tf .terraform*
    envsubst <../../../scripts/filestore-template >terragrunt.hcl

    # 移除與預設值相同的參數
    awk '!/default_setting/' terragrunt.hcl >temp_file && mv temp_file terragrunt.hcl

    until echo "yes" | terragrunt plan; do
        echo -e "\n\033[1;33mterragrunt plan 失敗，Delay 3 秒後重試 ....\033[0m"
        sleep 3
    done

    rm -rf terraform.tfstate .terraform* .terragrunt-cache

    terragrunt hclfmt

    cd ../../../scripts
}

export -f process_filestore
filestore_params=$(printf "%s\n" "${filestore_array[@]}")
echo "$filestore_params" | parallel --no-notice --jobs ${JOB_COUNT} process_filestore {} ${project_id} ${project_name}
