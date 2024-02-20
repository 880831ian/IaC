#! /bin/bash
source ./common.sh

output=$(gcloud compute instances list --project ${project_id} --filter="(NOT name ~ ^gke- AND NOT name ~ ^runner- AND NOT name ~ mig AND NOT name ~ template) AND status:RUNNING" --format="table(NAME,ZONE,INTERNAL_IP,EXTERNAL_IP)" --sort-by="NAME")

if [ -z "$output" ]; then
    echo -e "${RED}該專案無此資源 (GCE) ，請重新選擇專案${WHITE}\n"
    exit
else
    echo "$output"
fi

echo -e "\n"

read -r -e -p "以上為本次要匯入的 GCE Instances 線上資源，請確認是否繼續進行？(Y/N)：" continue
case $continue in
Y | y)
    echo -e "\n${GREEN}開始轉換 GCE Instances 線上資源 ... (請稍等) ◟(ꉺᴗꉺ๑)◝ ... ${WHITE}\n"
    url="https://console.cloud.google.com/compute/instances?project=${project_id}"
    echo -e "可以先按住 Command 鍵開啟 GCE Instances 資源連結，檢查服務是否轉換正常 👉 \033]8;;${url}\a點我開啟瀏覽器\033]8;;\a\n"
    ;;
N | n)
    exit
    ;;
*)
    echo -e "\n${RED}無效參數 ($REPLY)，請重新輸入${WHITE}\n"
    exit
    ;;
esac

gce_output=$(gcloud compute instances list --project ${project_id} --filter="(NOT name ~ ^gke- AND NOT name ~ ^runner- AND NOT name ~ mig AND NOT name ~ template) AND status:RUNNING" --format="csv(NAME,ZONE,INTERNAL_IP,EXTERNAL_IP)" --sort-by="NAME")
gce_output=$(echo "$gce_output" | sed '1d') # 移除標題列
IFS=$'\n' read -rd '' -a gce_array <<<"$gce_output"

