# GripMind Deployment Guide

本文件說明 GripMind 後端服務的部署方式，包括 Flask Backend、systemd 常駐服務、Nginx Reverse Proxy、Cloudflare Tunnel、自訂網域，以及 Ollama 本地 AI 服務整合。

本專案目前使用的正式 API Base URL：

```text
https://gripmind.hasaki.idv.tw/api/v1
```

---

## 1. Deployment Overview

GripMind 的部署架構如下：

```text
Internet
  |
  v
Cloudflare Tunnel
  |
  v
Nginx Reverse Proxy
  |
  v
Flask Backend API
  |
  +--> Local Data Files
  |
  +--> Ollama AI Server
```

主要組成：

| Component         | Description                                    |
| ----------------- | ---------------------------------------------- |
| Flask Backend     | 提供 RESTful API、LINE Login callback、AI analysis |
| systemd           | 管理 Flask 後端常駐服務                                |
| Nginx             | 將 HTTP request 反向代理至 Flask                     |
| Cloudflare Tunnel | 將本機服務安全地公開到外部網域                                |
| Ollama            | 提供本地或私有伺服器 AI 推論服務                             |
| LINE Login        | 用於裝置與 LINE 使用者綁定                               |

---

## 2. Server Environment

建議部署環境：

```text
OS: Linux
Python: 3.10+
Web Framework: Flask
Reverse Proxy: Nginx
Process Manager: systemd
Tunnel: Cloudflare Tunnel
AI Runtime: Ollama
```

本專案範例路徑：

```text
/home/justus/OOP/gripmind
```

如果你的專案路徑不同，請自行替換後續指令中的路徑。

---

## 3. Project Directory Example

建議後端 repo 結構如下：

```text
gripmind/
├── app.py
├── requirements.txt
├── .env
├── api/
├── data/
├── services/
└── ...
```

若 iOS App 與 Flask Backend 在同一個 repo，建議將目錄明確分離，例如：

```text
gripmind/
├── backend/
│   ├── app.py
│   ├── requirements.txt
│   └── ...
├── ios/
│   ├── GripMind/
│   └── GripMind.xcodeproj
├── README.md
└── docs/
```

目前若專案仍是混合結構，也應至少在 README 中說明 iOS 與後端的分工。

---

## 4. Environment Variables

Flask 後端建議使用 `.env` 管理環境變數。

範例：

```env
URL=https://gripmind.hasaki.idv.tw

LINE_CHANNEL_ID=your_line_channel_id
LINE_CHANNEL_SECRET=your_line_channel_secret

SECRET_KEY=your_flask_secret_key

OLLAMA_BASE_URL=http://127.0.0.1:11434
OLLAMA_MODEL=qwen2.5:7b
OLLAMA_TIMEOUT=120
```

若 Ollama 跑在另一台 Linux 主機或私有網路 IP，可改成：

```env
OLLAMA_BASE_URL=http://100.76.39.84:11434
```

注意：

```env
URL=https://gripmind.hasaki.idv.tw
```

此設定會影響 LINE Login Callback URL 產生方式。

LINE Developers 後台的 Callback URL 需設定為：

```text
https://gripmind.hasaki.idv.tw/callback
```

---

## 5. Python Virtual Environment

進入專案資料夾：

```bash
cd /home/justus/OOP/gripmind
```

建立虛擬環境：

```bash
python3 -m venv venv
```

啟用虛擬環境：

```bash
source venv/bin/activate
```

安裝 dependencies：

```bash
pip install -r requirements.txt
```

確認 Flask 可正常啟動：

```bash
python app.py
```

若後端使用 Gunicorn，則可測試：

```bash
gunicorn -w 2 -b 127.0.0.1:5001 app:app
```

---

## 6. Flask Backend systemd Service

為了讓 Flask 後端在伺服器重開機後自動啟動，建議使用 systemd 管理。

建立 service 檔：

```bash
sudo nano /etc/systemd/system/gripmind.service
```

範例設定：

