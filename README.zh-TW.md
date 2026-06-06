# GripMind iOS App｜智慧握力復健紀錄 App

繁體中文 | [English](README.md)

GripMind iOS App 是 GripMind 智慧握力復健紀錄系統的行動端 Client。

本 repo **僅包含 iOS App 原始碼**。App 會串接外部 Flask REST API，用於裝置綁定、握力紀錄查詢、目標握力設定，以及 AI 訓練回饋顯示。

> 後端 API、LINE Login Callback、Ollama AI 整合與伺服器部署設定不包含在此 iOS repo 中。

---

## 專案概述

GripMind 的目標是協助使用者透過 iOS App 追蹤握力訓練資料，並以簡潔的介面呈現每日摘要、每週趨勢、目標握力與 AI 輔助回饋。

本專案是一個 SwiftUI App Prototype，展示以下能力：

* iOS App 開發
* REST API 串接
* LINE Login 裝置綁定流程
* Swift Charts 資料視覺化
* MVVM 架構
* 下拉重新整理資料
* 深色模式與淺色模式支援
* 從外部後端取得 AI 訓練回饋

> GripMind 僅作為訓練紀錄與回饋輔助，不作為醫療診斷、治療建議或醫療決策依據。

---

## App 畫面截圖

| 首頁 Dashboard                         | 每週歷史紀錄                             | AI 訓練回饋                                | 設定頁                                 |
| ------------------------------------ | ---------------------------------- | -------------------------------------- | ----------------------------------- |
| ![](docs/screenshots/dashboard.webp) | ![](docs/screenshots/history.webp) | ![](docs/screenshots/ai-feedback.webp) | ![](docs/screenshots/settings.webp) |

---

## 核心功能

### 首次裝置綁定

* 使用者第一次開啟 App 時輸入 `device_id`
* App 開啟外部後端提供的 LINE Login 綁定頁
* LINE Login 完成後，後端透過 Custom URL Scheme 導回 App
* App 呼叫 Profile API 驗證裝置是否已完成綁定
* 成功後使用 `AppStorage` 將 `device_id` 儲存在本機

### 首頁 Dashboard

* 顯示今日訓練次數
* 顯示目標握力
* 顯示今日最高握力
* 顯示今日平均握力
* 顯示最近一次握力紀錄
* 顯示 LINE 綁定狀態
* 支援下拉重新整理

### 每週歷史紀錄

* 以週為單位顯示握力紀錄
* 支援切換週次
* 將同一天多筆紀錄整理成每日平均值
* 使用 Swift Charts 顯示握力趨勢
* 保留原始紀錄列表，方便查看每筆訓練資料

### 更改目標握力

* 使用者可在設定頁更新目標握力
* App 會自動使用已綁定的 `device_id`
* 綁定完成後不需要在每個頁面重複輸入裝置 ID

### AI 訓練回饋

* 呼叫外部後端 AI 分析 API
* 顯示 AI 產生的訓練回饋
* 顯示醫療免責聲明，避免將系統誤用為醫療診斷工具

---

## 系統定位

此 repo 是 GripMind 系統的 **iOS Client**。

```text
GripMind iOS App
  |
  | HTTPS REST API
  v
External Flask Backend API
  |
  +--> LINE Login Binding
  |
  +--> Grip Records / User Profile Data
  |
  +--> Ollama AI Feedback
```

外部後端服務需提供：

* RESTful API endpoints
* 裝置 Profile 查詢
* 握力紀錄儲存與查詢
* 目標握力更新
* LINE Login Callback 處理
* Ollama AI 分析整合

---

## 技術棧

### iOS App

* Swift
* SwiftUI
* Swift Charts
* MVVM 架構
* AppStorage
* URLSession async/await
* Custom URL Scheme
* 深色模式與淺色模式自適應 UI

### 外部服務

* Flask REST API
* LINE Login
* Ollama Local AI Server
* Cloudflare Tunnel / Nginx 部署環境

---

## 專案結構

