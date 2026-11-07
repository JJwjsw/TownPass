# Export the locally resolved Dart/Flutter package inventory without network access.
$ErrorActionPreference = 'Stop'
$workspaceRoot = Split-Path -Parent $PSScriptRoot
$packageConfigPath = Join-Path $workspaceRoot '.dart_tool/package_config.json'
$packageConfigUri = [Uri]::new($packageConfigPath)
$configuration = Get-Content -LiteralPath $packageConfigPath -Raw | ConvertFrom-Json
$rows = [Collections.Generic.List[string]]::new()
$rows.Add('# 第三方套件與授權盤點')
$rows.Add('')
$rows.Add('依 .dart_tool/package_config.json 的本機已解析套件與各套件 LICENSE 文字產生，含直接、遞移、開發與 SDK 套件；版本以 pubspec.lock／已解析 SDK 為準。這是盤點清單，不取代原文著作權聲明或完整授權審查。')
$rows.Add('')
$rows.Add('更新方式：先 flutter pub get，再執行 powershell -File tool/export_third_party_licenses.ps1。未辨識的授權明確標示待確認。')
$rows.Add('')
$rows.Add('| 套件 | 已解析版本 | LICENSE 文字辨識 | 授權來源 |')
$rows.Add('|---|---|---|---|')
$count = 0
foreach ($package in ($configuration.packages | Sort-Object name)) {
    if ($package.name -eq 'town_pass') { continue }
    $rootUri = [Uri]::new($packageConfigUri, [string]$package.rootUri)
    $rootPath = $rootUri.LocalPath
    $manifestPath = Join-Path $rootPath 'pubspec.yaml'
    $version = 'SDK／未標示'
    if (Test-Path -LiteralPath $manifestPath) {
        $manifest = Get-Content -LiteralPath $manifestPath -Raw
        if ($manifest -match '(?m)^version:\s*([^\s#]+)') { $version = $Matches[1].Trim("'",'"') }
    }
    $licensePath = Join-Path $rootPath 'LICENSE'
    $text = if (Test-Path -LiteralPath $licensePath) { Get-Content -LiteralPath $licensePath -Raw } else { '' }
    $labels = [Collections.Generic.List[string]]::new()
    if ($text -match 'Apache License') { $labels.Add('Apache-2.0') }
    if ($text -match 'Permission is hereby granted, free of charge') { $labels.Add('MIT') }
    if ($text -match 'Redistribution and use') {
        if ($text -match 'Neither the name') { $labels.Add('BSD-3-Clause') } else { $labels.Add('BSD 系列（詳見原文）') }
    }
    $licenseLabel = if ($labels.Count -gt 0) { $labels -join ' / ' } else { '待確認（未辨識或未附 LICENSE）' }
    $name = $package.name
    $link = if ($rootUri.AbsoluteUri -match '/hosted/pub.dev/') { "[LICENSE](https://pub.dev/packages/$name/versions/$version/license)" } else { '[SDK 原始碼](https://github.com/flutter/flutter)' }
    $rows.Add("| $name | $version | $licenseLabel | $link |")
    $count++
}
$rows.Add('')
$rows.Add("共 $count 個已解析套件。清單含開發工具，並非每個套件都會包入 release App。")
$rows.Add('')
$rows.Add('## 其他第三方元件與資產')
$rows.Add('')
$rows.Add('| 元件 | 來源／授權依據 | 待確認事項 |')
$rows.Add('|---|---|---|')
$rows.Add('| llama.cpp | [ggml-org/llama.cpp](https://github.com/ggml-org/llama.cpp)，MIT | 保留所使用原生執行庫版本的通知；不能僅以 Dart 套件清單取代原生元件盤點 |')
$rows.Add('| llamadart 原生執行庫及其 bundled libraries | 套件 build hook 取得，依各發行包 LICENSE／NOTICE | 發布前仍須盤點 Android／原生轉依賴，不將此表宣稱為完整 native SBOM |')
$rows.Add('| EmbeddingGemma 300M Q8_0 權重 | [模型卡](https://ai.google.dev/gemma/docs/embeddinggemma/model_card)、[Gemma Terms](https://ai.google.dev/gemma/terms) | 不套用 Dart 套件或專案 GPL；另附模型要求的聲明 |')
$rows.Add('| Android 系統語音服務／Gboard | 使用者裝置安裝的服務，非本專案重新散布 | Google 服務不在本專案開源授權涵蓋範圍，可能需要網路 |')
$rows.Add('| PingFangTC 字型 | fonts/PingFangTC-*.otf | 專案未找到字型授權書，散布權限待確認；不宣稱自由字型 |')
$rows.Add('| SVG、圖片與示範內容 | assets/svg、assets/image、assets/mock_data | 保留上游來源，逐項確認資產權利與引用需求 |')
$rows.Add('')
$rows.Add('Flutter 建置產物另含 NOTICES.Z。交付時需一併保留實際版本的授權原文與通知；本清單不能直接證明所有套件／模型／資產皆可無條件免費再散布。')
$outputPath = Join-Path $workspaceRoot 'docs/THIRD_PARTY.md'
Set-Content -LiteralPath $outputPath -Value $rows -Encoding utf8
Write-Output "Exported $count package entries to docs/THIRD_PARTY.md"
