# Edge Functions

包含 `create-meeting-session`、`finish-meeting-session`、`suggest-answer`、`generate-minutes`、`sync-entitlement` 與 `revenuecat-webhook`。所有權益與用量判斷都在後端執行，不信任手機端傳入的方案或剩餘分鐘數。`revenuecat-webhook` 與 `sync-entitlement` 都是讀取 RevenueCat subscriber 後寫入 `entitlements`。
