#! /bin/bash

PROJECT_ARRAY=(
    "專案名稱")

# 顏色設定
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
WHITE="\033[0m"

PS3='👆 請選擇要轉換的專案名稱(輸入開頭數字)：'
select PROJECT in "${PROJECT_ARRAY[@]}"; do
    case ${PROJECT} in
    "專案名稱")
        echo -e "\n${BLUE}選擇專案：${YELLOW}${PROJECT}${WHITE}\n"
        project_name="專案名稱"
        project_id="專案ID"
        region="asia-east1"
        break
        ;;
    *)
        echo -e "\n${RED}無效參數 ($REPLY)，請重新輸入${WHITE}\n"
        ;;
    esac
done