```text
GripMind
├── Assets.xcassets
├── ContentView.swift
├── DesignSystem
│   ├── GMAppHeader.swift
│   ├── GMCard.swift
│   ├── GMCopyrightFooter.swift
│   ├── GMDeviceCard.swift
│   ├── GMMessageCard.swift
│   ├── GMPrimaryButton.swift
│   ├── GMStatCard.swift
│   └── GMTheme.swift
├── GripMindApp.swift
├── Info.plist
├── Models
│   ├── AnalysisResponse.swift
│   ├── DailyGripAverage.swift
│   ├── DeviceProfileResponse.swift
│   ├── GripRecord.swift
│   ├── GripRecordsResponse.swift
│   ├── GripSummaryResponse.swift
│   ├── HealthResponse.swift
│   └── TargetUpdateResponse.swift
├── Services
│   └── APIClient.swift
├── ViewModels
│   ├── AnalysisViewModel.swift
│   ├── DashboardViewModel.swift
│   ├── HealthCheckViewModel.swift
│   ├── HistoryViewModel.swift
│   └── SettingsViewModel.swift
└── Views
    ├── AnalysisView.swift
    ├── DashboardView.swift
    ├── HistoryChartView.swift
    ├── HistoryView.swift
    ├── MainTabView.swift
    ├── OnboardingView.swift
    ├── RecordsListView.swift
    └── SettingsView.swift
```

---

## App 使用流程

### 1. Onboarding 裝置綁定

使用者第一次開啟 App 時，需要輸入裝置 ID。

App 會開啟外部後端登入網址：

```text
https://<BACKEND_DOMAIN>/login?device_id=<DEVICE_ID>&client=ios&app_callback_url=gripmind://bind-success
```

完成 LINE Login 後，後端會導回 App：

```text
gripmind://bind-success?status=success&device_id=<DEVICE_ID>
```

App 收到回跳後，會呼叫 Profile API 驗證裝置是否完成綁定，成功後將 `device_id` 儲存在本機。

---

### 2. 首頁資料載入

首頁會使用已儲存的 `device_id` 呼叫：

```http
GET /api/v1/devices/{device_id}/summary
GET /api/v1/devices/{device_id}/profile
```

取得資料後，App 會將今日訓練摘要顯示成 Dashboard 卡片。

---

### 3. 每週歷史紀錄處理

歷史紀錄頁會呼叫：

```http
GET /api/v1/devices/{device_id}/records
```

App 端會將原始資料做以下處理：

```text
Raw grip records
  → Parse timestamp
  → Group by day
  → Calculate daily average
  → Filter selected week
  → Display with Swift Charts
```

這樣可以避免同一天多筆資料直接畫在圖表上，造成折線圖過度密集。

---

### 4. 更改目標握力

設定頁會呼叫：

```http
PATCH /api/v1/devices/{device_id}/target
```

範例 Request Body：

```json
{
  "target_weight": 4.0
}
```

更新成功後，首頁重新整理即可看到新的目標握力。

---

### 5. AI 訓練回饋

AI 頁面會呼叫：

```http
POST /api/v1/devices/{device_id}/analysis
```

外部後端會透過 Ollama AI 服務產生訓練回饋，再將結果回傳給 App 顯示。

---

## 主要 API Endpoints

此 iOS App 預期外部後端提供以下 API：

| Method | Endpoint                               | 說明                 |
| ------ | -------------------------------------- | ------------------ |
| GET    | `/api/v1/health`                       | 檢查後端服務狀態           |
| GET    | `/api/v1/devices/{device_id}/profile`  | 取得裝置 Profile 與綁定狀態 |
| GET    | `/api/v1/devices/{device_id}/summary`  | 取得每日握力摘要           |
| GET    | `/api/v1/devices/{device_id}/records`  | 取得握力歷史紀錄           |
| PATCH  | `/api/v1/devices/{device_id}/target`   | 更新目標握力             |
| POST   | `/api/v1/devices/{device_id}/analysis` | 產生 AI 訓練回饋         |

詳細 API Contract 請參考：

