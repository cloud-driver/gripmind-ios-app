# Backend Requirements for GripMind iOS App

本文件說明 GripMind iOS App 所需的外部後端服務規格。

> 注意：本 repo 僅包含 iOS App 原始碼。
> Flask Backend、LINE Login Callback、Ollama AI 整合與伺服器部署不包含在此 repo 中。

GripMind iOS App 需要串接一個外部 Backend API，才能完成裝置綁定、握力紀錄查詢、目標握力更新與 AI 訓練回饋等功能。

---

## 1. Backend Role

外部後端在 GripMind 系統中負責：

1. 提供 RESTful API
2. 儲存與查詢裝置資料
3. 儲存與查詢握力紀錄
4. 管理使用者 Profile
5. 處理 LINE Login Callback
6. 將 LINE 使用者與 `device_id` 綁定
7. 提供目標握力更新 API
8. 呼叫 Ollama 產生 AI 訓練回饋
9. 回傳 iOS App 可解析的 JSON 格式資料

---

## 2. Expected Backend Base URL

iOS App 會透過 `APIClient.swift` 設定後端 API Base URL。

範例：

```swift
private let baseURL = "https://gripmind.hasaki.idv.tw/api/v1"
```

正式後端應提供：

```text
https://<BACKEND_DOMAIN>/api/v1
```

例如：

```text
https://gripmind.hasaki.idv.tw/api/v1
```

---

## 3. Required API Endpoints

iOS App 預期後端提供以下 endpoints：

| Method | Endpoint                               | Required | Purpose                   |
| ------ | -------------------------------------- | -------- | ------------------------- |
| GET    | `/api/v1/health`                       | Yes      | 檢查後端服務狀態                  |
| GET    | `/api/v1/devices/{device_id}/profile`  | Yes      | 查詢裝置 Profile 與綁定狀態        |
| GET    | `/api/v1/devices/{device_id}/summary`  | Yes      | 查詢今日握力摘要                  |
| GET    | `/api/v1/devices/{device_id}/records`  | Yes      | 查詢歷史握力紀錄                  |
| PATCH  | `/api/v1/devices/{device_id}/target`   | Yes      | 更新目標握力                    |
| POST   | `/api/v1/devices/{device_id}/analysis` | Yes      | 產生 AI 訓練回饋                |
| GET    | `/login`                               | Yes      | 開始 LINE Login 裝置綁定流程      |
| GET    | `/callback`                            | Yes      | LINE Login OAuth Callback |

---

## 4. Health Check API

### Request

```http
GET /api/v1/health
```

### Expected Response

```json
{
  "service": "GripMind API v1",
  "status": "ok"
}
```

### Purpose

iOS App 可用此 API 確認後端服務是否正常運作。

---

## 5. Device Profile API

### Request

```http
GET /api/v1/devices/{device_id}/profile
```

### Expected Response

```json
{
  "device_id": "device_demo_001",
  "profile": {
    "target_weight": 4.0,
    "age": "20",
    "gender": "male",
    "condition": "rehabilitation",
    "method": "grip_training",
    "points": 0
  }
}
```

### Required Fields

| Field                   | Type          | Required | Description    |
| ----------------------- | ------------- | -------- | -------------- |
| `device_id`             | String        | Yes      | 裝置 ID          |
| `profile`               | Object        | Yes      | 使用者或裝置 Profile |
| `profile.target_weight` | Number        | Yes      | 目標握力           |
| `profile.age`           | String / null | No       | 年齡             |
| `profile.gender`        | String / null | No       | 性別             |
| `profile.condition`     | String / null | No       | 使用者狀態          |
| `profile.method`        | String / null | No       | 訓練方式           |
| `profile.points`        | Number / null | No       | 使用者點數或其他統計資訊   |

### Error Response

若裝置不存在，建議回傳：

```json
{
  "error": "device not found"
}
```

HTTP status code:

```text
404 Not Found
```

### iOS Usage

iOS App 會使用此 API 判斷：

* 裝置是否存在
* 裝置是否完成 LINE 綁定
* 是否可以儲存 `device_id` 並進入主畫面

---

## 6. Grip Summary API

### Request

