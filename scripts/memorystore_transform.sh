#! /bin/bash
source ./common.sh

output=$(gcloud redis instances list --region ${region} --project ${project_id} --format="table(INSTANCE_NAME,REGION)" --sort-by="INSTANCE_NAME")

if [ -z "$output" ]; then
    echo -e "${RED}該專案無此資源 (Memorystore) ，請重新選擇專案${WHITE}\n"
    exit
else
    echo "$output"
fi

echo -e "\n"

read -r -e -p "以上為本次要匯入的 Memorystore Redis Instances 線上資源，請確認是否繼續進行？(Y/N)：" continue
case $continue in
Y | y)
    echo -e "\n${GREEN}開始轉換 Memorystore Redis Instances 線上資源 ... (請稍等) ◟(ꉺᴗꉺ๑)◝ ... ${WHITE}\n"
    ;;
N | n)
    exit
    ;;
*)
    echo -e "\n${RED}無效參數 ($REPLY)，請重新輸入${WHITE}\n"
    exit
    ;;
esac

redis_output=$(gcloud redis instances list --region ${region} --project ${project_id} --format="csv(INSTANCE_NAME,REGION)" --sort-by="INSTANCE_NAME")
redis_output=$(echo "$redis_output" | sed '1d') # 移除標題列
IFS=$'\n' read -rd '' -a redis_array <<<"$redis_output"

function process_memorystore() {
    local redis_data=$1
    local project_id=$2
    local project_name=$3

    export name=$(echo $redis_data | cut -d "," -f 1)
    export region=$(echo $redis_data | cut -d "," -f 2)

    echo -e "\n\033[1;32m====================================================================================================\033[0m"
    echo -e "\n\033[1;34m匯入 Memorystore Redis Instances 線上資源：\033[1;32m${name}\033[0m\n"

    mkdir -p ../projects/${project_name}/memorystore-${name}
    cd ../projects/${project_name}/memorystore-${name}

    echo "resource \"google_redis_instance\" \"instance\" {}" >main.tf

    until
        export TF_PLUGIN_TIMEOUT=4h
        terraform init 1>/dev/null
    do
        echo -e "\n\033[1;33mterraform init 失敗，Delay 3 秒後重試 ....\033[0m"
        sleep 3
    done

    until terraform import google_redis_instance.instance ${project_id}/${region}/${name} 1>/dev/null; do
        echo -e "\n\033[1;33mterraform import google_redis_instance.instance 失敗，Delay 3 秒後重試 ....\033[0m"
        sleep 3
    done

    export display_name=$(cat terraform.tfstate | jq -r '.resources[].instances[].attributes.display_name')
    if [ "$display_name" == "" ]; then # 與預設值相同，則不顯示
        export display_name="default_setting"
    fi

    export tier=$(cat terraform.tfstate | jq -r '.resources[].instances[].attributes.tier')
    if [ "$tier" == "STANDARD_HA" ]; then # 與預設值相同，則不顯示
        export tier="default_setting"
    fi

    export memory_size_gb=$(cat terraform.tfstate | jq -r '.resources[].instances[].attributes.memory_size_gb')
    if [ "$memory_size_gb" == "5" ]; then # 與預設值相同，則不顯示
        export memory_size_gb="default_setting"
    fi

    export region=$(cat terraform.tfstate | jq -r '.resources[].instances[].attributes.region')

    export replica_count=$(cat terraform.tfstate | jq -r '.resources[].instances[].attributes.replica_count')
    if [ "$replica_count" == "2" ]; then # 與預設值相同，則不顯示
        export replica_count="default_setting"
    fi

    export read_replicas_mode=$(cat terraform.tfstate | jq -r '.resources[].instances[].attributes.read_replicas_mode')
    if [ "$read_replicas_mode" == "READ_REPLICAS_ENABLED" ]; then # 與預設值相同，則不顯示
        export read_replicas_mode="default_setting"
    fi

    export network=$(cat terraform.tfstate | jq -r '.resources[].instances[].attributes.authorized_network' | sed 's/.*networks\/\([^\/]*\).*/\1/')

    export connect_mode=$(cat terraform.tfstate | jq -r '.resources[].instances[].attributes.connect_mode')
    if [ "$connect_mode" == "PRIVATE_SERVICE_ACCESS" ]; then
        export connect_mode="default_setting" # 與預設值相同，則不顯示
    fi

    export auth_enabled=$(cat terraform.tfstate | jq -r '.resources[].instances[].attributes.auth_enabled')
    if [ "$auth_enabled" == "true" ]; then
        export auth_enabled="default_setting" # 與預設值相同，則不顯示
    fi

    export maintenance_policy=$(cat terraform.tfstate | jq -r '.resources[].instances[].attributes.maintenance_policy')
    if [ "$maintenance_policy" = "[]" ]; then
        export maintenance_policy=null
    else
        export maintenance_policy=$(cat terraform.tfstate | jq -r '.resources[].instances[].attributes.maintenance_policy[].weekly_maintenance_window[] | {day: .day, start_time: .start_time[0]}' | sed -e 's/:/=/g' -e 's/\"day\"/day/g' -e 's/\"start_time\"/start_time/g' -e 's/,//g' -e '/^$/d')
    fi

    export redis_version=$(cat terraform.tfstate | jq -r '.resources[].instances[].attributes.redis_version')
    if [ "$redis_version" == "REDIS_5_0" ]; then
        export redis_version="default_setting" # 與預設值相同，則不顯示
    fi

    export redis_configs=$(cat terraform.tfstate | jq -r '.resources[].instances[].attributes.redis_configs' | sed 's/:/=/g')

    export labels=$(cat terraform.tfstate | jq -r '.resources[].instances[].attributes.labels')
    if [ "$labels" == "{}" ]; then
        export labels="default_setting" # 與預設值相同，則不顯示
    fi

    rm -rf *.tf .terraform*
    envsubst <../../../scripts/memorystore-template >terragrunt.hcl

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

export -f process_memorystore
redis_params=$(printf "%s\n" "${redis_array[@]}")
echo "$redis_params" | parallel --no-notice --jobs ${JOB_COUNT} process_memorystore {} ${project_id} ${project_name}
