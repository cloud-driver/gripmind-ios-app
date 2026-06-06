# GripMind API Documentation

本文件整理 GripMind iOS App 目前使用的後端 API，包括健康檢查、裝置 Profile、握力摘要、歷史紀錄、目標握力更新、AI 訓練回饋，以及 LINE Login 綁定流程。

> Base URL 範例：
>
> ```text
> https://gripmind.hasaki.idv.tw/api/v1
> ```

---

## 1. API Overview

GripMind iOS App 主要透過 RESTful API 與 Flask 後端溝通。

主要功能包含：

* 檢查後端服務狀態
* 取得裝置 Profile
* 取得今日握力摘要
* 取得歷史握力紀錄
* 修改目標握力
* 產生 AI 訓練回饋
* 驗證 LINE Login 裝置綁定狀態

---

## 2. Endpoint Summary

| Method | Endpoint                        | Description              |
| ------ | ------------------------------- | ------------------------ |
| GET    | `/health`                       | 檢查 API 服務狀態              |
| GET    | `/devices`                      | 取得目前已存在的裝置列表             |
| GET    | `/devices/{device_id}/profile`  | 取得裝置 Profile 與 LINE 綁定資料 |
| GET    | `/devices/{device_id}/summary`  | 取得今日握力摘要                 |
| GET    | `/devices/{device_id}/records`  | 取得握力歷史紀錄                 |
| PATCH  | `/devices/{device_id}/target`   | 更新目標握力                   |
| POST   | `/devices/{device_id}/analysis` | 產生 AI 訓練回饋               |

---

## 3. Common Response Format

目前 API 主要使用 JSON 格式回傳資料。

### Success Response

成功時通常會回傳：

```json
{
  "status": "ok"
}
```

或依不同 endpoint 回傳對應資料。

### Error Response

若發生錯誤，建議後端統一回傳：

```json
{
  "error": "Error message"
}
```

常見 HTTP status code：

| Status Code | Meaning      |
| ----------- | ------------ |
| 200         | 請求成功         |
| 400         | 請求格式錯誤       |
| 404         | 找不到指定 device |
| 500         | 後端服務錯誤       |

---

## 4. Health Check

檢查後端 API 是否正常運作。

### Request

```http
GET /api/v1/health
```

### Example

```bash
curl https://gripmind.hasaki.idv.tw/api/v1/health
```

### Response

```json
{
  "service": "GripMind API v1",
  "status": "ok"
}
```

### iOS Model

```swift
struct HealthResponse: Codable {
    let service: String
    let status: String
}
```

---

## 5. Get Devices

取得目前後端已存在的裝置列表。

### Request

```http
GET /api/v1/devices
```

### Example

```bash
curl https://gripmind.hasaki.idv.tw/api/v1/devices
```

### Response Example

```json
{
  "devices": [
    "device_demo_001"
  ]
}
```

### Usage

此 endpoint 可用於：

* Debug 後端是否已有裝置資料
* 檢查測試裝置是否存在
* 開發期間確認 `device_id`

---

## 6. Get Device Profile

取得指定裝置的 Profile 資料，並可用於確認 LINE Login 綁定狀態。

### Request

```http
GET /api/v1/devices/{device_id}/profile
```

### Path Parameters

| Parameter   | Type   | Description |
| ----------- | ------ | ----------- |
| `device_id` | String | 裝置 ID       |

### Example

```bash
curl https://gripmind.hasaki.idv.tw/api/v1/devices/device_demo_001/profile
```

### Response Example

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

### iOS Model

```swift
struct DeviceProfileResponse: Codable {
    let deviceId: String
    let profile: DeviceProfile

    enum CodingKeys: String, CodingKey {
        case deviceId = "device_id"
        case profile
    }
}

struct DeviceProfile: Codable {
    let targetWeight: Double
    let age: String?
    let gender: String?
    let condition: String?
    let method: String?
    let points: Int?

    enum CodingKeys: String, CodingKey {
        case targetWeight = "target_weight"
        case age
        case gender
        case condition
        case method
        case points
    }
}
```

### Notes

iOS App 會透過此 API 判斷裝置是否已完成 LINE 綁定。

如果此 API 回傳成功，App 會視為此裝置已可使用。

如果回傳 `404`，App 會視為裝置尚未綁定或不存在。

---

## 7. Get Grip Summary

取得指定裝置的今日握力摘要。

### Request

```http
GET /api/v1/devices/{device_id}/summary
```

### Path Parameters

| Parameter   | Type   | Description |
| ----------- | ------ | ----------- |
| `device_id` | String | 裝置 ID       |

### Example

```bash
curl https://gripmind.hasaki.idv.tw/api/v1/devices/device_demo_001/summary
```

### Response Example

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

### iOS Model

