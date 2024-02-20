#! /bin/bash

PROJECT_ARRAY=(
    "<專案名稱>")

# 顏色設定
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
WHITE="\033[0m"

# 多線程數量設定 (請依照電腦性能調整)
JOB_COUNT=20

if [[ $1 != *keep* ]]; then
    if ! brew list | grep parallel 1>/dev/null; then
        read -r -e -p "本腳本需要安裝 parallel，請確認是否安裝並繼續執行？(Y/N)：" continue
        case $continue in
        Y | y)
            brew install parallel
            ;;
        N | n)
            exit
            ;;
        *)
            echo -e "\n${RED}無效參數 ($REPLY)，請重新輸入${WHITE}\n"
            exit
            ;;
        esac
    fi
fi

PS3='👆 請選擇要轉換的專案名稱(輸入開頭數字)：'
select PROJECT in "${PROJECT_ARRAY[@]}"; do
    case ${PROJECT} in
    "<專案名稱>")
        project_name="<專案名稱>"
        project_id="<專案ID>"
        region="<專案地區>"
        echo -e "\n${BLUE}選擇專案：${YELLOW}${project_name} ($project_id)${WHITE}\n"
        break
        ;;
    *)
        echo -e "\n${RED}無效參數 ($REPLY)，請重新輸入${WHITE}\n"
        ;;
    esac
done