```text
docs/api.md
```

---

## 本地 iOS 開發方式

### 環境需求

* macOS
* Xcode
* iOS 16.0 或以上
* Swift Charts 支援

### 安裝步驟

1. Clone 專案：

```bash
git clone https://github.com/cloud-driver/gripmind.git
cd gripmind
```

2. 開啟 Xcode 專案：

```bash
open GripMind.xcodeproj
```

3. 修改 API Base URL：

請至：

```text
GripMind/Services/APIClient.swift
```

設定外部後端 API 網址：

```swift
private let baseURL = "https://your-backend-domain.example.com/api/v1"
```

4. 設定 URL Scheme：

在 Xcode 中設定：

```text
Target → Info → URL Types
```

建議 Scheme：

```text
gripmind
```

5. 執行 App：

可使用 iOS Simulator 或實體 iPhone 測試。

---

## 文件

| 文件                                                                     | 說明                           |
| ---------------------------------------------------------------------- | ---------------------------- |
| [`docs/architecture.md`](docs/architecture.md)                         | 系統架構與 App 資料流程               |
| [`docs/api.md`](docs/api.md)                                           | iOS App 使用之外部後端 API Contract |
| [`docs/backend-deployment-notes.md`](docs/backend-deployment-notes.md) | 外部後端部署環境筆記，若有保留              |

> 若 `docs/backend-deployment-notes.md` 不存在，代表後端部署文件不放在此 iOS App repo 中。

---

## Design System

App 內建立了簡易 Design System，使畫面風格一致、元件可重複使用，也方便後續維護。

| Component           | 用途            |
| ------------------- | ------------- |
| `GMTheme`           | 統一顏色、間距、圓角    |
| `GMCard`            | 共用卡片容器        |
| `GMStatCard`        | 首頁數據卡片        |
| `GMDeviceCard`      | 目前綁定裝置卡片      |
| `GMAppHeader`       | 固定頁面標題區       |
| `GMPrimaryButton`   | 主要操作按鈕        |
| `GMMessageCard`     | 成功、警告、錯誤、提示訊息 |
| `GMCopyrightFooter` | 頁尾資訊          |

UI 使用系統自適應色彩，支援深色模式與淺色模式。

---

## 錯誤處理

App 使用集中式 `APIClient` 與 `APIError` 處理網路錯誤。

目前處理的錯誤類型包括：

* 無效 URL
* 無效伺服器回應
* HTTP Server Error
* JSON Decode 失敗
* Request Cancelled
* Unknown Error

這樣可以避免每個 SwiftUI View 直接處理 `URLSession`，使畫面層與資料層分離。

---

## 專案亮點

本專案不是單純的靜態 UI Demo，而是具備實際 API 串接與資料處理流程的 iOS Prototype。

主要亮點：

* SwiftUI App 與外部 Flask API 串接
* MVVM 架構分層
* LINE Login 裝置綁定流程
* iOS Custom URL Scheme 回跳 App
* Swift Charts 握力趨勢圖
* 每日平均資料整理邏輯
* PATCH API 修改目標握力
* AI 訓練回饋顯示
* 深色模式支援
* 共用 Design System 元件
* GitHub 文件化整理

---

## 醫療聲明

GripMind 根據握力紀錄提供訓練資料視覺化與 AI 輔助回饋。

本系統不具備醫療診斷能力，不應被用於診斷、治療、預防疾病，也不能取代醫師、物理治療師或其他專業醫療人員的建議。

若使用者有疼痛、不適或復健相關疑慮，應諮詢專業醫療人員。

---

## 未來規劃

* 加入 API authentication token
* 加入多裝置支援
* 加入 HealthKit 整合
* 加入推播提醒
* 加入離線資料快取
* 加入訓練週報
* 加入 Model 與 ViewModel 單元測試
* 加入 UI Test
* 優化 AI 回饋呈現方式
* 支援更多復健訓練資料類型

---

## License

本專案為開源專案，詳細授權方式請參考 [`LICENSE`](LICENSE)。
