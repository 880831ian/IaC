#! /bin/bash
source ./common.sh

EXCLUDED_VM_IPS=$(gcloud compute instances list --project ${project_id} --filter="(NOT name ~ ^gke- AND NOT name ~ ^runner-)" --format="value(INTERNAL_IP,EXTERNAL_IP)")
EXCLUDED_FRONTEND_IPS=$(gcloud compute forwarding-rules list --project=${project_id} \
    --filter="NOT description ~ 'kubernetes.io/service-name' AND NOT description ~ 'kubernetes.io/ingress-name'" \
    --format="value(IP_ADDRESS)")
ALL_EXCLUDED_IPS="${EXCLUDED_VM_IPS} ${EXCLUDED_FRONTEND_IPS}"

FILTER_STRING=$(echo $ALL_EXCLUDED_IPS | sed 's/ \+/ OR /g')
FILTER_STRING=$(echo "${FILTER_STRING}" | sed 's/ / OR /g')

output=$(gcloud compute addresses list --project=${project_id} --filter="REGION ~ - AND NOT (${FILTER_STRING})" --format="table(NAME,REGION,ADDRESS)" --sort-by="NAME")

if [ -z "$output" ]; then
    echo -e "${RED}該專案無此資源 (IP Address) ，請重新選擇專案${WHITE}\n"
    exit
else
    echo "$output"
fi

echo -e "\n"

read -r -e -p "以上為本次要匯入的 IP Address 線上資源 (排除 VM IP、LB IP)，請確認是否繼續進行？(Y/N)：" continue
case $continue in
Y | y)
    echo -e "\n${GREEN}開始轉換 IP Address 線上資源 ... (請稍等) ◟(ꉺᴗꉺ๑)◝ ... ${WHITE}\n"
    url="https://console.cloud.google.com/networking/addresses/list?project=${project_id}"
    echo -e "可以先按住 Command 鍵開啟 IP Address 資源連結，檢查服務是否轉換正常 👉 \033]8;;${url}\a點我開啟瀏覽器\033]8;;\a\n"
    ;;
N | n)
    exit
    ;;
*)
    echo -e "\n${RED}無效參數 ($REPLY)，請重新輸入${WHITE}\n"
    exit
    ;;
esac

ip_output=$(gcloud compute addresses list --project ${project_id} --filter="REGION ~ - AND NOT (${FILTER_STRING})" --format="csv(NAME,REGION)" --sort-by="NAME")
ip_output=$(echo "$ip_output" | sed '1d') # 移除標題列
IFS=$'\n' read -rd '' -a ip_array <<<"$ip_output"

function process_ip() {
    local ip_data=$1
    local project_id=$2
    local project_name=$3

    export name=$(echo $ip_data | cut -d "," -f 1)
    export region=$(echo $ip_data | cut -d "," -f 2)

    echo -e "\n\033[1;32m====================================================================================================\033[0m"
    echo -e "\n\033[1;34m匯入 IP Address 線上資源：\033[1;32m${name}\033[0m\n"

    mkdir -p ../projects/${project_name}/ip-${name}
    cd ../projects/${project_name}/ip-${name}

    echo "resource \"google_compute_address\" \"address\" {}" >main.tf

    until
        export TF_PLUGIN_TIMEOUT=4h
        terraform init 1>/dev/null
    do
        echo -e "\n\033[1;33mterraform init 失敗，Delay 3 秒後重試 ....\033[0m"
        sleep 3
    done

    until terraform import google_compute_address.address ${project_id}/${region}/${name} 1>/dev/null; do
        echo -e "\n\033[1;33mterraform import google_compute_address.address 失敗，Delay 3 秒後重試 ....\033[0m"
        sleep 3
    done

    export description=$(cat terraform.tfstate | jq '.resources[].instances[].attributes.description')
    if [ $description == '""' ]; then # 與預設值相同，則不顯示
        export description="default_setting"
    fi

    export address_type=$(cat terraform.tfstate | jq -r '.resources[].instances[].attributes.address_type')
    export ip_address=$(cat terraform.tfstate | jq -r '.resources[].instances[].attributes.address')

    export subnetwork=$(cat terraform.tfstate | jq -r '.resources[].instances[].attributes.subnetwork' | sed 's/.*subnetworks\/\([^\/]*\).*/\1/')
    if [ "$subnetwork" == "" ]; then
        export subnetwork="default_setting" # 與預設值相同，則不顯示
    fi

    export network_tier=$(cat terraform.tfstate | jq -r '.resources[].instances[].attributes.network_tier')
    if [ "$network_tier" == "PREMIUM" ]; then
        export network_tier="default_setting" # 與預設值相同，則不顯示
    fi

    export labels=$(cat terraform.tfstate | jq -r '.resources[].instances[].attributes.labels')
    if [ "$labels" == "{}" ]; then
        export labels="default_setting" # 與預設值相同，則不顯示
    fi

    rm -rf *.tf .terraform*
    envsubst <../../../scripts/ip-template >terragrunt.hcl

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

export -f process_ip
ip_params=$(printf "%s\n" "${ip_array[@]}")
echo "$ip_params" | parallel --no-notice --jobs ${JOB_COUNT} process_ip {} ${project_id} ${project_name}
