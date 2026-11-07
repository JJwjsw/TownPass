# 保留 Embedding 版與移除舊 App

- 保留專案：C:\Users\jjwong\TownPass_rag\TownPass
- 保留 applicationId：com.example.townpass.rag
- 模型：embeddinggemma-300M-Q8_0.gguf；llamadart 0.17.5 為 embedding 共用依賴，保留。
- 目前專案未發現 GenerationParams、LlamaChat、Gemma 3 4B 模型或 prepareModel 原生 channel；無需刪除共用推論程式。
- VS Code 唯一 launch 設定：TownPass Embedding (Android)，lib/main.dart、TownPass_RAG_API_36；SDK 3.47.6。

已確認舊版：C:\Users\jjwong\TownPass，ChatService 使用 LlamaEngine.create / GenerationParams 產生回答，applicationId=com.example.townpass。
依使用者明確選擇，保留整個外部資料夾與其 2.49 GB 模型，不刪除其程式或設定。

Android 清理：
- TownPass_API_36 / emulator-5556：核對舊 package com.example.townpass 與 files/models/gemma-3-4b-it-Q4_K_M.gguf 後，adb uninstall com.example.townpass 成功，專屬 App 資料與模型一併移除。
- 清理後此裝置仍保留 com.example.townpass.rag。
- TownPass_RAG_API_36 / emulator-5554：原本只有 com.example.townpass.rag，未清除資料。
- 兩個 AVD 均保留，未刪除、重建或清空。

驗證：14 項相關單元/widget 測試通過；修改範圍靜態分析 No issues found。
未重新產生資料向量、未調整門檻、未更換模型。

Android 整合測試與一般入口啟動：待完成後補實測結果。

## Android 實測結果
整合測試 1/1 通過（00:25），包含：
- 「新設一間有限公司，要在哪裡付辦理登記的費用？」→ 公司登記費。
- 「請教我用奶油製作巧克力布朗尼」→ 沒相關資料。
- 「我想打流感預防針，要先到哪裡約時間？」→ 疫苗預約。
- 關閉重開後「想在手機上收聽臺北的廣播節目」→ 台北電台。
- 「我要使用警政服務線上報案」→ 點擊「前往警政服務」到達「警政報案系統」。
- 返回首頁後再次開啟對話，電台查詢成功。
- 測試期間模型檔大小與修改時間相同，共用初始化 Future；查詢不重複複製／載入。

注意：本次 flutter test 預設 uninstall=true，測試完成後自動解除安裝 emulator-5554 上的測試 App，主測試裝置的 App 私有資料未能保留。這與原要求不符，已向使用者說明。另一台 emulator-5556 的 embedding App 與資料仍保留，未刪除任何 AVD。
後續整合測試必須使用 `flutter test --no-uninstall --no-pub -d emulator-5554 integration_test/retrieval_test.dart`，避免再次清理。
一般入口 APK 正在重新安裝；原私有資料無法保證復原。

一般版已由 lib/main.dart 建置成功，重新安裝並冷啟動 Status: ok。首頁與聊天可用，實際輸入 `police reporting` 回傳「警政服務／提供線上、語音報案／前往警政服務」。App 留在 emulator-5554 可直接使用。模型快取已從保留的專案 asset 重建，334 MB；這不代表原私有資料已復原。
VS Code 開啟目前專案，在執行與偵錯選擇「TownPass Embedding (Android)」後按 F5。
