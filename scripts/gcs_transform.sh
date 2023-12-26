#! /bin/bash
source ./common.sh

gcloud storage buckets list --project ${project_id} --filter="NOT name ~ ^gcf-sources AND NOT name ~ appspot.com$" --format="value(NAME)"

echo -e "\n"

read -r -e -p "以上為本次要匯入的 GCS Bucket 線上資源，請確認是否繼續進行？(Y/N)：" continue
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

gcs_output=$(gcloud storage buckets list --project ${project_id} --filter="NOT name ~ ^gcf-sources AND NOT name ~ appspot.com$" --format="value(NAME)")
IFS=$'\n' read -d ' ' -a gcs_array <<<"$gcs_output"

for gcs_data in "${gcs_array[@]}"; do
    export name=$(echo $gcs_data)

    mkdir -p ../projects/${project_name}/gcs-${name}
    cd ../projects/${project_name}/gcs-${name}

    echo "resource \"google_storage_bucket\" \"bucket\" {}" >main.tf

    terraform init 1>/dev/null
    terraform import google_storage_bucket.bucket $project_id/$name 1>/dev/null

    echo -e "\n${BLUE}匯入 GCS Bucket 線上資源：${GREEN}${name}${WHITE}"
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

    echo "yes" | terragrunt plan

    rm -rf terraform.tfstate .terraform* .terragrunt-cache

    terragrunt hclfmt

    cd ../../../scripts
done
