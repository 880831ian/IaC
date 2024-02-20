#! /bin/bash
source ./common.sh

output=$(gcloud storage buckets list --project ${project_id} --filter="NOT name ~ ^gcf-sources AND NOT name ~ appspot.com$" --format="table(NAME)" --sort-by="NAME")

if [ -z "$output" ]; then
    echo -e "${RED}該專案無此資源 (GCS) ，請重新選擇專案${WHITE}\n"
    exit
else
    echo "$output"
fi

echo -e "\n"

read -r -e -p "以上為本次要匯入的 GCS Bucket 線上資源，請確認是否繼續進行？(Y/N)：" continue
case $continue in
Y | y)
    echo -e "\n${GREEN}開始轉換 GCS Bucket 線上資源 ... (請稍等) ◟(ꉺᴗꉺ๑)◝ ... ${WHITE}\n"
    url="https://console.cloud.google.com/storage/browser?project=${project_id}"
    echo -e "可以先按住 Command 鍵開啟 GCS Bucket 資源連結，檢查服務是否轉換正常 👉 \033]8;;${url}\a點我開啟瀏覽器\033]8;;\a\n"
    ;;
N | n)
    exit
    ;;
*)
    echo -e "\n${RED}無效參數 ($REPLY)，請重新輸入${WHITE}\n"
    exit
    ;;
esac

gcs_output=$(gcloud storage buckets list --project ${project_id} --filter="NOT name ~ ^gcf-sources AND NOT name ~ appspot.com$" --format="csv(NAME)" --sort-by="NAME")
gcs_output=$(echo "$gcs_output" | sed '1d') # 移除標題列
IFS=$'\n' read -d ' ' -a gcs_array <<<"$gcs_output"

function process_gcs() {
    local gcs_data=$1
    local project_id=$2
    local project_name=$3

    export name=$(echo $gcs_data)

    echo -e "\n\033[1;32m====================================================================================================\033[0m"
    echo -e "\n\033[1;34m匯入 GCS Bucket 線上資源：\033[1;32m${name}\033[0m\n"

    mkdir -p ../projects/${project_name}/gcs-${name}
    cd ../projects/${project_name}/gcs-${name}

    echo "resource \"google_storage_bucket\" \"bucket\" {}" >main.tf

    until
        export TF_PLUGIN_TIMEOUT=4h
        terraform init 1>/dev/null
    do
        echo -e "\n\033[1;33mterraform init 失敗，Delay 3 秒後重試 ....\033[0m"
        sleep 3
    done

    until terraform import google_storage_bucket.bucket $project_id/$name 1>/dev/null; do
        echo -e "\n\033[1;33mterraform import google_filestore_instance.instance 失敗，Delay 3 秒後重試 ....\033[0m"
        sleep 3
    done

    export location=$(cat terraform.tfstate | jq -r '.resources[].instances[].attributes.location')

    export labels=$(cat terraform.tfstate | jq -r '.resources[].instances[].attributes.labels')
    if [ "$labels" == "{}" ]; then
        export labels="default_setting" # 與預設值相同，則不顯示
    fi

    export custom_placement_config=$(cat terraform.tfstate | jq -r '.resources[].instances[].attributes.custom_placement_config')
    if [ "$custom_placement_config" == "[]" ]; then # 與預設值相同，則不顯示
        export custom_placement_config="default_setting"
    fi

    export autoclass=$(cat terraform.tfstate | jq -r '.resources[].instances[].attributes.autoclass[].enabled')
    if [ "$autoclass" == false ] || [ "$autoclass" == "" ]; then # 與預設值相同，則不顯示
        export autoclass="default_setting"
    fi

    export storage_class=$(cat terraform.tfstate | jq -r '.resources[].instances[].attributes.storage_class')
    if [ "$storage_class" == "STANDARD" ]; then # 與預設值相同，則不顯示
        export storage_class="default_setting"
    fi

    export public_access_prevention=$(cat terraform.tfstate | jq -r '.resources[].instances[].attributes.public_access_prevention')
    if [ "$public_access_prevention" == "enforced" ]; then # 與預設值相同，則不顯示
        export public_access_prevention="default_setting"
    fi

    export uniform_bucket_level_access=$(cat terraform.tfstate | jq -r '.resources[].instances[].attributes.uniform_bucket_level_access')
    if [ "$uniform_bucket_level_access" == true ]; then # 與預設值相同，則不顯示
        export uniform_bucket_level_access="default_setting"
    fi

    export force_destroy=$(cat terraform.tfstate | jq -r '.resources[].instances[].attributes.force_destroy')
    if [ "$force_destroy" == false ]; then # 與預設值相同，則不顯示
        export force_destroy="default_setting"
    fi

    export versioning=$(cat terraform.tfstate | jq -r '.resources[].instances[].attributes.versioning[].enabled')
    if [ "$versioning" == "" ]; then # 與預設值相同，則不顯示
        export versioning=null
    fi
    if [ "$versioning" == false ]; then # 與預設值相同，則不顯示
        export versioning="default_setting"
    fi

    export retention_policy=$(cat terraform.tfstate | jq -r '.resources[].instances[].attributes.retention_policy')
    if [ "$retention_policy" == "[]" ]; then # 與預設值相同，則不顯示
        export retention_policy="default_setting"
    fi

    export lifecycle_rule=$(cat terraform.tfstate | jq -r '.resources[].instances[].attributes.lifecycle_rule')
    if [ "$lifecycle_rule" == "[]" ]; then # 與預設值相同，則不顯示
        export lifecycle_rule="default_setting"
    fi

    export cors=$(cat terraform.tfstate | jq -r '.resources[].instances[].attributes.cors')
    if [ "$cors" == "[]" ]; then # 與預設值相同，則不顯示
        export cors="default_setting"
    fi

    rm -rf *.tf .terraform*
    envsubst <../../../scripts/gcs-template >terragrunt.hcl

    # 移除與預設值相同的參數
    awk '!/default_setting/' terragrunt.hcl >temp_file && mv temp_file terragrunt.hcl

    sed -i "" 's/:/=/g' terragrunt.hcl # 只有 macOS 會需要 -i ""，Linux 不需要

    until echo "yes" | terragrunt plan; do
        echo -e "\n\033[1;33mterragrunt plan 失敗，Delay 3 秒後重試 ....\033[0m"
        sleep 3
    done

    rm -rf terraform.tfstate .terraform* .terragrunt-cache

    terragrunt hclfmt

    cd ../../../scripts
}

export -f process_gcs
gcs_params=$(printf "%s\n" "${gcs_array[@]}")
echo "$gcs_params" | parallel --no-notice --jobs ${JOB_COUNT} process_gcs {} ${project_id} ${project_name}
