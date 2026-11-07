# 搜尋閾值調整

目前正式門檻：RetrievalConfig.minSimilarity = 0.35。
個別結果 cosine similarity >= 0.35 才保留，排序後最多三筆；全部低於則顯示「找不到相關結果」。等於門檻仍保留。模型／資料錯誤仍為錯誤，不視為無結果。

依據既有 assets/data/evaluation.json 的真實 Q8_0 推論分數：
- 無關問題最高分 0.29543390218108395。
- 相關問題最低預期命中分數 0.375888715887322。
- 原門檻 0.4021618282031547 漏掉圖書借閱問題。
- 以 0.35 回放，18/18 符合預期。

這是重用既有測試分數評估的起始值，並非新的獨立測試集或保證真實問題全部正確。未重新產生模型向量。
assets/data/evaluation.json 保留原始評估紀錄，內含的舊門檻是歷史值；目前實際值以 RetrievalConfig 為準。
重建工具仍輸出校準建議 suggestedCalibrationThreshold，但不再自動改寫正式門檻。

驗證：vector_search_test 包含18題分數回放、餘弦、排序、門檻相等、無匹配與無效向量。
