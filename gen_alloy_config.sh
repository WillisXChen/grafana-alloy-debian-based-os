#!/bin/bash

# --- Color Definitions ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color (Reset)

# --- Language Selection ---
echo -e "${CYAN}Language Selection / 語言選擇:${NC}"
echo -e "1) English"
echo -e "2) 繁體中文"
read -p "Please select (1-2): " LANG_CHOICE

if [[ "$LANG_CHOICE" == "2" ]]; then
    # Traditional Chinese Localization
    T_TITLE="🚀 Grafana Alloy 配置自動產生器"
    T_PROM_HEADER="📊 [1/2] Prometheus 設定 (Metrics)"
    T_LOKI_HEADER="📝 [2/2] Loki 設定 (Logs)"
    T_PROM_URL="👉 Prometheus 端點網址 (例如 http://1.2.3.4:9090): "
    T_LOKI_URL="👉 Loki 端點網址 (例如 http://1.2.3.4:3100): "
    T_USER="👤 輸入 Username: "
    T_PASS="🔑 輸入 Password: "
    T_CHECKING="🔍 正在自動偵測端點並檢查連線..."
    T_SUCCESS="✅ 連線成功！"
    T_WAIT_405="⚠️  回傳 405，視為 API 端點連通。"
    T_FAILED="❌ 連線失敗。HTTP 狀態碼: "
    T_ABORT="🛑 終止執行：驗證失敗。"
    T_GEN_START="🛠️  正在產生設定檔..."
    T_DONE="✨ 大功告成！設定檔已成功產生。"
    T_NEXT="💡 現在您可以執行: "
else
    # English Localization (Default)
    T_TITLE="🚀 Grafana Alloy Config Generator"
    T_PROM_HEADER="📊 [1/2] Prometheus Setup (Metrics)"
    T_LOKI_HEADER="📝 [2/2] Loki Setup (Logs)"
    T_PROM_URL="👉 Prometheus Endpoint (e.g., http://1.2.3.4:9090): "
    T_LOKI_URL="👉 Loki Endpoint (e.g., http://1.2.3.4:3100): "
    T_USER="👤 Enter Username: "
    T_PASS="🔑 Enter Password: "
    T_CHECKING="🔍 Auto-detecting endpoint and checking connection..."
    T_SUCCESS="✅ Connection successful!"
    T_WAIT_405="⚠️  Received 405, treating as API reachable."
    T_FAILED="❌ Connection failed. HTTP Status: "
    T_ABORT="🛑 Aborting: Validation failed."
    T_GEN_START="🛠️  Generating config file..."
    T_DONE="✨ Done! Config file generated successfully."
    T_NEXT="💡 You can now run: "
fi

# --- Header Display ---
echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}${BOLD}   $T_TITLE   ${NC}"
echo -e "${BLUE}================================================${NC}"

# --- Enhanced Health Check Function ---
check_health() {
    local type=$1 
    local raw_url=$2; local user=$3; local pass=$4
    
    # Use parameter expansion to remove trailing slash
    local base_url="${raw_url%/}"
    local test_url="$base_url"

    if [[ "$type" == "Prometheus" && ! "$base_url" =~ /-/healthy$ ]]; then
        test_url="$base_url/-/healthy"
    elif [[ "$type" == "Loki" && ! "$base_url" =~ /ready$ ]]; then
        test_url="$base_url/ready"
    fi

    echo -e "\n${CYAN}$T_CHECKING ($type)${NC}"
    echo -e "   Testing: $test_url"
    
    local status_code
    status_code=$(curl -s -o /dev/null -w "%{http_code}" -u "$user:$pass" --connect-timeout 5 "$test_url")
    
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

# --- Interactive Input ---
echo -e "\n${BOLD}$T_PROM_HEADER${NC}"
echo -en "${YELLOW}$T_PROM_URL${NC}"; read PROM_URL
echo -en "${YELLOW}$T_USER${NC}"; read PROM_USER
echo -en "${YELLOW}$T_PASS${NC}"; read -s PROM_PASS
echo -e ""

echo -e "\n${BOLD}$T_LOKI_HEADER${NC}"
echo -en "${YELLOW}$T_LOKI_URL${NC}"; read LOKI_URL
echo -en "${YELLOW}$T_USER${NC}"; read LOKI_USER
echo -en "${YELLOW}$T_PASS${NC}"; read -s LOKI_PASS
echo -e "\n"

# --- Execute Validation ---
echo -e "${BLUE}------------------------------------------------${NC}"
# Validation logic
check_health "Prometheus" "$PROM_URL" "$PROM_USER" "$PROM_PASS" || { echo -e "\n${RED}$T_ABORT${NC}"; exit 1; }
check_health "Loki" "$LOKI_URL" "$LOKI_USER" "$LOKI_PASS" || { echo -e "\n${RED}$T_ABORT${NC}"; exit 1; }
echo -e "${BLUE}------------------------------------------------${NC}"

# --- Configuration Generation ---
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
# Using | as delimiter to handle URLs safely
sed -i "s|__PROMETHEUS_URL__|$PROM_URL_SAFE|g" "$OUTPUT_FILE"
sed -i "s|__PROMETHEUS_USER__|$PROM_USER_SAFE|g" "$OUTPUT_FILE"
sed -i "s|__PROMETHEUS_PASS__|$PROM_PASS_SAFE|g" "$OUTPUT_FILE"
sed -i "s|__LOKI_URL__|$LOKI_URL_SAFE|g" "$OUTPUT_FILE"
sed -i "s|__LOKI_USER__|$LOKI_USER_SAFE|g" "$OUTPUT_FILE"
sed -i "s|__LOKI_PASS__|$LOKI_PASS_SAFE|g" "$OUTPUT_FILE"

echo -e "\n${GREEN}${BOLD}$T_DONE${NC}"
echo -e "${CYAN}$T_NEXT${NC}${BOLD}docker-compose up -d${NC}\n"