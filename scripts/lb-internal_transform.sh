#! /bin/bash
source ./common.sh

while read -r backend_service_name backend_service_region health_check; do
    if [ "$backend_service_name" == "" ]; then
        echo -e "${RED}該專案無此資源 (Load Balancer) ，請重新選擇專案${WHITE}\n"
        exit
    fi
    backend_service_region=$(echo $backend_service_region | awk -F'/' '{print $NF}')
    health_check=$(echo $health_check | awk -F'/' '{print $NF}')
    echo -e "BACKEND_NAME: ${backend_service_name}"
    echo -e "REGION: ${backend_service_region}"
    echo -e "HEALTH_CHECK: ${health_check}"
    frontend_output=$(gcloud compute forwarding-rules list --project ${project_id} --filter="${backend_service_name}" --format="value(NAME,IP_ADDRESS)")
    IFS=$'\n' read -rd '' -a frontend_array <<<"$frontend_output"
    for frontend in "${frontend_array[@]}"; do
        frontend_name=$(echo $frontend | cut -d " " -f 1)
        internal_ip_address=$(echo $frontend | cut -d " " -f 2)
        internal_ip_address_name=$(gcloud compute addresses list --project ${project_id} --filter="ADDRESS:(${internal_ip_address})" --format="value(NAME)")

        echo -e "FRONTEND_NAME: ${frontend_name}"
        echo -e "ADDRESS_NAME: ${internal_ip_address_name}"
        echo -e "ADDRESS: ${internal_ip_address}"
    done
    echo -e "\n"
done <<<"$(gcloud compute backend-services list --project ${project_id} --filter="NOT BACKENDS ~ k8s AND INTERNAL AND NOT INTERNAL_MANAGED" --format="value(NAME,REGION,health_checks)")"

read -r -e -p "以上為本次要匯入的 Load Balancer 線上資源，請確認是否繼續進行？(Y/N)：" continue
case $continue in
Y | y)
    echo -e "\n${GREEN}開始轉換 Load Balancer 線上資源 ... (請稍等) ◟(ꉺᴗꉺ๑)◝ ... ${WHITE}\n"
    url="https://console.cloud.google.com/net-services/loadbalancing/list/loadBalancers?project=${project_id}"
    echo -e "可以先按住 Command 鍵開啟 Load Balancer 資源連結，檢查服務是否轉換正常 👉 \033]8;;${url}\a點我開啟瀏覽器\033]8;;\a\n"
    ;;
N | n)
    exit
    ;;
*)
    echo -e "\n${RED}無效參數 ($REPLY)，請重新輸入${WHITE}\n"
    exit
    ;;
esac

