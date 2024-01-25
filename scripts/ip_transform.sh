#! /bin/bash
source ./common.sh

EXCLUDED_IPS=$(gcloud compute instances list --project ${project_id} --filter="(NOT name ~ ^gke- AND NOT name ~ ^runner-)" --format="value(INTERNAL_IP,EXTERNAL_IP)")
gcloud compute addresses list --project ${project_id} --filter="REGION ~ - AND NOT ADDRESS:(${EXCLUDED_IPS})" --format="table(NAME,REGION,ADDRESS)"

echo -e "\n"

read -r -e -p "以上為本次要匯入的 IP Address 線上資源 (排除 VM IP)，請確認是否繼續進行？(Y/N)：" continue
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

ip_output=$(gcloud compute addresses list --project ${project_id} --filter="REGION ~ - AND NOT ADDRESS:(${EXCLUDED_IPS})" --format="value(NAME,REGION)")
IFS=$'\n' read -rd '' -a ip_array <<<"$ip_output"

for ip_data in "${ip_array[@]}"; do
    export name=$(echo $ip_data | cut -d " " -f 1)
    export region=$(echo $ip_data | cut -d " " -f 2)

    mkdir -p ../projects/${project_name}/ip-${name}
    cd ../projects/${project_name}/ip-${name}

    echo "resource \"google_compute_address\" \"address\" {}" >main.tf

    terraform init 1>/dev/null
    terraform import google_compute_address.address ${project_id}/${region}/${name} 1>/dev/null

    echo -e "\n${BLUE}匯入 IP Address 線上資源：${GREEN}${name}${WHITE}"
    export description=$(cat terraform.tfstate | jq -r '.resources[].instances[].attributes.description')
    if [ "$description" == "" ]; then # 與預設值相同，則不顯示
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

    echo "yes" | terragrunt plan

    rm -rf terraform.tfstate .terraform* .terragrunt-cache

    terragrunt hclfmt

    cd ../../../scripts
done
