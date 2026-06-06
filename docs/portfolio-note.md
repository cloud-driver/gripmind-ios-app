# GripMind iOS App｜作品集說明

## 一、作品簡介

GripMind iOS App 是一個智慧握力復健紀錄系統的 iOS 行動端 Client，主要用於協助使用者查看握力訓練資料、追蹤每週復健趨勢、設定目標握力，並接收 AI 產生的訓練回饋。

本作品不是單純的靜態 App 介面，而是一個能與外部 Flask REST API 串接的 iOS Prototype。App 透過 `device_id` 與外部後端連線，取得握力紀錄、使用者 Profile、目標握力與 AI 分析結果，並以 SwiftUI 與 Swift Charts 呈現成可操作、可閱讀的行動介面。

本 repo 僅包含 iOS App 原始碼。後端 API、LINE Login Callback、Ollama AI 整合與伺服器部署為外部服務，不包含在此 repo 中。

---

## 二、開發動機

我希望透過 GripMind 展示自己不只會製作網頁或資料處理工具，也能進一步學習並完成 iOS App 開發，將後端 API、使用者介面、資料視覺化與 AI 回饋整合成一個完整的使用情境。

握力復健紀錄是一個適合行動端呈現的題目，因為使用者需要快速查看訓練狀態、理解近期變化，並在訓練後立即獲得回饋。因此，我將原本的網頁系統延伸成 iOS App，讓專案從「可用的網站」進一步變成「更接近真實產品的行動應用」。

---

## 三、我負責的部分

本作品中，我主要負責 iOS App 的設計與開發，包括：

* SwiftUI App 介面設計
* MVVM 架構規劃
* REST API 串接
* `URLSession async/await` 網路請求處理
* `AppStorage` 本地裝置 ID 儲存
* LINE Login 完成後的 Custom URL Scheme 回跳處理
* Dashboard 首頁資料呈現
* 歷史紀錄資料視覺化
* 每日平均握力資料整理
* 目標握力設定頁
* AI 訓練回饋頁面
* 深色模式與淺色模式 UI 調整
* GitHub README 與 docs 文件整理

---

## 四、主要功能

### 1. 首次裝置綁定

使用者第一次開啟 App 時，需輸入裝置 ID。App 會開啟外部後端提供的 LINE Login 綁定頁，完成登入後，後端透過 Custom URL Scheme 導回 App。

App 收到回跳後，會呼叫 Profile API 確認綁定是否成功，成功後將 `device_id` 儲存在本機。之後使用者不需要每次重新輸入裝置 ID。

### 2. 首頁 Dashboard

首頁顯示當日握力訓練摘要，包括：

* 今日訓練次數
* 目標握力
* 今日最高握力
* 今日平均握力
* 最近一次訓練紀錄
* LINE 綁定狀態

首頁也支援下拉重新整理，讓使用者能即時取得最新資料。

### 3. 每週歷史紀錄

歷史紀錄頁會顯示每週握力趨勢。由於同一天可能會有多筆握力紀錄，如果直接全部畫在圖表上，畫面會變得擁擠且不易閱讀。

因此，我在 App 端將同一天的多筆紀錄整理成「每日平均握力」，再用 Swift Charts 呈現折線圖。這樣可以讓使用者更清楚觀察每週訓練變化。

### 4. 目標握力設定

使用者可以在設定頁修改目標握力。App 會自動使用已綁定的裝置 ID 呼叫後端 PATCH API，不需要使用者重複輸入裝置資訊。

### 5. AI 訓練回饋

AI 頁面會呼叫外部後端的 AI 分析 API，後端再透過 Ollama 產生訓練回饋。App 負責顯示 AI 建議與醫療免責聲明，避免使用者將系統誤解為醫療診斷工具。

---

## 五、技術實作重點

### SwiftUI 與 MVVM 架構

本 App 採用 MVVM 架構，將畫面、資料狀態與 API 串接邏輯分開：

```text
View
  → ViewModel
  → APIClient
  → External Backend API
```

這樣可以避免 SwiftUI View 中混入過多網路請求與資料處理邏輯，使專案更容易維護與除錯。

### APIClient 集中管理網路請求

我將所有 API 呼叫集中在 `APIClient.swift` 中處理，包括：

* 建立 URL
* 發送 HTTP Request
* Decode JSON Response
* 處理 HTTP status code
* 處理 cancelled request
* 統一轉換 API error

這讓每個 ViewModel 不需要直接操作 `URLSession`，也讓錯誤處理更一致。

### Swift Charts 資料視覺化

歷史紀錄頁使用 Swift Charts 呈現握力趨勢。為了讓圖表更適合閱讀，我不是直接將所有原始紀錄畫上去，而是先在 `HistoryViewModel` 中進行資料整理：

```text
Raw grip records
  → Parse timestamp
  → Group by day
  → Calculate daily average
  → Filter selected week
  → Display with Swift Charts
```

