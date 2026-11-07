# 正式資料檢索實作與測試

## 重建方式
使用專案 Flutter 3.47.6 所附 Dart，在專案根目錄執行：

```
dart run tool/generate_knowledge.dart
dart run tool/validate_knowledge.dart
flutter test --no-pub test/vector_search_test.dart test/knowledge_response_test.dart
flutter test --no-uninstall --no-pub -d emulator-5554 integration_test/retrieval_test.dart
```

實際來源為 `assets/data/knowledge_raw.json`（並非根目錄 data/），共 46 筆。可將其他來源路徑作為 generate_knowledge.dart 第一個參數。
輸出為 `assets/data/knowledge.json`；詳細檢索分數與預期／實際結果為 `assets/data/evaluation.json`；測試題在 `tool/retrieval_cases.json`，在量測前固定預期。

模型 `assets/models/embeddinggemma-300M-Q8_0.gguf`，333590944 bytes，SHA256 b5ce9d77a3fc4b3b39ccb5643c36777911cc4eb46a66962eadfa3f5f60490d63。
使用 llamadart 0.17.5 / llama.cpp CPU worker、GGUF 預設 pooling、normalize=true、768 維；文件為 `title: none | text: {name}:{description}`，查詢為 `task: search result | query: {input}`。
資料工具已對 46 筆逐筆實際推論，沒有沿用舊向量，失敗 id 為空。完整性工具已確認逐筆 id（保留數字型別）、name、description、正規化 url 與來源相同，向量為非零有限 768 維。

## 連結資料的實際限制
來源中的非空 url 都是 `lib/...dart` 程式路徑，沒有 HTTP(S) 網址。
這些字串原樣保留並顯示，不編造映射、不作為網頁開啟。null/NaN/空白/大小寫 nan 或 null 會轉為 JSON null，顯示「未提供連結」。
只有 HTTP(S) 且具有主機名稱的完整連結可點擊。有效外部網址使用獨立 fixture 測試，不混入正式資料。
非標準裸 NaN 的解析採逐字掃描，只處理字串外的完整 token，帶引號文字不變。

## 門檻與檢索結果
校準組 9 題，獨立驗證組 9 題，均包含五個不同主題正例、兩個完全無關負例、兩個關鍵字相同但意圖無關負例。
校準最低正例 0.5088897542252255，最高負例 0.29543390218108395；取中點 0.4021618282031547。
校準 9/9 符合預期；獨立驗證 8/9。
失敗案例：「我想借閱北市圖的小說」，預期 id=39，實測 0.375888715887322，低於門檻而回覆「沒相關資料」。保留失敗紀錄，未使用此題重新調門檻。
部分查詢會同時出現其他超過門檻的候選，例如公司規費查詢會回傳公司與商業登記費，屬依門檻取前三筆的預期行為。

## 自動測試
8 項單元／widget 測試全部通過：餘弦計算、非有限值、零向量、維度、分數排序、數字 id 同分排序、門檻等於、最多三筆、少於三筆不補、無匹配、NaN、原文格式、有效連結點擊與開啟失敗、資料損壞不可當無匹配。
靜態分析（修改範圍與整合測試）No issues found。
完整專案在前次分析已有 25 個其他警告／提示；本次不修改那些無關程式。
原有 test/widget_test.dart 是與實際 App 不符的 counter 範本，未將其當作本功能測試。

## Android 驗證
依使用者後續指示，驗收範圍縮為正常查詢與回答，不繼續 URL 測試。
先前測試中已觀察到公司登記費、疫苗預約、無關問題與關閉重開後電台問題均成功；正在以移除 URL 流程的整合測試完成最終驗證。
先前測試腳本曾因未等待按鈕更新、外部瀏覽器生命週期而中止，已調整腳本；不將中止的整段測試宣稱為通過。


