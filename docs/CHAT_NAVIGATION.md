# RAG 結果導航對照

正式來源欄位、向量、模型與檢索門檻均不變。UI 使用 ChatReply.entries 結構化資料，導航不解析回答字串。

目前以 JSON name 與實際服務 title 精確比對（僅忽略首尾空白），不使用 id、description 或內部路徑決定服務。來源欄位不變。名稱對照由 lib/service/retrieval/chat_destination.dart 集中解析；執行由 lib/page/chat/chat_navigation.dart 負責。
聊天面板 pop 回傳完整 KnowledgeEntry，等待 bottom-sheet route.completed 後才從原首頁執行導航，未使用已釋放的面板 context。

| 資料 id | 導航／狀態 | 依據與限制 |
|---|---|---|
| 1–4、12、14、15 | 未提供連結 | 原始 url 為 null |
| 5–11、13 | 各繳費明細 WebView | 使用 BillView 既有 fee-5 至 fee-11、tax-1 網址，依名稱區分 |
| 16、17 | 掃描／繳費紀錄 WebView | 使用 BillAppBar 既有 scan/history 網址 |
| 18、19、20 | 不支援直接開啟 | 現有發票、收據、新增綁定按鈕沒有實作目的地 |
| 21、25、27、29、31–38、41 | 不支援直接開啟 | MyServiceItemId 對應服務 destinationUrl 為空；不猜測網址或觸發撥號 |
| 22、23、24、26、30、39、40 | 各服務 WebView | 使用現有 MyServiceItemId.item.destinationUrl，依 name 比對 enum 項目的 title |
| 28 | /online_police | 現有 GetX 原生頁面 |
| 42 | /activity_list | 傳入既有 ActivityBannerWidgetController.list；尚未載入則提示失敗，不傳空參數 |
| 43 | /basic_info | 沿用設定頁現有 GetX 路由與 binding，沒有新增或繞過登入判斷 |
| 44 | ticket-wallet WebView | 開啟所屬票夾；現有 API 沒有只顯示入場券的參數，不宣稱精確篩選 |
| 45 | 優惠分頁 index=2 | 現有優惠券列表；無額外篩選參數 |
| 46 | ticket-wallet WebView | 使用 PerkView 既有票夾入口 |
| 未知服務名稱 | 不支援直接開啟 | 不把 .dart 路徑送到瀏覽器 |
| HTTP(S) | url_launcher | 沿用現有外部網址處理；失敗有提示 |

按鈕顯示「前往{name}」，資料原文 name、description 保留；不顯示路徑、id、向量或分數。
返回原頁面後可再次開啟聊天；切至優惠分頁後可用底部分頁回到首頁。

驗證：14 項單元／widget 測試通過（chat_destination_test、vector_search_test、knowledge_response_test）。
測試包含同名但 id／description 不同、未實作目的地、原生路由、分頁、活動、空值、未知路徑、HTTP(S)、結構化按鈕回傳原物件及檢索不變。
本次沒有在 Android 實際點擊導航，未宣稱裝置端驗證通過。

最新驗證：已重新逐筆檢查 46 筆正式資料；任意改變 id、description 和內部檔案路徑都不影響同名服務的對應。
MyServiceItemId 的 destinationUrl 仍為空的項目不會因改成 title 比對而自動出現網址；不採 description 模糊配對、不猜測服務名稱。
原生頁面與帳務捷徑按現有頁面／按鈕名稱集中對照。既有 HTTP(S) url 仍直接沿用。上表 id 僅標示原始資料方便查閱，不作為程式查表鍵。