function process_instance() {
    local gce_data=$1
    local project_id=$2
    local project_name=$3

    export name=$(echo $gce_data | cut -d "," -f 1)
    export zone=$(echo $gce_data | cut -d "," -f 2)
    export region=$(echo $zone | sed 's/-[^-]*$//')
    export internal_ip_address=$(echo $gce_data | cut -d "," -f 3)
    export external_ip_address=$(echo $gce_data | cut -d "," -f 4)
    export internal_ip_address_name=$(gcloud compute addresses list --project ${project_id} --filter="address ~ $internal_ip_address$" --format="value(NAME)")
    if [ "$external_ip_address" != "" ]; then
        export external_ip_address_name=$(gcloud compute addresses list --project ${project_id} --filter="address ~ $external_ip_address$" --format="value(NAME)")
    else
        export external_ip_address_name=""
    fi

    echo -e "\n\033[1;32m====================================================================================================\033[0m"
    echo -e "\n\033[1;34m匯入 GCE Instances 線上資源：\033[1;32m${name}\033[0m\n"

    mkdir -p ../projects/${project_name}/gce-${name}
    cd ../projects/${project_name}/gce-${name}

    echo "resource \"google_compute_instance\" \"instance\" {}" >main.tf
    echo "resource \"google_compute_address\" \"internal-address\" {}" >>main.tf

    if [ "$external_ip_address" != "" ]; then
        echo "resource \"google_compute_address\" \"external-address\" {}" >>main.tf
    fi

    until
        export TF_PLUGIN_TIMEOUT=4h
        terraform init 1>/dev/null
    do
        echo -e "\n\033[1;33mterraform init 失敗，Delay 3 秒後重試 ....\033[0m"
        sleep 3
    done

    until terraform import google_compute_instance.instance $project_id/$zone/$name 1>/dev/null; do
        echo -e "\n\033[1;33mterraform import google_compute_instance.instance 失敗，Delay 3 秒後重試 ....\033[0m"
        sleep 3
    done

    if [ "$internal_ip_address_name" != "" ]; then
        terraform import google_compute_address.internal-address $project_id/$region/$internal_ip_address_name 1>/dev/null
    fi
    if [ "$external_ip_address_name" != "" ]; then
        terraform import google_compute_address.external-address $project_id/$region/$external_ip_address_name 1>/dev/null
    fi

    export machine_type=$(cat terraform.tfstate | jq -r '.resources[] | select(.type == "google_compute_instance") | .instances[].attributes.machine_type')

    export enable_display=$(cat terraform.tfstate | jq -r '.resources[] | select(.type == "google_compute_instance") | .instances[].attributes.enable_display')
    if [ "$enable_display" == "false" ]; then # 與預設值相同，則不顯示
        export enable_display="default_setting"
    fi

    export network_tags=$(cat terraform.tfstate | jq -r '.resources[] | select(.type == "google_compute_instance") | .instances[].attributes.tags')
    if [ "$network_tags" == "[]" ]; then
        export network_tags="default_setting" # 與預設值相同，則不顯示
    fi

    export labels=$(cat terraform.tfstate | jq -r '.resources[] | select(.type == "google_compute_instance") | .instances[].attributes.boot_disk[].initialize_params[].labels')
    if [ "$labels" == "{}" ]; then
        export labels="default_setting" # 與預設值相同，則不顯示
    fi

    export boot_disk_auto_delete=$(cat terraform.tfstate | jq -r '.resources[] | select(.type == "google_compute_instance") | .instances[].attributes.boot_disk[].auto_delete')
    if [ "$boot_disk_auto_delete" == "true" ]; then # 與預設值 true 相同，則不顯示
        export boot_disk_auto_delete="default_setting"
    fi

    export boot_disk_device_name=$(cat terraform.tfstate | jq -r '.resources[] | select(.type == "google_compute_instance") | .instances[].attributes.boot_disk[].device_name')
    if [ "$boot_disk_device_name" == "$name" ]; then # 與預設值 true 相同，則不顯示
        export boot_disk_device_name="default_setting"
    fi

    export boot_disk_image=$(cat terraform.tfstate | jq -r '.resources[] | select(.type == "google_compute_instance") | .instances[].attributes.boot_disk[].initialize_params[].image | split("/") | .[-1]')
    if [ "$boot_disk_image" == "null" ]; then # 與預設值空值相同，則不顯示
        export boot_disk_image="default_setting"
    fi

    export boot_disk_size=$(cat terraform.tfstate | jq -r '.resources[] | select(.type == "google_compute_instance") | .instances[].attributes.boot_disk[].initialize_params[].size')
    if [ "$boot_disk_size" == "10" ]; then # 與預設值 10 相同，則不顯示
        export boot_disk_size="default_setting"
    fi

    export boot_disk_type=$(cat terraform.tfstate | jq -r '.resources[] | select(.type == "google_compute_instance") | .instances[].attributes.boot_disk[].initialize_params[].type')
    if [ "$boot_disk_type" == "pd-balanced" ]; then # 與預設值 pd-balanced 相同，則不顯示
        export boot_disk_type="default_setting"
    fi

    export boot_disk_mode=$(cat terraform.tfstate | jq -r '.resources[] | select(.type == "google_compute_instance") | .instances[].attributes.boot_disk[].mode')
    if [ "$boot_disk_mode" == "READ_WRITE" ]; then # 與預設值 READ_WRITE 相同，則不顯示
        export boot_disk_mode="default_setting"
    fi

    attached_disk_enabled=$(cat terraform.tfstate | jq '.resources[] | select(.type == "google_compute_instance") | .instances[].attributes.attached_disk')
    if [ "$attached_disk_enabled" == "[]" ]; then # 與預設值 false 相同，則不顯示
        export attached_disk_enabled="default_setting"
        export attached_disk_device_name="default_setting"
        export attached_disk_mode="default_setting"
        export attached_disk_source="default_setting"
    else
        export attached_disk_enabled="true"
        export attached_disk_device_name=$(cat terraform.tfstate | jq '.resources[] | select(.type == "google_compute_instance") | .instances[].attributes.attached_disk[].device_name' | tr -d '"')
        export attached_disk_mode=$(cat terraform.tfstate | jq '.resources[] | select(.type == "google_compute_instance") | .instances[].attributes.attached_disk[].mode' | tr -d '"')
        if [ "$attached_disk_mode" == "READ_WRITE" ]; then # 與預設值 READ_WRITE 相同，則不顯示
            export attached_disk_mode="default_setting"
        fi
        export attached_disk_source=$(cat terraform.tfstate | jq '.resources[] | select(.type == "google_compute_instance") | .instances[].attributes.attached_disk[].source' | tr -d '"')
    fi

    export network_project_id=$(cat terraform.tfstate | jq -r '.resources[] | select(.type == "google_compute_instance") | .instances[].attributes.network_interface[].network' | sed -n 's/.*projects\/\([^\/]*\).*/\1/p')
    if [ "$network_project_id" != "$project_id" ]; then # 與預設值相同，則不顯示
        export network_project_id="default_setting"
    fi

    export network=$(cat terraform.tfstate | jq -r '.resources[] | select(.type == "google_compute_instance") | .instances[].attributes.network_interface[].network' | sed 's/.*networks\/\([^\/]*\).*/\1/')
    export subnetwork=$(cat terraform.tfstate | jq -r '.resources[] | select(.type == "google_compute_instance") | .instances[].attributes.network_interface[].subnetwork' | sed 's/.*subnetworks\/\([^\/]*\).*/\1/')

    nat_ip=$(cat terraform.tfstate | jq -r '.resources[] | select(.type == "google_compute_instance") | .instances[].attributes.network_interface[].access_config[].nat_ip')
    if [ "$nat_ip" == "" ]; then
        export nat_ip_enabled="default_setting" # 與預設值相同，則不顯示
        export external_ip_address_name="default_setting"
        export external_ip_address="default_setting"
    else
        export nat_ip_enabled="true"
    fi

    export metadata=$(cat terraform.tfstate | jq -r '.resources[] | select(.type == "google_compute_instance") | .instances[].attributes.metadata')
    metadata=$(echo "$metadata" | jq 'del(.["ssh-keys"])') # 移除 ssh-keys
    if [ "$metadata" == "{}" ]; then
        export metadata="default_setting" # 與預設值相同，則不顯示
    fi

    export resource_policies=$(cat terraform.tfstate | jq '.resources[] | select(.type == "google_compute_instance") | .instances[].attributes.resource_policies')
    if [ "$resource_policies" == "[]" ]; then
        export resource_policies="default_setting" # 與預設值相同，則不顯示
    fi

    service_account_enabled=$(cat terraform.tfstate | jq '.resources[] | select(.type == "google_compute_instance") | .instances[].attributes.service_account')
    if [ "$service_account_enabled" == "[]" ]; then # 與預設值 false 相同，則不顯示
        export service_account_enabled="false"
        export service_account_email="default_setting"
        export service_account_scopes="default_setting"
    else
        export service_account_enabled="default_setting"
        export service_account_email=$(cat terraform.tfstate | jq -r '.resources[] | select(.type == "google_compute_instance") | .instances[].attributes.service_account[].email')
        export service_account_scopes=$(cat terraform.tfstate | jq -r '.resources[] | select(.type == "google_compute_instance") | .instances[].attributes.service_account[].scopes')
        scopes=$(echo "$service_account_scopes" | jq -r '.[]')

        default_service_account_scopes=(
            "https://www.googleapis.com/auth/devstorage.read_only"
            "https://www.googleapis.com/auth/logging.write"
            "https://www.googleapis.com/auth/monitoring.write"
            "https://www.googleapis.com/auth/service.management.readonly"
            "https://www.googleapis.com/auth/servicecontrol"
            "https://www.googleapis.com/auth/trace.append"
        )

        if [ "$(echo "$scopes" | tr '\n' ' ')" == "$(echo "${default_service_account_scopes[@]}" | tr '\n' ' ')" ]; then
            export service_account_scopes="default_setting" # 與預設值相同，則不顯示
        fi
        if [ "$service_account_scopes" == "" ]; then
            export service_account_scopes=[]
        fi
    fi

    export deletion_protection=$(cat terraform.tfstate | jq -r '.resources[] | select(.type == "google_compute_instance") | .instances[].attributes.deletion_protection')
    if [ "$deletion_protection" == "false" ]; then # 與預設值相同，則不顯示
        export deletion_protection="default_setting"
    fi

    export allow_stopping_for_update=$(cat terraform.tfstate | jq -r '.resources[] | select(.type == "google_compute_instance") | .instances[].attributes.allow_stopping_for_update')
    if [ "$allow_stopping_for_update" == null ]; then # 與預設值相同，則不顯示
        export allow_stopping_for_update="default_setting"
    fi

    export internal_ip_address_description=$(cat terraform.tfstate | jq -r '.resources[] | select(.name == "internal-address") | .instances[].attributes.description')
    if [ "$internal_ip_address_description" == "" ]; then # 與預設值相同，則不顯示
        export internal_ip_address_description="default_setting"
    fi

    export external_ip_address_description=$(cat terraform.tfstate | jq -r '.resources[] | select(.name == "external-address") | .instances[].attributes.description')
    if [ "$external_ip_address_description" == "" ]; then # 與預設值相同，則不顯示
        export external_ip_address_description="default_setting"
    fi

    export external_network_tier=$(cat terraform.tfstate | jq -r '.resources[] | select(.name == "external-address") | .instances[].attributes.network_tier')
    if [ "$external_network_tier" == "PREMIUM" ] || [ "$external_network_tier" == "" ]; then # 與預設值相同，則不顯示
        export external_network_tier="default_setting"
    fi

    rm -rf *.tf .terraform*
    envsubst <../../../scripts/gce-template >terragrunt.hcl

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

export -f process_instance
instance_params=$(printf "%s\n" "${gce_array[@]}")
echo "$instance_params" | parallel --no-notice --jobs ${JOB_COUNT} process_instance {} ${project_id} ${project_name}
