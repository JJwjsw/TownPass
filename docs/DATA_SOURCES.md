# 資料來源清單

本清單區分資料在目前 App 中的用途與可確認來源，不將頁面連結當成資料授權證明。

| 名稱 | 專案位置 | 可確認來源／連結 | 性質與限制 |
|---|---|---|---|
| 市政服務檢索索引 | `assets/data/knowledge_raw.json` | 專案使用者提供的 46 筆服務整理；可對照 `lib/page/city_service/model/my_service_model.dart`、帳務與優惠頁面 | 非即時政府 API；沒有逐筆正式發布網址、擷取日期或資料授權，須交付者補齊。不屬於先前 AI 產生的五筆測試假資料 |
| 市政服務文件向量 | `assets/data/knowledge.json` | 上列索引與指定 EmbeddingGemma Q8_0 模型推論 | 衍生向量；id、name、description 原文保留，url 依規則正規化，不能視為新獨立來源 |
| 測試題及評估 | `tool/retrieval_cases.json`、`assets/data/evaluation.json` | 開發時編寫的 18 題問題及模型分數 | 測試／合成問題，不是政府公開資料，也不是正式效果保證 |
| 示範帳號 | `assets/mock_data/account.json` | 隨專案提供，`AccountService.init()` 讀取 | **模擬資料**；非真實會員後端。姓名、聯絡資訊等不可當作已驗證個資 |
| 活動列表 | `assets/mock_data/activity.json` | 隨專案提供；上游專案參考：[TownPass](https://github.com/taipei-doit/TownPass) | **頁面展示／模擬資料**，不保證現行活動與日期有效；逐筆內容權利待確認 |
| 首頁輪播 | `assets/mock_data/home_banner.json` | 同上 | **頁面展示／模擬資料**，圖片及連結權利待確認 |
| 訊息 | `assets/mock_data/message.json` | 同上 | **模擬資料**，不是正式通知來源 |
| 訂閱 | `assets/mock_data/subscription.json` | 同上 | **模擬資料**，不是正式訂閱後端 |
| 外部服務入口 | `lib/service/retrieval/chat_destination.dart`、`lib/page/city_service/model/my_service_model.dart` | `https://taipei-pass-service.vercel.app/` 及個別設定網址；儀表板為 `https://dashboard.gov.taipei/` | 導航目的地，不是本地 JSON 來源證明。Vercel 頁面視為目前原型整合入口，不宣稱正式市政 API |
| 模型權重 | `assets/models/embeddinggemma-300M-Q8_0.gguf` | [ggml-org](https://huggingface.co/ggml-org/embeddinggemma-300M-GGUF)、[Google 原模型](https://huggingface.co/google/embeddinggemma-300m) | 第三方模型資產；模型與授權揭露見 README |

## 正式資料交付需要補的欄位

若要將索引標示為正式政府資料，請逐筆補上資料發布單位、原始資料集名稱、可存取的來源網址、取得日期、更新頻率及授權依據。現有 JSON 的 `url` 很多是 Dart 原始碼路徑，只表示功能位置，不能用作上述資料來源欄位。

目前本地向量檢索不需要另外啟動後端；外部服務、語音服務、裝置定位與通知的行為各自獨立，不能因此宣稱整個 App 全離線或已與正式後端串接。
