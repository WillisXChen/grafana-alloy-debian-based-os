#!/bin/bash

# --- 顏色定義 ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# --- 語言選擇 ---
echo -e "${CYAN}Language Selection / 語言選擇:${NC}"
echo -e "1) English"
echo -e "2) 繁體中文"
read -p "Please select (1-2): " LANG_CHOICE

if [[ "$LANG_CHOICE" == "2" ]]; then
    # 中文語系
    T_TITLE="🚀 Grafana Alloy 配置自動產生器"
    T_PROM_HEADER="📊 [1/2] Prometheus 設定 (Metrics)"
    T_LOKI_HEADER="📝 [2/2] Loki 設定 (Logs)"
    T_URL="👉 輸入 URL: "
    T_USER="👉 輸入 Username: "
    T_PASS="👉 輸入 Password: "
    T_CHECKING="🔍 正在檢查連線狀態..."
    T_SUCCESS="✅ 連線成功！"
    T_WAIT_405="⚠️  回傳 405，視為連線成功。"
    T_FAILED="❌ 連線失敗。HTTP 狀態碼: "
    T_ABORT="🛑 終止執行：驗證失敗。"
    T_GEN_START="🛠️  正在產生設定檔..."
    T_DONE="✨ 大功告成！設定檔已成功產生。"
    T_NEXT="💡 現在您可以執行: "
else
    # 英文語系 (Default)
    T_TITLE="🚀 Grafana Alloy Config Generator"
    T_PROM_HEADER="📊 [1/2] Prometheus Setup (Metrics)"
    T_LOKI_HEADER="📝 [2/2] Loki Setup (Logs)"
    T_URL="👉 Enter URL: "
    T_USER="👉 Enter Username: "
    T_PASS="👉 Enter Password: "
    T_CHECKING="🔍 Checking connection..."
    T_SUCCESS="✅ Connection successful!"
    T_WAIT_405="⚠️  Received 405, treating as success."
    T_FAILED="❌ Connection failed. HTTP Status: "
    T_ABORT="🛑 Aborting: Validation failed."
    T_GEN_START="🛠️  Generating config file..."
    T_DONE="✨ Done! Config file generated successfully."
    T_NEXT="💡 You can now run: "
fi

# --- 標題顯示 ---
echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}${BOLD}   $T_TITLE   ${NC}"
echo -e "${BLUE}================================================${NC}"

# --- 健康檢查函式 ---
check_health() {
    local name=$1; local url=$2; local user=$3; local pass=$4
    echo -e "\n${CYAN}$T_CHECKING ($name)${NC}"
    
    local status_code
    status_code=$(curl -s -o /dev/null -w "%{http_code}" -u "$user:$pass" --connect-timeout 5 "$url")
    
    if [[ "$status_code" == "200" || "$status_code" == "204" ]]; then
        echo -e "   ${GREEN}$T_SUCCESS${NC}"
        return 0
    elif [[ "$status_code" == "405" ]]; then
        echo -e "   ${YELLOW}$T_WAIT_405${NC}"
        return 0
    else
        echo -e "   ${RED}$T_FAILED $status_code${NC}"
        return 1
    fi
}

# --- 互動輸入 ---
echo -e "\n${BOLD}$T_PROM_HEADER${NC}"
echo -en "${YELLOW}$T_URL${NC}"; read PROM_URL
echo -en "${YELLOW}$T_USER${NC}"; read PROM_USER
echo -en "${YELLOW}$T_PASS${NC}"; read -s PROM_PASS
echo -e ""

echo -e "\n${BOLD}$T_LOKI_HEADER${NC}"
echo -en "${YELLOW}$T_URL${NC}"; read LOKI_URL
echo -en "${YELLOW}$T_USER${NC}"; read LOKI_USER
echo -en "${YELLOW}$T_PASS${NC}"; read -s LOKI_PASS
echo -e "\n"

# --- 執行驗證 ---
echo -e "${BLUE}------------------------------------------------${NC}"
check_health "Prometheus" "$PROM_URL" "$PROM_USER" "$PROM_PASS" || { echo -e "\n${RED}$T_ABORT${NC}"; exit 1; }
check_health "Loki" "$LOKI_URL" "$LOKI_USER" "$LOKI_PASS" || { echo -e "\n${RED}$T_ABORT${NC}"; exit 1; }
echo -e "${BLUE}------------------------------------------------${NC}"

# --- 產生設定檔 ---
TEMPLATE_FILE="./alloy_templates/config_template.alloy"
OUTPUT_FILE="./config.alloy"

if [ ! -f "$TEMPLATE_FILE" ]; then
    echo -e "\n${RED}Error: $TEMPLATE_FILE not found!${NC}"
    exit 1
fi

echo -e "\n$T_GEN_START"

escape_sed() { echo "$1" | sed 's/|/\\|/g'; }

PROM_URL_SAFE=$(escape_sed "$PROM_URL")
PROM_USER_SAFE=$(escape_sed "$PROM_USER")
PROM_PASS_SAFE=$(escape_sed "$PROM_PASS")
LOKI_URL_SAFE=$(escape_sed "$LOKI_URL")
LOKI_USER_SAFE=$(escape_sed "$LOKI_USER")
LOKI_PASS_SAFE=$(escape_sed "$LOKI_PASS")

cp "$TEMPLATE_FILE" "$OUTPUT_FILE"
sed -i "s|__PROMETHEUS_URL__|$PROM_URL_SAFE|g" "$OUTPUT_FILE"
sed -i "s|__PROMETHEUS_USER__|$PROM_USER_SAFE|g" "$OUTPUT_FILE"
sed -i "s|__PROMETHEUS_PASS__|$PROM_PASS_SAFE|g" "$OUTPUT_FILE"
sed -i "s|__LOKI_URL__|$LOKI_URL_SAFE|g" "$OUTPUT_FILE"
sed -i "s|__LOKI_USER__|$LOKI_USER_SAFE|g" "$OUTPUT_FILE"
sed -i "s|__LOKI_PASS__|$LOKI_PASS_SAFE|g" "$OUTPUT_FILE"

echo -e "\n${GREEN}${BOLD}$T_DONE${NC}"
echo -e "${CYAN}$T_NEXT${NC}${BOLD}docker-compose up -d${NC}\n"