```ini
[Unit]
Description=GripMind Flask Backend
After=network-online.target
Wants=network-online.target

[Service]
User=justus
Group=justus
WorkingDirectory=/home/justus/OOP/gripmind
EnvironmentFile=/home/justus/OOP/gripmind/.env
ExecStart=/home/justus/OOP/gripmind/venv/bin/python app.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

若你使用 Gunicorn，`ExecStart` 可改成：

```ini
ExecStart=/home/justus/OOP/gripmind/venv/bin/gunicorn -w 2 -b 127.0.0.1:5001 app:app
```

注意：`ExecStart` 的 Python 路徑必須真的存在。

可用以下指令確認：

```bash
ls -l /home/justus/OOP/gripmind/venv/bin/python
```

如果你的虛擬環境資料夾叫 `.venv`，則路徑應改成：

```text
/home/justus/OOP/gripmind/.venv/bin/python
```

如果你的虛擬環境資料夾叫 `venv`，則路徑應改成：

```text
/home/justus/OOP/gripmind/venv/bin/python
```

這是常見錯誤來源。

---

### 啟用 systemd service

重新載入 systemd：

```bash
sudo systemctl daemon-reload
```

啟用開機自動啟動：

```bash
sudo systemctl enable gripmind
```

啟動服務：

```bash
sudo systemctl start gripmind
```

查看狀態：

```bash
sudo systemctl status gripmind
```

查看 log：

```bash
journalctl -u gripmind -f
```

---

## 7. Nginx Reverse Proxy

建議使用 Nginx 將外部 HTTP request 轉發到 Flask Backend。

建立 Nginx 設定：

```bash
sudo nano /etc/nginx/conf.d/gripmind.conf
```

範例：

```nginx
server {
    listen 80;
    server_name gripmind.hasaki.idv.tw;

    location / {
        proxy_pass http://127.0.0.1:5001;

        proxy_http_version 1.1;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        proxy_read_timeout 180;
        proxy_connect_timeout 180;
        proxy_send_timeout 180;
    }
}
```

如果 Flask Backend 直接跑在 5000 port，則改成：

```nginx
proxy_pass http://127.0.0.1:5000;
```

測試 Nginx 設定：

```bash
sudo nginx -t
```

重新載入 Nginx：

```bash
sudo systemctl reload nginx
```

本機測試：

```bash
curl -H "Host: gripmind.hasaki.idv.tw" http://127.0.0.1/api/v1/health
```

預期回應：

```json
{
  "service": "GripMind API v1",
  "status": "ok"
}
```

---

## 8. Cloudflare Tunnel

GripMind 使用 Cloudflare Tunnel 將內部服務公開到：

```text
https://gripmind.hasaki.idv.tw
```

---

### 8.1 config.yml 方式

如果 cloudflared 使用 `/etc/cloudflared/config.yml`，範例設定如下：

```yaml
tunnel: your-tunnel-id
credentials-file: /home/justus/.cloudflared/your-tunnel-id.json

ingress:
  - hostname: gripmind.hasaki.idv.tw
    service: http://127.0.0.1:80

  - service: http_status:404
```

如果同一個 tunnel 同時服務多個 hostname，可寫成：

```yaml
tunnel: your-tunnel-id
credentials-file: /home/justus/.cloudflared/your-tunnel-id.json

ingress:
  - hostname: food-api.hasaki.idv.tw
    service: http://127.0.0.1:5000

  - hostname: gripmind.hasaki.idv.tw
    service: http://127.0.0.1:80

  - service: http_status:404
