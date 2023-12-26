#! /bin/bash
source ./common.sh

gcloud filestore instances list --project ${project_id} --format="table(INSTANCE_NAME,LOCATION)"

echo -e "\n"

read -r -e -p "以上為本次要匯入的 Filestore Instances 線上資源，請確認是否繼續進行？(Y/N)：" continue
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

filestore_output=$(gcloud filestore instances list --project ${project_id} --format="value(INSTANCE_NAME,LOCATION)")
IFS=$'\n' read -rd '' -a filestore_array <<<"$filestore_output"

for filestore_data in "${filestore_array[@]}"; do
    export name=$(echo $filestore_data | cut -d " " -f 1)
    export location=$(echo $filestore_data | cut -d " " -f 2)

    mkdir -p ../projects/${project_name}/filestore-${name}
    cd ../projects/${project_name}/filestore-${name}

    echo "resource \"google_filestore_instance\" \"instance\" {}" >main.tf

    terraform init 1>/dev/null
    terraform import google_filestore_instance.instance ${project_id}/${location}/${name} 1>/dev/null

    echo -e "\n${BLUE}匯入 Filestore Instances 線上資源：${GREEN}${name}${WHITE}"
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

    echo "yes" | terragrunt plan

    rm -rf terraform.tfstate .terraform* .terragrunt-cache

    terragrunt hclfmt

    cd ../../../scripts
done