```http
GET /api/v1/devices/{device_id}/summary
```

### Expected Response

```json
{
  "device_id": "device_demo_001",
  "target_weight": 4.0,
  "latest_record": {
    "device_id": "device_demo_001",
    "grip": 3.8,
    "timestamp": "20260606 12:54:52"
  },
  "today": {
    "count": 3,
    "max_grip": 4.1,
    "average_grip": 3.6,
    "goal_reached": true
  },
  "total_records": 12
}
```

### Required Fields

| Field                | Type          | Required | Description |
| -------------------- | ------------- | -------- | ----------- |
| `device_id`          | String        | Yes      | 裝置 ID       |
| `target_weight`      | Number        | Yes      | 目前目標握力      |
| `latest_record`      | Object / null | Yes      | 最近一筆握力紀錄    |
| `today`              | Object        | Yes      | 今日摘要        |
| `today.count`        | Number        | Yes      | 今日訓練次數      |
| `today.max_grip`     | Number / null | Yes      | 今日最高握力      |
| `today.average_grip` | Number / null | Yes      | 今日平均握力      |
| `today.goal_reached` | Boolean       | Yes      | 今日是否達標      |
| `total_records`      | Number        | Yes      | 總紀錄數        |

### Timestamp Format

iOS App 目前預期 timestamp 格式為：

```text
yyyyMMdd HH:mm:ss
```

範例：

```text
20260606 12:54:52
```

若後端改變 timestamp 格式，iOS App 的 `DateFormatter` 也需要同步修改。

---

## 7. Grip Records API

### Request

```http
GET /api/v1/devices/{device_id}/records
```

### Query Parameters

| Parameter  | Type   | Required | Description    |
| ---------- | ------ | -------- | -------------- |
| `limit`    | Int    | No       | 限制回傳紀錄數量       |
| `_refresh` | String | No       | iOS App 用於避免快取 |

### Expected Response

```json
{
  "device_id": "device_demo_001",
  "count": 3,
  "records": [
    {
      "device_id": "device_demo_001",
      "grip": 3.0,
      "timestamp": "20260606 12:54:50"
    },
    {
      "device_id": "device_demo_001",
      "grip": 4.1,
      "timestamp": "20260606 12:54:51"
    },
    {
      "device_id": "device_demo_001",
      "grip": 3.7,
      "timestamp": "20260607 09:20:00"
    }
  ]
}
```

### Required Fields

| Field                 | Type   | Required | Description |
| --------------------- | ------ | -------- | ----------- |
| `device_id`           | String | Yes      | 裝置 ID       |
| `count`               | Number | Yes      | 回傳紀錄數量      |
| `records`             | Array  | Yes      | 握力紀錄陣列      |
| `records[].device_id` | String | Yes      | 裝置 ID       |
| `records[].grip`      | Number | Yes      | 握力數值        |
| `records[].timestamp` | String | Yes      | 紀錄時間        |

### iOS Data Processing

iOS App 會在本地端將紀錄做以下處理：

```text
Raw records
  → Parse timestamp
  → Group by day
  → Calculate daily average
  → Filter selected week
  → Display with Swift Charts
```

因此後端只需要回傳原始紀錄，不需要先幫 App 算每日平均。

---

## 8. Update Target API

### Request

```http
PATCH /api/v1/devices/{device_id}/target
```

### Headers

```http
Content-Type: application/json
```

### Request Body

```json
{
  "target_weight": 4.0
}
```

### Expected Response

```json
{
  "device_id": "device_demo_001",
  "target_weight": 4.0,
  "message": "Target weight updated successfully"
}
```

### Required Fields

| Field           | Type   | Required | Description |
| --------------- | ------ | -------- | ----------- |
| `device_id`     | String | Yes      | 裝置 ID       |
| `target_weight` | Number | Yes      | 更新後的目標握力    |
| `message`       | String | Yes      | 更新結果訊息      |

### Validation Requirements

後端應檢查：

* `target_weight` 是否存在
* `target_weight` 是否為數字
* `target_weight` 是否大於 0
* `device_id` 是否存在

建議錯誤範例：

```json
{
  "error": "target_weight must be greater than 0"
}
```