```

注意：`ingress` 規則會由上往下匹配，最後必須保留：

```yaml
- service: http_status:404
```

---

### 8.2 Token service 方式

如果 systemd 裡的 cloudflared 是用 token 啟動，例如：

```ini
ExecStart=/usr/bin/cloudflared --no-autoupdate tunnel run --token <TOKEN>
```

這種方式可能不會讀取 `/etc/cloudflared/config.yml`。

若要使用 `config.yml` 管理 ingress，service 應改成類似：

```ini
ExecStart=/usr/bin/cloudflared --config /etc/cloudflared/config.yml tunnel run
```

否則你在 `/etc/cloudflared/config.yml` 修改 ingress 後，實際服務可能不會套用。

---

### 8.3 檢查 ingress 規則

檢查某個網址會匹配哪條 ingress：

```bash
cloudflared tunnel ingress rule https://gripmind.hasaki.idv.tw
```

如果顯示匹配到：

```text
service: http_status:404
```

代表 Cloudflare Tunnel 沒有正確讀到 `gripmind.hasaki.idv.tw` 的規則，或 service 使用的 config 不是你正在編輯的檔案。

---

### 8.4 重啟 cloudflared

```bash
sudo systemctl restart cloudflared
```

查看 log：

```bash
journalctl -u cloudflared -f
```

---

## 9. Ollama AI Server

GripMind 的 AI 訓練回饋由後端呼叫 Ollama API 產生。

---

### 9.1 安裝與啟動 Ollama

確認 Ollama 是否正常：

```bash
ollama list
```

確認 API 是否可存取：

```bash
curl http://127.0.0.1:11434/api/version
```

確認模型列表：

```bash
curl http://127.0.0.1:11434/api/tags
```

---

### 9.2 Pull Model

範例：

```bash
ollama pull qwen2.5:7b
```

確認模型名稱：

```bash
ollama list
```

`.env` 中的模型名稱必須與 `ollama list` 顯示的名稱一致。

例如：

```env
OLLAMA_MODEL=qwen2.5:7b
```

不要寫成不存在的名稱，例如：

```env
OLLAMA_MODEL=qwen2.5:7b-instruct
```

除非該模型真的存在於 `ollama list`。

---

### 9.3 測試 Ollama Chat API

```bash
curl http://127.0.0.1:11434/api/chat \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen2.5:7b",
    "messages": [
      {
        "role": "user",
        "content": "請用繁體中文簡短說明 GripMind 是什麼"
      }
    ],
    "stream": false
  }'
```

若 Ollama 在另一台機器：

```bash
curl http://100.76.39.84:11434/api/tags
```

---

### 9.4 常見 Ollama 錯誤

#### 404 Not Found

如果後端回傳：

```text
Ollama API 回傳錯誤：404 Client Error: Not Found
```

可能原因：

1. `OLLAMA_BASE_URL` 指錯服務
2. Ollama 沒有監聽該 IP 或 port
3. 呼叫的 endpoint 不存在
4. 模型名稱不存在

檢查：

```bash
curl http://127.0.0.1:11434/api/tags
ollama list
cat .env
```

#### Model Not Found

若回傳 model not found，請確認：

```bash
ollama list
```

並修正：

```env
OLLAMA_MODEL=<actual_model_name>
```

---

## 10. LINE Login Production Settings

LINE Login 需要在 LINE Developers 後台設定 Callback URL。

正式環境 Callback URL：

```text
https://gripmind.hasaki.idv.tw/callback
```

Flask 後端 `.env` 應設定：

```env
URL=https://gripmind.hasaki.idv.tw
```

iOS App 首次綁定會開啟：

```text
https://gripmind.hasaki.idv.tw/login?device_id=<DEVICE_ID>&client=ios&app_callback_url=gripmind://bind-success
```

完成 LINE Login 後，後端會導回：

```text
gripmind://bind-success?status=success&device_id=<DEVICE_ID>
```

iOS App 需要在 Xcode 設定 URL Scheme：

```text
gripmind
```

設定位置：

```text
Target → Info → URL Types
```

---

## 11. No-cache Headers

因為握力紀錄會頻繁更新，建議 Flask API 加上 no-cache headers，避免 App 或代理層拿到舊資料。

範例：

```python
@api_v1.after_request
def add_no_cache_headers(response):
    response.headers["Cache-Control"] = "no-store, no-cache, must-revalidate, max-age=0"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "0"
    return response
