# GripMind iOS App Setup Guide

本文件說明如何在本機環境開啟、設定與執行 GripMind iOS App。

> 注意：本 repo 僅包含 iOS App。
> App 需要串接外部 Flask Backend API 才能完整使用裝置綁定、握力紀錄、目標設定與 AI 訓練回饋功能。

---

## 1. Requirements

開發與執行 GripMind iOS App 需要以下環境：

| Tool                  | Requirement                   |
| --------------------- | ----------------------------- |
| macOS                 | 建議使用最新版或近兩版 macOS             |
| Xcode                 | 建議使用 Xcode 15 或以上             |
| iOS Deployment Target | iOS 16.0 或以上                  |
| Swift                 | Swift 5.9 或以上                 |
| Network               | 需要能連線至外部 GripMind Backend API |

本專案使用 Swift Charts，因此 iOS Deployment Target 建議設定為：

```text
iOS 16.0+
```

---

## 2. Clone Repository

```bash
git clone https://github.com/cloud-driver/gripmind.git
cd gripmind
```

---

## 3. Open Xcode Project

使用 Xcode 開啟專案：

```bash
open GripMind.xcodeproj
```

或直接在 Finder 中雙擊：

```text
GripMind.xcodeproj
```

---

## 4. Project Structure

主要 iOS App 結構如下：

```text
GripMind
├── Assets.xcassets
├── ContentView.swift
├── DesignSystem
├── Models
├── Services
├── ViewModels
└── Views
```

各資料夾用途：

| Folder         | Purpose             |
| -------------- | ------------------- |
| `DesignSystem` | 共用 UI 元件、主題色、卡片、按鈕  |
| `Models`       | API Response 對應資料模型 |
| `Services`     | APIClient 與網路請求邏輯   |
| `ViewModels`   | SwiftUI 畫面狀態與資料處理   |
| `Views`        | App 主要畫面            |

---

## 5. Configure API Base URL

GripMind iOS App 會透過 `APIClient.swift` 連接外部後端。

請開啟：

```text
GripMind/Services/APIClient.swift
```

找到：

```swift
private let baseURL = "https://your-backend-domain.example.com/api/v1"
```

改成實際後端 API Base URL。

範例：

```swift
private let baseURL = "https://gripmind.hasaki.idv.tw/api/v1"
```

確認後端健康檢查可用：

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

---

## 6. Configure URL Scheme

GripMind 使用 iOS Custom URL Scheme 接收 LINE Login 完成後的回跳。

### Xcode 設定方式

1. 點選 Xcode 左側專案
2. 選擇 App Target
3. 進入：

```text
Info → URL Types
```

4. 新增一組 URL Type：

| Field       | Value                 |
| ----------- | --------------------- |
| Identifier  | `com.hasaki.gripmind` |
| URL Schemes | `gripmind`            |

設定完成後，App 可以接收：

```text
gripmind://bind-success
```

---

## 7. Backend Login URL Requirement

首次綁定裝置時，App 會開啟外部後端登入頁。

格式如下：

```text
https://<BACKEND_DOMAIN>/login?device_id=<DEVICE_ID>&client=ios&app_callback_url=gripmind://bind-success
```

完成 LINE Login 後，後端應導回：

```text
gripmind://bind-success?status=success&device_id=<DEVICE_ID>
```

接著 iOS App 會呼叫：

```http
GET /api/v1/devices/{device_id}/profile
```

確認裝置綁定是否成功。

---

## 8. Run the App

在 Xcode 中選擇模擬器或實體裝置後，按下：

```text
Command + R
```

或點擊左上角 Run 按鈕。

---

## 9. First-Time App Flow

第一次開啟 App 時，流程如下：

```text
Open App
  → Enter device_id
  → Open LINE Binding
  → Complete LINE Login
  → Backend redirects to gripmind://bind-success
  → App verifies profile API
  → Save device_id with AppStorage
  → Enter MainTabView
```

成功後，App 會進入主要畫面：

```text
首頁
紀錄
AI
設定
```

---

## 10. Main Tabs

### Dashboard

首頁會呼叫：

```http
GET /api/v1/devices/{device_id}/summary
GET /api/v1/devices/{device_id}/profile
```

用於顯示：

* 今日訓練次數
* 目標握力
* 今日最高握力
* 今日平均握力
* 最近一次紀錄
* LINE 綁定狀態

---

### History

歷史紀錄頁會呼叫：

```http
GET /api/v1/devices/{device_id}/records
```

App 會在本地端將原始握力紀錄整理成每日平均值，並以週為單位顯示圖表。

---

### AI Feedback

AI 頁面會呼叫：

```http
POST /api/v1/devices/{device_id}/analysis
```

