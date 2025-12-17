#!/bin/bash

# --- 定義顏色與樣式 ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # 無顏色 (Reset)

# --- 標題裝飾 ---
echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}${BOLD}   🚀 Grafana Alloy 配置自動產生器 (Debian)   ${NC}"
echo -e "${BLUE}================================================${NC}"

# 檢查健康狀況的函式
check_health() {
    local name=$1
    local url=$2
    local user=$3
    local pass=$4

    echo -e "\n${CYAN}🔍 正在檢查 $name 連線狀態...${NC}"
    echo -e "   URL: $url"

    local status_code
    status_code=$(curl -s -o /dev/null -w "%{http_code}" -u "$user:$pass" --connect-timeout 5 "$url")
    
    if [[ "$status_code" == "200" || "$status_code" == "204" ]]; then
        echo -e "   ${GREEN}✅ $name 連線成功！${NC}"
        return 0
    elif [[ "$status_code" == "405" ]]; then
        echo -e "   ${YELLOW}⚠️  $name 回傳 405 (Method Not Allowed)。${NC}"
        echo -e "      這在 Push API 是正常的，視為連線成功。"
        return 0
    else
        echo -e "   ${RED}❌ $name 連線失敗。HTTP 狀態碼: $status_code${NC}"
        echo -e "      請檢查 URL 格式或帳號密碼是否正確。"
        return 1
    fi
}

# --- 互動式輸入 ---

echo -e "\n${BOLD}📊 [1/2] Prometheus 設定 (Metrics)${NC}"
echo -en "${YELLOW}👉 輸入 Remote Write URL: ${NC}"; read PROM_URL
echo -en "${YELLOW}👉 輸入 Username: ${NC}"; read PROM_USER
echo -en "${YELLOW}👉 輸入 Password: ${NC}"; read -s PROM_PASS
echo -e "\n"

echo -e "${BOLD}📝 [2/2] Loki 設定 (Logs)${NC}"
echo -en "${YELLOW}👉 輸入 Push URL: ${NC}"; read LOKI_URL
echo -en "${YELLOW}👉 輸入 Username: ${NC}"; read LOKI_USER
echo -en "${YELLOW}👉 輸入 Password: ${NC}"; read -s LOKI_PASS
echo -e "\n"

# --- 執行驗證 ---

echo -e "${BLUE}------------------------------------------------${NC}"
check_health "Prometheus" "$PROM_URL" "$PROM_USER" "$PROM_PASS" || { echo -e "\n${RED}🛑 終止執行：Prometheus 驗證失敗。${NC}"; exit 1; }
check_health "Loki" "$LOKI_URL" "$LOKI_USER" "$LOKI_PASS" || { echo -e "\n${RED}🛑 終止執行：Loki 驗證失敗。${NC}"; exit 1; }
echo -e "${BLUE}------------------------------------------------${NC}"

# --- 產生設定檔 ---

TEMPLATE_FILE="./alloy_templates/config_template.alloy"
OUTPUT_FILE="./config.alloy"

if [ ! -f "$TEMPLATE_FILE" ]; then
    echo -e "\n${RED}❌ 錯誤: 找不到模板檔案 $TEMPLATE_FILE${NC}"
    exit 1
fi

echo -e "\n${CYAN}🛠️  正在產生 $OUTPUT_FILE...${NC}"

# 安全轉義函式
escape_sed() {
    echo "$1" | sed 's/|/\\|/g'
}

PROM_URL_SAFE=$(escape_sed "$PROM_URL")
PROM_USER_SAFE=$(escape_sed "$PROM_USER")
PROM_PASS_SAFE=$(escape_sed "$PROM_PASS")
LOKI_URL_SAFE=$(escape_sed "$LOKI_URL")
LOKI_USER_SAFE=$(escape_sed "$LOKI_USER")
LOKI_PASS_SAFE=$(escape_sed "$LOKI_PASS")

# 複製並替換
cp "$TEMPLATE_FILE" "$OUTPUT_FILE"
sed -i "s|__PROMETHEUS_URL__|$PROM_URL_SAFE|g" "$OUTPUT_FILE"
sed -i "s|__PROMETHEUS_USER__|$PROM_USER_SAFE|g" "$OUTPUT_FILE"
sed -i "s|__PROMETHEUS_PASS__|$PROM_PASS_SAFE|g" "$OUTPUT_FILE"
sed -i "s|__LOKI_URL__|$LOKI_URL_SAFE|g" "$OUTPUT_FILE"
sed -i "s|__LOKI_USER__|$LOKI_USER_SAFE|g" "$OUTPUT_FILE"
sed -i "s|__LOKI_PASS__|$LOKI_PASS_SAFE|g" "$OUTPUT_FILE"

echo -e "${GREEN}${BOLD}✨ 大功告成！設定檔已成功產生。${NC}"
echo -e "${CYAN}💡 現在您可以執行: ${NC}${BOLD}docker-compose up -d${NC}\n"