while read -r backend_service_name backend_service_region health_check PROTOCOL; do
    if [ "$backend_service_name" == "" ]; then
        echo -e "\n${RED}無效參數 ($REPLY)，請重新輸入${WHITE}\n"
        exit
    fi

    export name=$(echo $backend_service_name)
    export backend_service_region=$(echo $backend_service_region | awk -F'/' '{print $NF}')

    health_check_state=""
    if echo "$health_check" | grep -q "regions"; then
        export health_check_state="region"
    fi

    export health_check=$(echo $health_check | awk -F'/' '{print $NF}')

    echo -e "\n\033[1;32m====================================================================================================\033[0m"
    echo -e "\n${BLUE}匯入 Load Balancer 線上資源：${GREEN}${name}${WHITE}\n"

    mkdir -p ../projects/${project_name}/lb-internal-${name}
    cd ../projects/${project_name}/lb-internal-${name}

    PROTOCOL=$(echo $PROTOCOL | tr '[:upper:]' '[:lower:]')

    echo "resource \"google_compute_region_backend_service\" \"backend\" {}" >main.tf

    if [ "$health_check_state" == "region" ]; then
        echo "resource \"google_compute_region_health_check\" \"${PROTOCOL}\" { count = 1 }" >>main.tf
    else
        echo "resource \"google_compute_health_check\" \"${PROTOCOL}\" { count = 1 }" >>main.tf
    fi

    terraform init 1>/dev/null
    terraform import google_compute_region_backend_service.backend $project_id/$backend_service_region/$name 1>/dev/null

    if [ "$health_check_state" == "region" ]; then
        terraform import google_compute_region_health_check.${PROTOCOL}[0] $project_id/$backend_service_region/$health_check 1>/dev/null
        health_check_type="google_compute_region_health_check"
    else
        terraform import google_compute_health_check.${PROTOCOL}[0] $project_id/$health_check 1>/dev/null
        health_check_type="google_compute_health_check"
    fi

    export backend_name=$(cat terraform.tfstate | jq -r '.resources[] | select(.type == "google_compute_region_backend_service") | .instances[].attributes.name')
    export zone=$(cat terraform.tfstate | jq -r '.resources[] | select(.type == "google_compute_region_backend_service") | .instances[].attributes.backend[].group | split("/")[-3]' | sort -u)
    export protocol=$(cat terraform.tfstate | jq -r '.resources[] | select(.type == "google_compute_region_backend_service") | .instances[].attributes.protocol')
    if [ "$protocol" == "TCP" ]; then # 與預設值相同，則不顯示
        export protocol="default_setting"
    fi

    export network=$(cat terraform.tfstate | jq -r '.resources[] | select(.type == "google_compute_region_backend_service") | .instances[].attributes.network' | sed 's/.*networks\/\([^\/]*\).*/\1/')

    export backends=$(
        cat terraform.tfstate | jq -r '.resources[] | select(.type == "google_compute_region_backend_service") | .instances[].attributes.backend[] |
    {group: (.group | sub(".*/instanceGroups/"; "")), description, failover}' |
            sed '/"description": "",/d;/"failover": false/d' | sed 's/}$/},/' | sed '$ s/.$//'
    )

    export logging=$(cat terraform.tfstate | jq -r '.resources[] | select(.type == "google_compute_region_backend_service") | .instances[].attributes.log_config[].enable')
    if [ "$logging" == false ] || [ "$logging" == '' ]; then # 與預設值相同，則不顯示
        export logging="default_setting"
    fi

    export connection_draining_timeout_sec=$(cat terraform.tfstate | jq -r '.resources[] | select(.type == "google_compute_region_backend_service") | .instances[].attributes.connection_draining_timeout_sec')
    if [ "$connection_draining_timeout_sec" == "300" ]; then # 與預設值相同，則不顯示
        export connection_draining_timeout_sec="default_setting"
    fi

    # ========================================
    # google_compute_region_health_check / google_compute_health_check
    export health_check_name=$(cat terraform.tfstate | jq -r '.resources[] | select(.type == "'${health_check_type}'") | .instances[].attributes.name')

    if [ "$health_check_state" == "region" ]; then
        export health_check_region=true
    else
        export health_check_region=false
    fi

    export health_check_description=$(cat terraform.tfstate | jq -r '.resources[] | select(.type == "'${health_check_type}'") | .instances[].attributes.description')
    if [ "$health_check_description" == "" ]; then # 與預設值相同，則不顯示
        export health_check_description="default_setting"
    fi

    export health_check_protocol=$(cat terraform.tfstate | jq -r '.resources[] | select(.type == "'${health_check_type}'") | .instances[].attributes.type')
    case $health_check_protocol in
    HTTP)
        export health_check_port=$(cat terraform.tfstate | jq -r '.resources[] | select(.type == "'${health_check_type}'") | .instances[].attributes.http_health_check[].port')

        export health_check_proxy_header=$(cat terraform.tfstate | jq -r '.resources[] | select(.type == "'${health_check_type}'") | .instances[].attributes.http_health_check[].proxy_header')
        if [ "$health_check_proxy_header" == "NONE" ]; then # 與預設值相同，則不顯示
            export health_check_proxy_header="default_setting"
        fi

        export health_check_request_path=$(cat terraform.tfstate | jq -r '.resources[] | select(.type == "'${health_check_type}'") | .instances[].attributes.http_health_check[].request_path')
        if [ "$health_check_request_path" == "/" ]; then # 與預設值相同，則不顯示
            export health_check_request_path="default_setting"
        fi

        export health_check_response=$(cat terraform.tfstate | jq -r '.resources[] | select(.type == "'${health_check_type}'") | .instances[].attributes.http_health_check[].response')
        if [ "$health_check_response" == "" ]; then # 與預設值相同，則不顯示
            export health_check_response="default_setting"
        fi

        export http_host=$(cat terraform.tfstate | jq -r '.resources[] | select(.type == "'${health_check_type}'") | .instances[].attributes.http_health_check[].host')
        if [ "$http_host" == "" ]; then # 與預設值相同，則不顯示
            export http_host="default_setting"
        fi
        ;;
    TCP)
        export health_check_port=$(cat terraform.tfstate | jq -r '.resources[] | select(.type == "'${health_check_type}'") | .instances[].attributes.tcp_health_check[].port')

        export health_check_proxy_header=$(cat terraform.tfstate | jq -r '.resources[] | select(.type == "'${health_check_type}'") | .instances[].attributes.tcp_health_check[].proxy_header')
        if [ "$health_check_proxy_header" == "NONE" ]; then # 與預設值相同，則不顯示
            export health_check_proxy_header="default_setting"
        fi

        export health_check_request_path=$(cat terraform.tfstate | jq -r '.resources[] | select(.type == "'${health_check_type}'") | .instances[].attributes.tcp_health_check[].request')
        if [ "$health_check_request_path" == "" ]; then # 與預設值相同，則不顯示
            export health_check_request_path="default_setting"
        fi

        export health_check_response=$(cat terraform.tfstate | jq -r '.resources[] | select(.type == "'${health_check_type}'") | .instances[].attributes.tcp_health_check[].response')
        if [ "$health_check_response" == "" ]; then # 與預設值相同，則不顯示
            export health_check_response="default_setting"
        fi

        export http_host="default_setting"
        ;;
    esac

    export health_check_logging=$(cat terraform.tfstate | jq -r '.resources[] | select(.type == "'${health_check_type}'") | .instances[].attributes.log_config[].enable')

    export check_interval_sec=$(cat terraform.tfstate | jq -r '.resources[] | select(.type == "'${health_check_type}'") | .instances[].attributes.check_interval_sec')
    if [ "$check_interval_sec" == 5 ]; then # 與預設值相同，則不顯示
        export check_interval_sec="default_setting"
    fi

    export timeout_sec=$(cat terraform.tfstate | jq -r '.resources[] | select(.type == "'${health_check_type}'") | .instances[].attributes.timeout_sec')
    if [ "$timeout_sec" == 5 ]; then # 與預設值相同，則不顯示
        export timeout_sec="default_setting"
    fi

    export healthy_threshold=$(cat terraform.tfstate | jq -r '.resources[] | select(.type == "'${health_check_type}'") | .instances[].attributes.healthy_threshold')
    if [ "$healthy_threshold" == 2 ]; then # 與預設值相同，則不顯示
        export healthy_threshold="default_setting"
    fi

    export unhealthy_threshold=$(cat terraform.tfstate | jq -r '.resources[] | select(.type == "'${health_check_type}'") | .instances[].attributes.unhealthy_threshold')
    if [ "$unhealthy_threshold" == 2 ]; then # 與預設值相同，則不顯示
        export unhealthy_threshold="default_setting"
    fi

    # ========================================
    # google_compute_forwarding_rule

    frontend_names=() # 清除避免重複儲存
    frontend_output=$(gcloud compute forwarding-rules list --project ${project_id} --filter="${backend_service_name}" --format="csv(NAME,IP_ADDRESS)")
    frontend_output=$(echo "$frontend_output" | sed '1d') # 移除標題列
    IFS=$'\n' read -rd '' -a frontend_array <<<"$frontend_output"

    echo "resource \"google_compute_forwarding_rule\" \"frontend\" {" >>main.tf
    echo " for_each = toset([" >>main.tf

    for frontend in "${frontend_array[@]}"; do
        export frontend_name=$(echo $frontend | cut -d "," -f 1)
        frontend_names+=("\"$frontend_name\"")
    done

    frontend_names_str=$(
        IFS=,
        echo "${frontend_names[*]}" | sed 's/,$//'
    )

    echo "  $frontend_names_str" >>main.tf
    echo '])' >>main.tf
    echo '}' >>main.tf

    for frontend in "${frontend_array[@]}"; do
        export frontend_name=$(echo $frontend | cut -d "," -f 1)
        terraform import "google_compute_forwarding_rule.frontend[\"$frontend_name\"]" $project_id/$backend_service_region/$frontend_name 1>/dev/null
    done

    # ========================================
    # google_compute_address

    echo "resource \"google_compute_address\" \"internal-address\" {" >>main.tf
    echo " for_each = toset([" >>main.tf

    frontend_names=() # 清除避免重複儲存
    for frontend in "${frontend_array[@]}"; do
        export frontend_name=$(echo $frontend | cut -d "," -f 1)
        frontend_names+=("\"$frontend_name\"")
    done

    frontend_names_str=$(
        IFS=,
        echo "${frontend_names[*]}" | sed 's/,$//'
    )

    echo "  $frontend_names_str" >>main.tf
    echo '])' >>main.tf
    echo '}' >>main.tf

    for frontend in "${frontend_array[@]}"; do
        export frontend_name=$(echo $frontend | cut -d "," -f 1)
        export internal_ip_address=$(echo $frontend | cut -d "," -f 2)
        export internal_ip_address_name=$(gcloud compute addresses list --project ${project_id} --filter="ADDRESS:(${internal_ip_address})" --format="value(NAME)")
        if [ "$internal_ip_address_name" != "" ]; then
            terraform import "google_compute_address.internal-address[\"$frontend_name\"]" $project_id/$backend_service_region/$internal_ip_address_name 1>/dev/null
        fi
    done

    # ========================================
    forwarding_rules=""
    for row in $(cat terraform.tfstate | jq -c '.resources[] | select(.type == "google_compute_forwarding_rule") | .instances[]'); do
        name=$(echo "${row}" | jq -r '.attributes.name')

        description=$(echo "${row}" | jq -r '.attributes.description')
        if [ "${description}" == "" ]; then # 與預設值相同，則不顯示
            description="default_setting"
        fi

        if [ -z "${network_project_id}" ]; then
            network_project_id=$(echo "${row}" | jq -r '.attributes.subnetwork' | sed -n 's/.*projects\/\([^\/]*\).*/\1/p')
            if [ "${network_project_id}" != "${project_id}" ]; then
                network_project_id="default_setting"
            fi
        fi

        network=$(echo "${row}" | jq -r '.attributes.network' | sed 's/.*networks\/\([^\/]*\).*/\1/')
        subnetwork=$(echo "${row}" | jq -r '.attributes.subnetwork' | sed 's/.*subnetworks\/\([^\/]*\).*/\1/')
        internal_ip_address=$(echo "${row}" | jq -r '.attributes.ip_address')
        export internal_ip_address_name=$(gcloud compute addresses list --project ${project_id} --filter="ADDRESS:(${internal_ip_address})" --format="value(NAME)")

        ip_version=$(echo "${row}" | jq -r '.attributes.ip_version')
        if [ "${ip_version}" == "IPV4" ]; then # 與預設值相同，則不顯示
            ip_version="default_setting"
        fi

        global_access=$(echo "${row}" | jq -r '.attributes.allow_global_access')
        if [ "${global_access}" == false ]; then # 與預設值相同，則不顯示
            global_access="default_setting"
        fi

        all_ports=$(echo "${row}" | jq -r '.attributes.all_ports')
        if [ "${all_ports}" == false ]; then # 與預設值相同，則不顯示
            all_ports="default_setting"
        fi

        ports=$(echo "${row}" | jq -r '.attributes.ports | map(tonumber)')
        if [ "${ports}" == "[]" ]; then # 與預設值相同，則不顯示
            ports="default_setting"
        fi

        # 將格式化後的 forwarding_rules 代碼添加到變數中
        forwarding_rules+="  ${name} = {\n"
        forwarding_rules+="    description = \"${description}\"\n"
        forwarding_rules+="    network_project_id = \"${network_project_id}\"\n"
        forwarding_rules+="    network = \"${network}\"\n"
        forwarding_rules+="    subnetwork = \"${subnetwork}\"\n"
        forwarding_rules+="    internal_ip_address_name = \"${internal_ip_address_name}\"\n"
        forwarding_rules+="    internal_ip_address = \"${internal_ip_address}\"\n"
        forwarding_rules+="    global_access = ${global_access}\n"
        forwarding_rules+="    all_ports = ${all_ports}\n"
        forwarding_rules+="    ports = ${ports}\n"
        forwarding_rules+="  },\n"
    done

    export forwarding_rules=$(echo -e "${forwarding_rules}")

    rm -rf *.tf .terraform*
    rm -rf terraform.tfstate.backup .terraform* .terragrunt-cache
    envsubst <../../../scripts/lb-internal-template >terragrunt.hcl

    # 移除與預設值相同的參數
    awk '!/default_setting/' terragrunt.hcl >temp_file && mv temp_file terragrunt.hcl

    echo "yes" | terragrunt plan

    rm -rf terraform.tfstate terraform.tfstate.backup .terraform* .terragrunt-cache

    terragrunt hclfmt

    cd ../../../scripts

done <<<"$(gcloud compute backend-services list --project ${project_id} --filter="NOT BACKENDS ~ k8s AND INTERNAL AND NOT INTERNAL_MANAGED" --format="value(NAME,REGION,health_checks,PROTOCOL)")"