```

iOS App 端也可使用 `_refresh` query parameter 避免快取：

```text
/devices/{device_id}/records?limit=100&_refresh=<UUID>
```

---

## 12. Health Check

後端部署完成後，請先檢查：

```bash
curl https://gripmind.hasaki.idv.tw/api/v1/health
```

預期回應：

```json
{
  "service": "GripMind API v1",
  "status": "ok"
}
```

也可以從伺服器本機測試 Nginx：

```bash
curl -H "Host: gripmind.hasaki.idv.tw" http://127.0.0.1/api/v1/health
```

---

## 13. Full Deployment Checklist

### Flask Backend

```bash
cd /home/justus/OOP/gripmind
source venv/bin/activate
pip install -r requirements.txt
python app.py
```

### systemd

```bash
sudo systemctl daemon-reload
sudo systemctl enable gripmind
sudo systemctl restart gripmind
sudo systemctl status gripmind
journalctl -u gripmind -f
```

### Nginx

```bash
sudo nginx -t
sudo systemctl reload nginx
curl -H "Host: gripmind.hasaki.idv.tw" http://127.0.0.1/api/v1/health
```

### Cloudflare Tunnel

```bash
cloudflared tunnel ingress rule https://gripmind.hasaki.idv.tw
sudo systemctl restart cloudflared
journalctl -u cloudflared -f
```

### Ollama

```bash
ollama list
curl http://127.0.0.1:11434/api/tags
```

### Public API

```bash
curl https://gripmind.hasaki.idv.tw/api/v1/health
curl https://gripmind.hasaki.idv.tw/api/v1/devices/device_demo_001/summary
curl "https://gripmind.hasaki.idv.tw/api/v1/devices/device_demo_001/records?limit=100"
curl -X POST https://gripmind.hasaki.idv.tw/api/v1/devices/device_demo_001/analysis
```

---

## 14. Troubleshooting

### 14.1 systemd: status=203/EXEC

錯誤範例：

```text
Failed at step EXEC spawning /home/justus/OOP/gripmind/.venv/bin/python: No such file or directory
```

原因：

`ExecStart` 指到不存在的 Python 路徑。

解法：

```bash
ls -l /home/justus/OOP/gripmind/venv/bin/python
ls -l /home/justus/OOP/gripmind/.venv/bin/python
```

確認實際虛擬環境資料夾名稱後，修正：

```bash
sudo nano /etc/systemd/system/gripmind.service
sudo systemctl daemon-reload
sudo systemctl restart gripmind
```

---

### 14.2 Cloudflare Tunnel always returns 404

可能原因：

1. ingress 沒有設定 `gripmind.hasaki.idv.tw`
2. cloudflared service 沒有使用你編輯的 config
3. hostname 沒有正確指向 tunnel
4. ingress 順序錯誤，提前進入 `http_status:404`

檢查：

```bash
cloudflared tunnel ingress rule https://gripmind.hasaki.idv.tw
sudo cat /etc/cloudflared/config.yml
sudo systemctl cat cloudflared
```

如果 systemd 使用 token 啟動：

```text
cloudflared tunnel run --token ...
```

則 `/etc/cloudflared/config.yml` 可能不會生效。

---

### 14.3 iOS App can access health but records do not refresh

可能原因：

1. API response 被快取
2. iOS 使用舊資料
3. Flask 沒有 no-cache header
4. ViewModel 沒有真正重新呼叫 API

建議：

* 後端加 no-cache headers
* iOS request 使用 `_refresh=<UUID>`
* iOS request 使用 `reloadIgnoringLocalCacheData`
* App 端下拉刷新時強制重新呼叫 API

---

### 14.4 LINE Login does not return to iOS App

檢查：

1. Xcode 是否設定 URL Scheme：

```text
gripmind
```

2. 後端是否導回：

```text
gripmind://bind-success
```

3. `/login` 是否帶入：

```text
client=ios
app_callback_url=gripmind://bind-success
```

4. LINE Developers Callback URL 是否設定：

```text
https://gripmind.hasaki.idv.tw/callback
```

---

### 14.5 Ollama API returns 404

檢查：

```bash
curl http://127.0.0.1:11434/api/tags
ollama list
cat .env
```

確認：

```env
OLLAMA_BASE_URL=http://127.0.0.1:11434
OLLAMA_MODEL=<model_name_from_ollama_list>
```

---

## 15. Production Improvements

目前部署方式適合作為 Prototype。若要正式產品化，建議加入：

* HTTPS-only policy
* API authentication
* User session management
* Device ownership validation
* Database migration
* Structured logging
* Rate limiting
* Backup policy
* CI/CD pipeline
* Monitoring and alerting
* Secret management
* Better error response format

---

## 16. Summary

GripMind 的部署流程涵蓋：

* Flask API service
* systemd process management
* Nginx reverse proxy
* Cloudflare Tunnel domain exposure
* LINE Login callback
* iOS Custom URL Scheme
* Ollama local AI integration

這使 GripMind 不只是單純的 iOS App Demo，而是一個具備完整前後端整合與實際部署能力的系統 Prototype。
