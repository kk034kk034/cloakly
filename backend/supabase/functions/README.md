# Edge Functions

`project-question` 接收本機檢索的專案片段，產生附來源 ID 的回答；沿用登入及 Hosted AI 權益檢查。最多 16 個來源、48,000 字元 evidence、2,000 字元問題。需另外部署此 endpoint；詳見 [專案問答](../../../docs/project-questions.md)。

`project-plan` 依本機檢索片段建議可追蹤工作，並以 `phase` 欄位拆成可陸續封存的階段（每階段建議 4～10 項）。App 甘特圖可手動維護或審核後套用 AI 建議；完成的階段可封存，不佔看板版面。所有 AI endpoint 都會回傳模型及輸入／輸出 token 用量；專案問答、回答提示、會議紀錄與計畫輔助分別設有輸出上限。

包含 `create-meeting-session`、`finish-meeting-session`、`suggest-answer`、`generate-minutes`、`sync-entitlement` 與 `revenuecat-webhook`。所有權益與用量判斷都在後端執行，不信任手機端傳入的方案或剩餘分鐘數。`revenuecat-webhook` 與 `sync-entitlement` 都是讀取 RevenueCat subscriber 後寫入 `entitlements`。
