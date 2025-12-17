# Grafana Alloy Deployment on Debian

本專案提供在 Debian VM 上透過 Docker Compose 部署 Grafana Alloy 的自動化配置與執行方案。
主要功能包含：
- 自動化產生設定檔 (`config.alloy`)
- 整合 Prometheus (Metrics) 與 Loki (Logs)
- 監控主機資源 (CPU, RAM, Disk, Network)
- 監控 Docker 容器資源與日誌

## 快速開始

### 1. 產生設定檔

執行 `gen_alloy_config.sh` 腳本，依照提示輸入 Prometheus 與 Loki 的連線資訊。
腳本會自動檢查連線健康狀態，驗證通過後即產生 `config.alloy`。

```bash
chmod +x gen_alloy_config.sh
./gen_alloy_config.sh
```

### 2. 啟動服務

設定檔產生後，使用 Docker Compose 啟動服務。

```bash
docker-compose up -d
```

### 3. 驗證狀態

- **Alloy UI**: 瀏覽器訪問 `http://<您的IP>:12345` 查看 Alloy 運行狀態。
- **Logs**: 檢查 Alloy 容器日誌確認有無錯誤。
  ```bash
  docker-compose logs -f alloy
  ```

## 檔案說明

- `docker-compose.yml`: 定義 Alloy 服務與掛載路徑 (包含 host filesystem 與 docker socket)。
- `alloy_templates/config_template.alloy`: 設定檔模板。
- `gen_alloy_config.sh`: 設定檔產生器腳本。