```swift
struct GripSummaryResponse: Codable {
    let deviceId: String
    let targetWeight: Double
    let latestRecord: GripRecord?
    let today: TodaySummary
    let totalRecords: Int

    enum CodingKeys: String, CodingKey {
        case deviceId = "device_id"
        case targetWeight = "target_weight"
        case latestRecord = "latest_record"
        case today
        case totalRecords = "total_records"
    }
}

struct TodaySummary: Codable {
    let count: Int
    let maxGrip: Double?
    let averageGrip: Double?
    let goalReached: Bool

    enum CodingKeys: String, CodingKey {
        case count
        case maxGrip = "max_grip"
        case averageGrip = "average_grip"
        case goalReached = "goal_reached"
    }
}
```

### Usage in iOS

此 API 用於首頁 Dashboard：

* 今日訓練次數
* 目標握力
* 今日最高握力
* 今日平均握力
* 是否達成目標
* 最近一次紀錄

---

## 8. Get Grip Records

取得指定裝置的握力歷史紀錄。

### Request

```http
GET /api/v1/devices/{device_id}/records
```

### Path Parameters

| Parameter   | Type   | Description |
| ----------- | ------ | ----------- |
| `device_id` | String | 裝置 ID       |

### Query Parameters

| Parameter  | Type   | Required | Description         |
| ---------- | ------ | -------- | ------------------- |
| `limit`    | Int    | No       | 限制回傳紀錄數量            |
| `_refresh` | String | No       | iOS App 用於避免快取的刷新參數 |

### Example

```bash
curl "https://gripmind.hasaki.idv.tw/api/v1/devices/device_demo_001/records?limit=100"
```

### Response Example

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

### iOS Model

```swift
struct GripRecordsResponse: Codable {
    let deviceId: String
    let count: Int
    let records: [GripRecord]

    enum CodingKeys: String, CodingKey {
        case deviceId = "device_id"
        case count
        case records
    }
}

struct GripRecord: Codable, Identifiable {
    let deviceId: String
    let grip: Double
    let timestamp: String

    var id: String {
        "\(deviceId)-\(timestamp)"
    }

    enum CodingKeys: String, CodingKey {
        case deviceId = "device_id"
        case grip
        case timestamp
    }
}
```

### Timestamp Format

目前 iOS App 解析 timestamp 時使用下列格式：

```text
yyyyMMdd HH:mm:ss
```

範例：

```text
20260606 12:54:52
```

若後端 timestamp 格式改變，iOS 的 `DateFormatter` 也需要同步調整。

### Usage in iOS

歷史紀錄頁會使用此 API 取得原始握力資料。

App 端會將資料轉換成每日平均值：

```text
同一天多筆紀錄 → 計算平均 → 圖表顯示一個點
```

這樣可以避免圖表資料過於密集。

---

## 9. Update Target Grip

更新指定裝置的目標握力。

### Request

```http
PATCH /api/v1/devices/{device_id}/target
```

### Headers

```http
Content-Type: application/json
```

### Path Parameters

| Parameter   | Type   | Description |
| ----------- | ------ | ----------- |
| `device_id` | String | 裝置 ID       |

### Request Body

```json
{
  "target_weight": 4.0
}
```

### Example

```bash
curl -X PATCH https://gripmind.hasaki.idv.tw/api/v1/devices/device_demo_001/target \
  -H "Content-Type: application/json" \
  -d '{
    "target_weight": 4.0
  }'
```

### Response Example

```json
{
  "device_id": "device_demo_001",
  "target_weight": 4.0,
  "message": "Target weight updated successfully"
}
```

### iOS Model

```swift
struct TargetUpdateResponse: Codable {
    let deviceId: String
    let targetWeight: Double
    let message: String

    enum CodingKeys: String, CodingKey {
        case deviceId = "device_id"
        case targetWeight = "target_weight"
        case message
    }
}
```

### Validation

建議後端驗證：

* `target_weight` 必須存在
* `target_weight` 必須是數字
* `target_weight` 必須大於 0

建議錯誤回應：

```json
{
  "error": "target_weight must be greater than 0"
}
```

---

## 10. Generate AI Training Feedback

根據使用者近期握力資料與目標握力，產生 AI 訓練回饋。

### Request

```http
POST /api/v1/devices/{device_id}/analysis
```

### Path Parameters

| Parameter   | Type   | Description |
| ----------- | ------ | ----------- |
| `device_id` | String | 裝置 ID       |

### Example

```bash
curl -X POST https://gripmind.hasaki.idv.tw/api/v1/devices/device_demo_001/analysis
```

### Response Example

```json
{
  "device_id": "device_demo_001",
  "suggestion": "你近期的握力表現逐漸接近目標，建議維持目前訓練頻率，並注意每次訓練後的休息時間。",
  "disclaimer": "This suggestion is for training feedback only and is not a medical diagnosis."
}
```

