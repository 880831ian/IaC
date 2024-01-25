#! /bin/bash
source ./common.sh

gcloud compute instance-groups unmanaged list --project ${project_id} --filter="NOT name ~ ^k8s AND NOT name ~ mig AND NOT name ~ template" --format="table(NAME,ZONE)"

echo -e "\n"

read -r -e -p "以上為本次要匯入的 GCE-GROUP Instances 線上資源，請確認是否繼續進行？(Y/N)：" continue
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

gce_group_output=$(gcloud compute instance-groups unmanaged list --project ${project_id} --filter="NOT name ~ ^k8s AND NOT name ~ mig AND NOT name ~ template" --format="value(NAME,ZONE)")
IFS=$'\n' read -rd '' -a gce_group_array <<<"$gce_group_output"

for gce_group_data in "${gce_group_array[@]}"; do
    export name=$(echo $gce_group_data | cut -d " " -f 1)
    export zone=$(echo $gce_group_data | cut -d " " -f 2)

    mkdir -p ../projects/${project_name}/gce-group-${name}
    cd ../projects/${project_name}/gce-group-${name}

    echo "resource \"google_compute_instance_group\" \"group\" {}" >main.tf

    terraform init 1>/dev/null
    terraform import google_compute_instance_group.group $project_id/$zone/$name 1>/dev/null

    echo -e "\n${BLUE}匯入 GCE-GROUP Instances 線上資源：${GREEN}${name}${WHITE}"

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

    echo "yes" | terragrunt plan

    rm -rf terraform.tfstate terraform.tfstate.backup .terraform* .terragrunt-cache

    terragrunt hclfmt

    cd ../../../scripts
done