HTTP status code:

```text
400 Bad Request
```

---

## 9. AI Analysis API

### Request

```http
POST /api/v1/devices/{device_id}/analysis
```

### Expected Response

```json
{
  "device_id": "device_demo_001",
  "suggestion": "你近期的握力表現逐漸接近目標，建議維持目前訓練頻率，並注意每次訓練後的休息時間。",
  "disclaimer": "This suggestion is for training feedback only and is not a medical diagnosis."
}
```

### Required Fields

| Field        | Type          | Required | Description |
| ------------ | ------------- | -------- | ----------- |
| `device_id`  | String        | Yes      | 裝置 ID       |
| `suggestion` | String        | Yes      | AI 產生的訓練回饋  |
| `disclaimer` | String / null | No       | 醫療免責聲明      |

### Backend AI Flow

後端應負責：

1. 讀取指定 `device_id` 的 profile
2. 讀取近期握力紀錄
3. 整理成 AI Prompt
4. 呼叫 Ollama API
5. 回傳訓練回饋文字
6. 附上醫療免責聲明

### Ollama Requirement

若使用 Ollama，後端應可存取：

```text
http://127.0.0.1:11434
```

或其他私有伺服器位址，例如：

```text
http://100.76.39.84:11434
```

建議後端環境變數：

```env
OLLAMA_BASE_URL=http://127.0.0.1:11434
OLLAMA_MODEL=qwen2.5:7b
OLLAMA_TIMEOUT=120
```

---

## 10. LINE Login Binding Requirement

iOS App 第一次使用時，需要透過外部後端完成 LINE Login 裝置綁定。

### Login URL

```http
GET /login?device_id={device_id}&client=ios&app_callback_url=gripmind://bind-success
```

### Example

```text
https://gripmind.hasaki.idv.tw/login?device_id=device_demo_001&client=ios&app_callback_url=gripmind://bind-success
```

### Required Query Parameters

| Parameter          | Type   | Required    | Description           |
| ------------------ | ------ | ----------- | --------------------- |
| `device_id`        | String | Yes         | 要綁定的裝置 ID             |
| `client`           | String | Recommended | iOS App 建議帶 `ios`     |
| `app_callback_url` | String | Recommended | iOS Custom URL Scheme |

---

## 11. LINE Login Callback Requirement

LINE Developers 後台 Callback URL 應設定為後端 callback：

```text
https://<BACKEND_DOMAIN>/callback
```

例如：

```text
https://gripmind.hasaki.idv.tw/callback
```

### Required Backend Behavior

LINE Login 成功後，後端應：

1. 接收 LINE OAuth callback
2. 驗證 OAuth `state`
3. 使用 `code` 換取 LINE profile
4. 取得 LINE user ID
5. 將 LINE user ID 與 `device_id` 綁定
6. 若 `client=ios`，導回 iOS App

iOS App 回跳格式：

```text
gripmind://bind-success?status=success&device_id=device_demo_001
```

若登入失敗，建議回跳：

```text
gripmind://bind-error?status=error&message=<ERROR_MESSAGE>
```

---

## 12. iOS Custom URL Scheme Requirement

後端導回 App 時，需使用：

```text
gripmind://bind-success
```

因此 iOS App 需設定 URL Scheme：

```text
gripmind
```

Xcode 設定位置：

```text
Target → Info → URL Types
```

---

## 13. Cache Policy Requirement

握力資料會頻繁更新，因此後端應避免 API 被快取。

建議所有 `/api/v1` response 加上：

```http
Cache-Control: no-store, no-cache, must-revalidate, max-age=0
Pragma: no-cache
Expires: 0
```

Flask 範例：

```python
@api_v1.after_request
def add_no_cache_headers(response):
    response.headers["Cache-Control"] = "no-store, no-cache, must-revalidate, max-age=0"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "0"
    return response
```

iOS App 端也會在 records API 加上 `_refresh` query parameter 以避免快取。

---

## 14. CORS Requirement

若只有 iOS App 使用 API，通常不需要特別開 CORS。

但如果同一個後端也有 Web 前端，後端可能需要設定 CORS。

建議限制允許來源，不要直接在正式環境使用過寬設定：

