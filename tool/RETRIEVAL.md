# 本機向量檢索

正式資料來源：`assets/data/knowledge_raw.json`（46 筆）。
輸出：`assets/data/knowledge.json`。

重建向量與門檻：
```
dart run tool/generate_knowledge.dart
```
驗證欄位保留與向量格式：
```
dart run tool/validate_knowledge.dart
```

使用 Flutter 3.47.6 所附 Dart，並先執行 flutter pub get。
模型：assets/models/embeddinggemma-300M-Q8_0.gguf。
文件：`title: none | text: {name}:{description}`。
查詢：`task: search result | query: {input}`。

完整測試、門檻、失敗案例及 Android 畫面請參閱 `docs/RETRIEVAL_REPORT.md`。
實際資料的非空 url 是程式碼路徑，會原樣顯示，但不作為網頁開啟；HTTP(S) URL 才提供點擊。
