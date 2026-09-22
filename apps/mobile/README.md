# Cloakly Mobile

Android 與 iOS 的官方 Hosted 應用程式入口。它提供 Supabase Email／密碼登入，透過 RevenueCat 顯示、購買和恢復訂閱，並把轉寫與 AI 請求送到 `../../backend/supabase`。

Soniox 與 OpenAI 長效金鑰不得加入此目錄或編譯進 App。

## 啟動

複製 `config/example.json` 為不進版控的 `config/local.json`，填入 Supabase publishable key 與 RevenueCat 的 Apple／Google 公開 SDK key，再執行：

```powershell
flutter devices
flutter run -d <device-id> --dart-define-from-file=config/local.json
```

未設定 RevenueCat key 時仍可註冊、登入與使用免費額度，但訂閱商品不會顯示。商店 SDK 初始化失敗時（例如沒有 Play 商店的模擬器）也不會擋住登入。手機版不支援 Windows target；桌面版請從 `../desktop` 啟動。

## RevenueCat

App User ID 使用 Supabase user UUID。登入後會 `logIn` 綁定，登出或換帳號會先 `logOut`，避免兩個真實帳號被 alias 成同一位顧客。

Dashboard 最少需要：

1. Entitlement 識別碼 `pro`（或與 `REVENUECAT_ENTITLEMENT_ID` 相同）
2. App Store / Google Play 的月繳與年繳自動續訂商品
3. 一個 Current Offering，內含上述商品
4. Webhook 指向 `revenuecat-webhook`，Authorization 與後端 secret 完全相同
5. Restore behavior 維持預設：已識別使用者之間用 Transfer

購買、恢復與登入後，App 會呼叫 `sync-entitlement`；商店狀態仍以 webhook 與後端 `entitlements` 表為準。免費額度用盡時，會議開始失敗會引導到「帳號與訂閱」。

## 商店／內部測試發版

見 [`docs/store-release.md`](../../docs/store-release.md)。GitHub Actions workflow：`Mobile Internal Release`（TestFlight + Play 內部測試）。