### iOS Model

```swift
struct AnalysisResponse: Codable {
    let deviceId: String
    let suggestion: String
    let disclaimer: String?

    enum CodingKeys: String, CodingKey {
        case deviceId = "device_id"
        case suggestion
        case disclaimer
    }
}
```

### Backend AI Flow

```text
POST /analysis
  → read device profile
  → read recent grip records
  → build prompt
  → call Ollama /api/chat
  → return suggestion
```

### Notes

AI 回饋僅作為訓練輔助，不應視為醫療診斷。

若 Ollama 服務未啟動、模型不存在或 API URL 設定錯誤，後端應回傳清楚的錯誤訊息，方便 debug。

---

## 11. LINE Login Binding Flow

LINE Login 流程不屬於 `/api/v1`，但 iOS App 的首次綁定會使用此流程。

### Login URL

```http
GET /login?device_id={device_id}&client=ios&app_callback_url=gripmind://bind-success
```

### Example

```text
https://gripmind.hasaki.idv.tw/login?device_id=device_demo_001&client=ios&app_callback_url=gripmind://bind-success
```

### Parameters

| Parameter          | Type   | Required | Description               |
| ------------------ | ------ | -------- | ------------------------- |
| `device_id`        | String | Yes      | 要綁定的裝置 ID                 |
| `client`           | String | No       | 若為 iOS App，建議使用 `ios`     |
| `app_callback_url` | String | No       | iOS App Custom URL Scheme |

---

### Callback Flow

1. iOS App 開啟 `/login`
2. 後端導向 LINE Login
3. 使用者完成 LINE 登入
4. LINE 導回 Flask `/callback`
5. Flask 儲存 LINE 使用者與 `device_id`
6. Flask 導回 iOS App：

```text
gripmind://bind-success?status=success&device_id=device_demo_001
```

7. iOS App 呼叫 `/profile` 驗證綁定是否成功
8. 驗證成功後儲存 `device_id`

---

## 12. iOS APIClient Notes

iOS App 使用 `APIClient.swift` 統一處理 API 呼叫。

主要設計：

* 使用 `URLSession.shared.data(for:)`
* 使用 async/await
* 統一處理 HTTP status code
* 統一 decode JSON
* 避免每個 View 直接呼叫 API
* 將網路錯誤轉換為 `APIError`

### APIError

```swift
enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(Int)
    case decodingError
    case cancelled
    case unknown(Error)
}
```

### Refresh Handling

歷史紀錄頁使用 `_refresh` query parameter 避免快取：

```text
/devices/{device_id}/records?limit=100&_refresh=<UUID>
```

並設定：

```swift
request.cachePolicy = .reloadIgnoringLocalCacheData
```

---

## 13. Cache Policy

因為握力紀錄會頻繁更新，建議後端對 API response 加上 no-cache headers。

建議 Flask 設定：

```python
@api_v1.after_request
def add_no_cache_headers(response):
    response.headers["Cache-Control"] = "no-store, no-cache, must-revalidate, max-age=0"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "0"
    return response
```

這可以避免 iOS App、代理伺服器或 Cloudflare 快取舊資料。

---

## 14. Security Notes

目前 GripMind 是 Prototype，API 設計仍有可改進空間。

目前限制：

* API 尚未加入正式 token authentication
* 裝置 ID 目前由使用者輸入
* Profile 查詢可作為綁定驗證，但不是完整登入系統
* AI feedback 不應被視為醫療建議
* 若要正式產品化，需要更完整的權限控管

建議未來加入：

* API token
* User session
* Device ownership validation
* Rate limiting
* Database migration
* Audit log
* HTTPS-only production setting
* 更嚴格的 LINE Login state validation

---

## 15. Testing Examples

### Health Check

```bash
curl https://gripmind.hasaki.idv.tw/api/v1/health
```

### Get Summary

```bash
curl https://gripmind.hasaki.idv.tw/api/v1/devices/device_demo_001/summary
```

### Get Records

```bash
curl "https://gripmind.hasaki.idv.tw/api/v1/devices/device_demo_001/records?limit=100"
```

### Update Target

```bash
curl -X PATCH https://gripmind.hasaki.idv.tw/api/v1/devices/device_demo_001/target \
  -H "Content-Type: application/json" \
  -d '{"target_weight": 4.0}'
```

### Generate AI Feedback

```bash
curl -X POST https://gripmind.hasaki.idv.tw/api/v1/devices/device_demo_001/analysis
```

---

## 16. Medical Disclaimer

The AI feedback generated by GripMind is for training reference only.

It is not a medical diagnosis, medical treatment, or professional rehabilitation prescription.

Users should consult healthcare professionals for medical decisions.
