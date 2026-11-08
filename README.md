# TownPass：本機市政服務檢索

本專案以臺北市政府 TownPass Flutter 專案為基礎，加入本機語意檢索聊天介面。使用者可打字或語音輸入問題，由 EmbeddingGemma 將問題轉成向量，再從服務資料中找出相關項目並提供導航卡片。

目前是 embedding 檢索版本，沒有生成式 LLM 回答、雲端 AI API 或另外啟動的向量資料庫。回答的名稱與說明來自資料原文；系統語音辨識及外部服務網頁則可能需要網路。

- 主要驗證平台：Windows 開發環境、Android 16／API 36 模擬器。
- Android applicationId：`com.example.townpass.rag`。
- App 入口：`lib/main.dart`。
- Flutter：`3.47.6`；該 SDK 所附 Dart：`3.13.5`，以 `.fvmrc` 為準。
- 原始 TownPass：[專案](https://github.com/taipei-doit/TownPass)、[文件](https://townpass.taipei/en/docs/)。

## 功能

- 「服務、首頁、優惠、帳務」四個底部分頁共用聊天入口。
- 聊天按鈕可拖曳；閒置五秒後淡化，觸碰恢復。
- 繁體中文文字輸入、原生鍵盤及傳送按鈕左側的語音輸入按鈕。
- 語音辨識文字填入輸入框，由使用者確認後送出，不自動查詢。
- 依餘弦相似度篩選、排序，最多顯示三張結果卡片。
- 卡片顯示分類、名稱、說明及導航箭頭；有入口時整張卡片可點擊。
- 所有候選低於閾值時顯示「找不到相關結果」。

## 1. 開發環境

安裝以下工具：

| 工具 | 本專案設定 |
|---|---|
| Flutter / Dart | Flutter 3.47.6，建議用 FVM 固定版本 |
| VS Code | Flutter 與 Dart 擴充套件 |
| Android SDK | Platform 36、Platform Tools、Emulator |
| Android NDK | 29.0.13113456 |
| Java | 與 Gradle／AGP 相容的 JDK 17 以上版本，使用 `flutter doctor -v` 確認 |
| Gradle / AGP | Wrapper 9.3.1／Android Gradle Plugin 9.1.0，依專案設定下載 |

建議開發電腦至少 16 GB RAM；模擬器可先配置約 4 GB RAM。此為實作建議，不是已量測的最低硬體需求。須保留模型、App 安裝及首次複製模型所需空間；多架構 debug APK 會明顯大於模型本身。

以下指令皆在專案根目錄執行。首次安裝套件、Gradle、NDK 與原生推論執行庫需網路。

```powershell
fvm install
fvm flutter doctor -v
fvm flutter doctor --android-licenses
fvm flutter pub get
```

若沒有使用 FVM，請將以下指令中的 `fvm flutter`／`fvm dart` 替換成 Flutter 3.47.6 的 `flutter`／`dart`。

### 公開 repo 未包含的本機資產

模型權重與尚未確認可再散布的 PingFangTC 字型不提交一般 Git，既有本機檔案保留。
首次 clone 必須先依下方下載模型，並依 [字型準備](fonts/README.md) 補齊合法取得的字型，才可完成建置。

### 產生程式碼

本專案的圖片資源類別與 JSON 類別由工具產生，部分產物受 `.gitignore` 排除。首次取得原始碼後執行：

```powershell
fvm dart run build_runner build --delete-conflicting-outputs
```

## 2. 模型準備與 AI 揭露

| 項目 | 設定 |
|---|---|
| 原始模型 | Google EmbeddingGemma 300M；不是 EmbeddingGemma 2 |
| GGUF 發布者 | ggml-org |
| 模型檔 | `embeddinggemma-300M-Q8_0.gguf` |
| 格式／量化 | GGUF／Q8_0（8-bit） |
| 檔案大小 | 333,590,944 bytes，約 334 MB |
| 已下載檔案 SHA-256 | `b5ce9d77a3fc4b3b39ccb5643c36777911cc4eb46a66962eadfa3f5f60490d63` |
| Dart 推論套件 | llamadart 0.17.5 |
| 原生推論 | llama.cpp，CPU，4 threads，GPU layers = 0 |
| 上下文／batch／micro-batch | 2048／2048／2048 |
| 向量維度／正規化 | 768／L2 normalization |
| Pooling | 沿用 GGUF metadata 的預設，不另指定 |
| 用途 | 文件與問題的文字 embedding，不生成自然語言回答 |

來源：[GGUF 模型](https://huggingface.co/ggml-org/embeddinggemma-300M-GGUF)、[原始模型](https://huggingface.co/google/embeddinggemma-300m)、[模型卡](https://ai.google.dev/gemma/docs/embeddinggemma/model_card)、[llamadart 文件](https://llamadart.leehack.com/docs/guides/embeddings)。

檢查下列檔案已存在，且不是 Git LFS pointer 文字檔：

```text
assets/models/embeddinggemma-300M-Q8_0.gguf
```

若尚未取得模型，可依模型發布頁取得 Q8_0 檔，或在 PowerShell 執行：

```powershell
New-Item -ItemType Directory -Force assets/models | Out-Null
Invoke-WebRequest `
  -Uri 'https://huggingface.co/ggml-org/embeddinggemma-300M-GGUF/resolve/0f741b5/embeddinggemma-300M-Q8_0.gguf?download=true' `
  -OutFile assets/models/embeddinggemma-300M-Q8_0.gguf
Get-FileHash assets/models/embeddinggemma-300M-Q8_0.gguf -Algorithm SHA256
```

將雜湊與上表比對；不同時先確認模型版本，勿混用既有向量。若來源平台要求接受模型條款或登入，請依官方流程取得，不將存取憑證寫入專案。

模型權重依 [Gemma Terms of Use](https://ai.google.dev/gemma/terms) 處理，與 Dart 套件或專案程式碼的授權分開；不宣稱模型權重是 AGPL 或所有元件都採相同授權。

## 3. 資料準備

目前已有以下檔案；一般建置不必重新產生向量：

| 檔案 | 用途 |
|---|---|
| `assets/data/knowledge_raw.json` | 46 筆服務索引文字，原始輸入 |
| `assets/data/knowledge.json` | 保留原始欄位並加入真實模型向量的檢索資料 |
| `assets/data/evaluation.json` | 歷史模型評估分數，內含當時的門檻 |
| `tool/retrieval_cases.json` | 18 題測試問題、分組及預期命中 id |

每筆輸出格式為 `id`、`name`、`description`、`url`、`vector`。`vector` 是 768 維有限非零數值陣列；不使用隨機或補零向量。

文件與查詢分別使用：

```text
文件：title: none | text: {name}:{description}
查詢：task: search result | query: {使用者輸入}
```

更換資料內容或模型時，須重新產生對應文件向量：

```powershell
fvm dart run tool/generate_knowledge.dart
fvm dart run tool/validate_knowledge.dart
```

第一個工具會覆寫 `knowledge.json` 與 `evaluation.json`，使用相同 GGUF 實際推論；失敗時列出資料 id。預設來源是 `assets/data/knowledge_raw.json`，亦可透過第一個參數指定其他來源檔。現有測試題依目前 46 筆資料編寫，更換資料／id 時也須更新測試題。

工具會記錄校準建議，不會自動覆寫正式閾值。`url` 的 null、NaN、空白與字串 nan/null 會正規化為 null；原始碼路徑不會當成 HTTP 網址。

資料來源與模擬資料標示詳見 [資料來源清單](docs/DATA_SOURCES.md)。

## 4. 啟動 Android 版本

### VS Code

1. 開啟這份專案的根目錄，不要開到舊的生成式 LLM 專案。
2. `.vscode/settings.json` 目前有開發者本機 SDK 絕對路徑；接手時改為自己的 Flutter 3.47.6 SDK 路徑，或透過 VS Code 選擇 SDK。
3. 先建立／啟動自己的 Android 模擬器。現有開發環境名稱為 `TownPass_RAG_API_36`；其他電腦需自行建立，或修改 `.vscode/launch.json` 的 `emulatorId`。
4. 選擇 **TownPass Embedding (Android)**，按 F5。入口必須是 `lib/main.dart`。

既有開發目錄為 `C:\Users\jjwong\TownPass_rag\TownPass`，只作辨識用途，其他電腦不必使用相同路徑。

### 終端機

在一般 Windows PowerShell 設定 SDK 路徑；若 SDK 裝在別處請自行替換：

```powershell
$androidSdk = "$env:LOCALAPPDATA\Android\Sdk"
& "$androidSdk\emulator\emulator.exe" -list-avds
```

另開終端機或透過 IDE 啟動已存在的模擬器：

```powershell
& "$androidSdk\emulator\emulator.exe" -avd TownPass_RAG_API_36 -no-snapshot-load -allow-host-audio
```

`-no-snapshot-load` 是保留使用者資料的冷啟動，不是 Wipe Data。啟動後於專案根目錄執行：

```powershell
fvm flutter devices
fvm flutter run -d emulator-5554 -t lib/main.dart
```

裝置 id 以 `flutter devices` 實際輸出為準，不保證永遠是 `emulator-5554`。

開啟 App 後，可從任一底部分頁的浮動聊天按鈕輸入：

```text
我要使用警政服務線上報案
我想打流感預防針，要先到哪裡約時間？
請教我用奶油製作巧克力布朗尼
```

前兩題用於相關服務檢索，最後一題用於無關內容測試。部分服務沒有已實作的導航目的地，能找到內容不代表可直接開啟服務。

### 中文鍵盤與語音

- Android 設定 → 螢幕鍵盤 → Gboard → Languages → 加入「繁體中文（台灣）／注音」，完成必要下載。
- 若接著電腦鍵盤卻不顯示螢幕鍵盤，可啟用：

  ```powershell
  & "$androidSdk\platform-tools\adb.exe" -s emulator-5554 shell settings put secure show_ime_with_hard_keyboard 1
  ```

- 模擬器預設可能不傳入主機音訊；每次重啟後可執行：

  ```powershell
  & "$androidSdk\platform-tools\adb.exe" -s emulator-5554 emu avd hostmicon
  ```

- Windows 必須允許桌面應用程式存取麥克風，並選到正確的輸入裝置。
- 聊天框的麥克風按鈕使用 Android `RecognizerIntent`，指定 `zh-TW`；裝置需安裝可處理語音辨識的服務。本機測試使用 Google 系統語音服務。辨識是否連網／能否離線由系統服務決定，本專案沒有自建語音模型。
- 先前出現手寫工具列時，本機以 Android 設定 `stylus_handwriting_enabled=0` 切回一般鍵盤；這是模擬器輸入法設定，不是中文語言包的一部分。

## 5. 檢索與導航規則

```text
使用者輸入 → EmbeddingGemma 查詢向量 → 與所有資料向量計算 cosine similarity
→ 保留分數 >= 0.35 → 由高到低取最多三筆 → 顯示卡片 → 點擊導航
```

- 正式門檻集中在 `lib/service/retrieval/vector_search.dart` 的 `RetrievalConfig.minSimilarity`。
- 全部低於門檻／有效資料為空：顯示「找不到相關結果」。
- 模型載入、資料格式或推論失敗會顯示錯誤，不混同無相關結果。
- 同分時使用 id 穩定排序；導航則依 JSON `name` 比對既有服務 `title`，不使用 description 配對。
- 保留 JSON 原始欄位；卡片不顯示向量、分數或原始碼路徑。
- `destinationUrl` 有值才沿用服務網址；警政、基本資料等原生頁面有對應路由。空網址不會自動補造目的地。
- 模型在首次查詢時由 assets 複製到 App 私有儲存空間；同一 App 程序共用載入結果。重啟程序會重載模型，但不重複複製已存在的檔案。

詳見 [導航對照](docs/CHAT_NAVIGATION.md)、[門檻依據](docs/SEARCH_THRESHOLD.md)、[互動說明](docs/CHAT_INTERACTION.md)。門檻 0.35 是依既有小型測試集選出的起始值，不保證所有真實問題均正確。

## 6. 建置與測試

```powershell
fvm flutter build apk --debug -t lib/main.dart
```

APK 輸出：`build/app/outputs/flutter-apk/app-debug.apk`。更新安裝可使用 `adb install -r`；不需要解除安裝或清除資料。

目前 release 設定仍使用 debug signing，僅供開發展示；正式發布前需設定自己的簽章，不將目前建置視為正式上架產物。

單元／widget 測試：

```powershell
fvm flutter test test/vector_search_test.dart test/chat_destination_test.dart test/knowledge_response_test.dart test/chat_interaction_test.dart test/speech_input_test.dart
```

Android 整合測試：

```powershell
fvm flutter test --no-uninstall -d emulator-5554 integration_test/retrieval_test.dart
```

**務必保留 `--no-uninstall`。**Flutter 整合測試預設的結束清理可能解除安裝 App；本專案曾因此失去測試裝置私有資料。測試前仍應備份重要資料。整合測試會安裝測試入口，完成後重新執行 `flutter run -t lib/main.dart` 回到一般 App。

```powershell
fvm flutter analyze
```

測試範圍包含向量計算、閾值、排序、資料解析、title 對照、卡片操作、拖曳／淡化、鍵盤與語音文字填入。`test/widget_test.dart` 仍是原始 counter 範本，尚未改為本 App 的有效測試；不能把全目錄測試都宣稱為通過。專案其他頁面也仍有既有靜態分析提示。

歷史驗證與限制：[檢索報告](docs/RETRIEVAL_REPORT.md)、[版本整理紀錄](docs/EMBEDDING_CLEANUP.md)。歷史報告可能記錄舊門檻或舊 UI，當前行為以程式設定及本 README 為準。

## 7. 專案結構

```text
lib/main.dart                            App 入口與服務初始化
lib/page/main/                           四分頁共用容器
lib/page/chat/                           面板、結果卡片、拖曳按鈕、導航
lib/service/chat_service.dart            模型初始化與檢索協調
lib/service/retrieval/                   embedding、JSON、cosine、閾值與 title 導航對照
lib/service/speech_input_service.dart    Flutter 到 Android 語音辨識的通道
android/app/src/main/kotlin/.../         Android 系統語音辨識入口
assets/models/                          Q8_0 模型檔
assets/data/                            原始索引、文件向量與歷史評估
assets/mock_data/                       帳號、活動等頁面模擬資料
fonts/                                  字型資源（散布權限待確認）
tool/                                   向量產生、驗證與測試題
test/、integration_test/                 自動測試
docs/                                   來源、套件、導航及驗證說明
```

## 8. 資料來源、第三方套件與授權

- [資料來源清單](docs/DATA_SOURCES.md)：區分專案整理的索引、模擬資料與外部服務。
- [第三方套件清單](docs/THIRD_PARTY.md)：依本機已解析套件及 LICENSE 盤點，含版本與待確認項目。
- 現有 [LICENSE](LICENSE) 是 **GNU GPL version 3**，不是圖片繳交要求所列的 AGPL-3.0。本次只撰寫文件，沒有替換原授權；提交前需由專案權利人確認與主辦指定授權聲明的處理方式。
- `fonts/PingFangTC-*.otf` 沒有在專案內找到附帶授權文件，尚不能宣稱可自由再散布。圖片、SVG、原始模擬資料與模型權重也應分別確認來源／條款，不能僅以程式碼 LICENSE 涵蓋所有資產。