後端會產生 AI 訓練回饋，App 負責顯示結果。

---

### Settings

設定頁會呼叫：

```http
PATCH /api/v1/devices/{device_id}/target
```

用於更新目標握力。

---

## 11. Test with Demo Device

如果後端已有測試裝置，可以使用：

```text
device_demo_001
```

建議先測試：

```bash
curl https://gripmind.hasaki.idv.tw/api/v1/devices/device_demo_001/profile
curl https://gripmind.hasaki.idv.tw/api/v1/devices/device_demo_001/summary
curl "https://gripmind.hasaki.idv.tw/api/v1/devices/device_demo_001/records?limit=100"
```

若上述 API 可正常回傳，iOS App 才能正常顯示資料。

---

## 12. Reset Device Binding

如果需要重新綁定裝置：

1. 開啟 App
2. 進入「設定」
3. 點擊「清除綁定裝置」
4. App 會回到 Onboarding
5. 重新輸入 `device_id` 並進行 LINE 綁定

此操作會清除本機儲存的 `savedDeviceId`。

---

## 13. Common Issues

### 13.1 Cannot Connect to API

可能原因：

* `APIClient.swift` 的 `baseURL` 設定錯誤
* 後端服務未啟動
* Cloudflare Tunnel / Nginx 設定錯誤
* 裝置或模擬器無法連網

檢查：

```bash
curl https://<BACKEND_DOMAIN>/api/v1/health
```

---

### 13.2 LINE Login Does Not Return to App

請檢查：

1. Xcode 是否設定 URL Scheme：

```text
gripmind
```

2. 後端是否導回：

```text
gripmind://bind-success
```

3. 登入網址是否包含：

```text
client=ios
app_callback_url=gripmind://bind-success
```

---

### 13.3 Dashboard Shows No Data

可能原因：

* 該 `device_id` 沒有握力紀錄
* 後端 summary API 回傳空資料
* App 使用的 `device_id` 與後端資料不一致

檢查：

```bash
curl https://<BACKEND_DOMAIN>/api/v1/devices/<DEVICE_ID>/summary
```

---

### 13.4 History Page Does Not Refresh

可能原因：

* 後端回傳被快取
* App 未重新呼叫 records API
* 後端資料尚未更新

建議後端加上 no-cache headers，App 端 records API 使用 `_refresh` query parameter。

檢查：

```bash
curl "https://<BACKEND_DOMAIN>/api/v1/devices/<DEVICE_ID>/records?limit=100&_refresh=test"
```

---

### 13.5 AI Feedback Returns Error

可能原因：

* Ollama Server 未啟動
* 模型名稱設定錯誤
* 後端 AI endpoint 錯誤
* API timeout

先檢查後端：

```bash
curl -X POST https://<BACKEND_DOMAIN>/api/v1/devices/<DEVICE_ID>/analysis
```

---

## 14. Development Notes

### MVVM

App 採用 MVVM 分層：

```text
View
  → ViewModel
  → APIClient
  → External Backend API
```

View 不直接處理 `URLSession`，所有 API 呼叫集中在 `APIClient.swift`。

---

### Local Device Storage

App 使用：

```swift
@AppStorage("savedDeviceId")
```

保存目前綁定的裝置 ID。

這讓使用者完成首次綁定後，不需要在每個頁面重複輸入 `device_id`。

---

### Chart Data Processing

歷史紀錄圖表不是直接顯示每筆原始資料，而是：

```text
Raw records
  → Group by date
  → Calculate daily average
  → Filter by selected week
  → Display chart
```

這樣可以避免同一天多筆紀錄造成圖表過度密集。

---

## 15. Before Commit Checklist

提交前請確認：

* [ ] App 可以成功 build
* [ ] `baseURL` 指向正確後端
* [ ] URL Scheme 已設定為 `gripmind`
* [ ] Dashboard 可正常載入
* [ ] History 可下拉重新整理
* [ ] AI Feedback 不顯示錯誤
* [ ] Settings 可更新目標握力
* [ ] 深色模式與淺色模式文字都清楚可讀
* [ ] README 截圖路徑正確
* [ ] 沒有提交 `.env`、個人憑證或 Xcode 使用者資料

---

## 16. Related Documents

| Document                                                  | Description                           |
| --------------------------------------------------------- | ------------------------------------- |
| [`README.md`](../README.md)                               | Project overview                      |
| [`README.zh-TW.md`](../README.zh-TW.md)                   | 中文專案說明                                |
| [`docs/architecture.md`](architecture.md)                 | System architecture                   |
| [`docs/api.md`](api.md)                                   | API contract used by the iOS app      |
| [`docs/backend-requirements.md`](backend-requirements.md) | Backend requirements for this iOS app |