```text
Access-Control-Allow-Origin: *
```

---

## 15. Authentication Requirement

目前 GripMind iOS Prototype 主要依靠 `device_id` 與 LINE 綁定流程運作，尚未實作正式 API token authentication。

若要產品化，建議加入：

* Bearer Token
* Session Token
* Device ownership validation
* API rate limiting
* Refresh token mechanism
* User account management

目前階段，至少應避免：

* 在公開 repo 放 LINE secret
* 在公開 repo 放 `.env`
* 在前端硬編碼敏感資訊
* 讓任意 `app_callback_url` 造成 open redirect

---

## 16. Security Requirement for App Callback URL

後端若支援：

```text
app_callback_url=gripmind://bind-success
```

必須檢查 callback URL 是否安全。

建議只允許以下 prefix：

```text
gripmind://bind-success
gripmind://bind-error
```

不應允許任意網址，例如：

```text
https://evil.example.com
```

否則可能造成 open redirect 風險。

---

## 17. Error Response Format

建議後端統一錯誤格式：

```json
{
  "error": "Human readable error message"
}
```

常見錯誤：

| Status Code | Scenario              |
| ----------- | --------------------- |
| 400         | Request body 格式錯誤     |
| 401         | 未授權                   |
| 403         | 無權限                   |
| 404         | 找不到 device            |
| 429         | Too many requests     |
| 500         | Server internal error |

---

## 18. Minimum Backend Test Checklist

後端完成後，至少應通過以下測試：

### Health Check

```bash
curl https://<BACKEND_DOMAIN>/api/v1/health
```

### Profile

```bash
curl https://<BACKEND_DOMAIN>/api/v1/devices/<DEVICE_ID>/profile
```

### Summary

```bash
curl https://<BACKEND_DOMAIN>/api/v1/devices/<DEVICE_ID>/summary
```

### Records

```bash
curl "https://<BACKEND_DOMAIN>/api/v1/devices/<DEVICE_ID>/records?limit=100&_refresh=test"
```

### Update Target

```bash
curl -X PATCH https://<BACKEND_DOMAIN>/api/v1/devices/<DEVICE_ID>/target \
  -H "Content-Type: application/json" \
  -d '{"target_weight": 4.0}'
```

### AI Analysis

```bash
curl -X POST https://<BACKEND_DOMAIN>/api/v1/devices/<DEVICE_ID>/analysis
```

### LINE Login

手動開啟：

```text
https://<BACKEND_DOMAIN>/login?device_id=<DEVICE_ID>&client=ios&app_callback_url=gripmind://bind-success
```

確認登入成功後是否能導回 App。

---

## 19. Example Backend Environment Variables

後端可使用以下環境變數：

```env
URL=https://gripmind.hasaki.idv.tw

LINE_CHANNEL_ID=your_line_channel_id
LINE_CHANNEL_SECRET=your_line_channel_secret

SECRET_KEY=your_flask_secret_key

OLLAMA_BASE_URL=http://127.0.0.1:11434
OLLAMA_MODEL=qwen2.5:7b
OLLAMA_TIMEOUT=120
```

注意：

* `.env` 不應提交到 GitHub
* LINE secrets 不應硬編碼在程式碼內
* Ollama model 名稱需與 `ollama list` 顯示一致

---

## 20. Backend Deployment Recommendation

雖然後端不包含在此 repo 中，但建議部署方式如下：

```text
Flask Backend
  |
  v
systemd
  |
  v
Nginx Reverse Proxy
  |
  v
Cloudflare Tunnel
  |
  v
Public Domain
```

建議正式 API 使用 HTTPS：

```text
https://<BACKEND_DOMAIN>/api/v1
```

---

## 21. Summary

GripMind iOS App 需要一個外部 Backend API 才能完整運作。

此 Backend 至少需要提供：

* 裝置 Profile API
* 握力 Summary API
* 握力 Records API
* 目標握力更新 API
* AI 訓練回饋 API
* LINE Login 綁定流程
* iOS Custom URL Scheme 回跳支援

只要後端符合本文件規格，GripMind iOS App 即可透過 `APIClient.swift` 正常串接並顯示資料。