這個設計讓資料呈現更符合使用者觀察趨勢的需求。

### AppStorage 本地狀態保存

App 使用 `@AppStorage("savedDeviceId")` 儲存目前綁定的裝置 ID。使用者完成首次綁定後，App 會自動記住裝置，不需要在首頁、紀錄頁、AI 頁、設定頁重複輸入。

### Custom URL Scheme 回跳

LINE Login 完成後，後端會透過：

```text
gripmind://bind-success
```

將使用者導回 iOS App。App 會接收此 URL，並繼續完成 Profile 驗證與裝置保存流程。

### Design System

為了讓 UI 更一致，我建立了簡易 Design System：

* `GMTheme`
* `GMCard`
* `GMStatCard`
* `GMDeviceCard`
* `GMAppHeader`
* `GMPrimaryButton`
* `GMMessageCard`
* `GMCopyrightFooter`

這讓不同頁面的卡片、按鈕、標題與顏色有一致的規格，也讓深色模式與淺色模式更容易維護。

---

## 六、遇到的問題與解決方式

### 問題一：LINE Login 完成後無法回到 App

原本後端登入流程是網頁版流程，LINE Login 完成後只會導回網頁。為了讓 iOS App 能接續流程，我加入了 `client=ios` 與 `app_callback_url` 概念，讓後端完成綁定後可以導回：

```text
gripmind://bind-success
```

App 再透過 `.onOpenURL` 接收回跳並驗證裝置綁定狀態。

### 問題二：歷史紀錄下拉刷新沒有立即更新

在開發過程中，我發現歷史紀錄頁有時需要切換頁面後才會看到新資料。後來釐清可能與快取、ViewModel 狀態與 API 重新請求有關。

我在 App 端加入 `_refresh` query parameter，並設定 request cache policy，避免拿到舊資料。同時在 ViewModel 中調整刷新流程，使下拉重新整理能重新呼叫 API。

### 問題三：同一天多筆資料造成圖表擁擠

若每筆握力紀錄都直接畫在圖表上，同一天多筆資料會擠在一起，導致圖表難以閱讀。因此我將同一天資料整理成每日平均握力，讓圖表更適合觀察長期趨勢。

### 問題四：深色模式下部分文字看不清楚

一開始部分 UI 使用固定白色或黑色背景，導致深色模式下出現白底白字或對比不足的問題。後來我改用系統自適應色彩，例如 `Color.primary`、`Color.secondary`、`systemGroupedBackground`，讓 App 在深色與淺色模式下都能正常閱讀。

---

## 七、學習收穫

透過這個專案，我實際練習到從 iOS App 到後端 API 串接的完整流程，也理解到 App 開發不只是把畫面做出來，更重要的是資料流、錯誤處理、使用者流程與系統整合。

我在本專案中學到：

* SwiftUI App 架構設計
* MVVM 分層概念
* REST API 串接
* JSON Decode 與資料模型設計
* Swift Charts 資料視覺化
* iOS Custom URL Scheme
* LINE Login App 回跳流程
* 深色模式 UI 適配
* GitHub 文件化與作品整理
* 如何把一個網頁系統延伸為行動端 App

---

## 八、與資工能力的關聯

GripMind iOS App 展示了我在資訊工程領域中逐步累積的實作能力。這個作品不只包含 UI 設計，也涵蓋資料處理、API 串接、系統架構理解、狀態管理與外部服務整合。

此作品能對應到資工學習中的多個面向：

* 軟體工程：專案架構、模組分離、文件撰寫
* 行動應用開發：SwiftUI、AppStorage、URL Scheme
* 資料處理：歷史紀錄整理、每日平均計算、週次篩選
* 資料視覺化：Swift Charts 折線圖
* 網路程式設計：REST API、JSON、HTTP status handling
* 系統整合：iOS App、Flask API、LINE Login、Ollama AI
* 人機介面：Dashboard、設定頁、錯誤提示、深色模式

---

## 九、未來改進方向

若繼續完善此專案，我會優先改進以下方向：

1. 加入正式 API authentication token
2. 支援多裝置管理
3. 加入 HealthKit 整合
4. 加入推播提醒
5. 加入離線快取
6. 加入訓練週報
7. 增加 Model 與 ViewModel 單元測試
8. 加入 UI Test
9. 優化 AI 訓練回饋 prompt
10. 支援更多復健訓練資料類型

---

## 十、作品定位總結

GripMind iOS App 是我將原本網頁系統延伸為行動端 App 的實作成果。它展示了我從需求情境、API 串接、資料視覺化、使用者流程到 GitHub 文件整理的完整開發能力。

雖然目前仍是 Prototype，但它已具備完整的 App 使用流程，也能串接外部後端服務取得真實資料。對我而言，這個作品不只是一次 iOS 開發練習，更是一次把不同技術整合成完整系統的實作經驗。
