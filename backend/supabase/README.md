# Cloakly Hosted Backend

此目錄是官方手機版使用的 Supabase migration 與 Edge Functions：

- 驗證 Supabase Auth JWT
- 接收 RevenueCat webhook，向 REST API 讀取目前 subscriber 狀態後更新 entitlement
- 以資料庫交易保留免費或付費會議額度
- 簽發單次使用、最長 30 分鐘的 Soniox temporary API key
- 代理 OpenAI 回答建議與會議摘要

桌面版不呼叫這套後端。後端程式碼可以公開，但下列值只能配置在部署環境的 Secrets：

- `SONIOX_API_KEY`
- `OPENAI_API_KEY`
- Supabase secret key
- RevenueCat webhook／secret key
- `REVENUECAT_SECRET_API_KEY`

## 建立與部署

先安裝 Supabase CLI，建立專案並在 `backend` 目錄（包含 `supabase/config.toml`）執行：

```powershell
Set-Location C:\Kate\sideProject\cloakly\backend
supabase login
supabase link --project-ref <project-ref>
supabase db push

supabase secrets set SONIOX_API_KEY=<server-key>
supabase secrets set OPENAI_API_KEY=<server-key>
supabase secrets set REVENUECAT_SECRET_API_KEY=<server-key>
supabase secrets set REVENUECAT_WEBHOOK_AUTH="Bearer <random-secret>"
supabase secrets set REVENUECAT_ENTITLEMENT_ID=pro

supabase functions deploy create-meeting-session
supabase functions deploy finish-meeting-session
supabase functions deploy suggest-answer
supabase functions deploy project-question
supabase functions deploy project-plan
supabase functions deploy generate-minutes
supabase functions deploy sync-entitlement
supabase functions deploy revenuecat-webhook
```

Supabase 會自動提供 `SUPABASE_URL`、`SUPABASE_ANON_KEY` 和 `SUPABASE_SERVICE_ROLE_KEY`。如果專案使用新式 publishable／secret key，也可另外設 `SUPABASE_PUBLISHABLE_KEY` 與 `SUPABASE_SECRET_KEY`。

在 Supabase Auth 開啟 Email provider，並開啟 Confirm email。未確認的帳號不能登入，後端也會拒絕。RevenueCat 需建立 entitlement `pro`、月繳與年繳商品、Current Offering，App User ID 會使用 Supabase user UUID。Webhook URL 設成：

```text
https://<project-ref>.supabase.co/functions/v1/revenuecat-webhook
```

Webhook 的 Authorization header 要與 `REVENUECAT_WEBHOOK_AUTH` 完全相同。Soniox server key 需要 Temporary API keys 與 real-time speech-to-text 權限。

`revenuecat-webhook` 不會只看事件上的 `entitlement_ids`。它會找出事件中的 Supabase UUID，向 RevenueCat 讀取該使用者目前的 subscriber，再寫入 `entitlements`。TRANSFER 會同時更新來源與目的帳號；來源帳號會被標成 expired。沒有對應 profile 的匿名 ID 會回 200 並忽略，避免 RevenueCat 一直重試。

## 方案規則

- 免費帳號：每天可開多場，所有會議加總最多 1,800 秒，以 UTC 日期計算；結束會議後會釋放未使用的預留秒數。全體免費帳號同一天加總最多 86,400 秒（24 小時，也就是 48 個帳號各用滿 30 分鐘）。名額用盡後，當天較晚的免費會議會被拒絕；Pro 不計入這個總額。
- 一支手機一天只能使用一個免費帳號的額度。額度是該帳號的 1,800 秒會議（回答提示與會議紀錄包含在內，不再另計次）、5 次專案問答、5 次計畫建議。識別由 App 送上裝置 ID，後端只保存雜湊。刪除帳號不會清掉當天的手機占用，也不會重置問答與計畫次數。
- Pro：不受每日次數與全體免費名額限制；目前每條轉寫連線仍以 1,800 秒為安全上限。
- 未確認信箱不能登入，也不能呼叫這些函式。Supabase Auth 必須開啟 Confirm email，寄信管道要能送出確認信。
- RevenueCat webhook 以 `事件 id + 使用者 id` 去重；客戶端同步使用穩定的 `sync:<user-id>`，可覆寫同一筆紀錄，但不會用較舊的事件覆蓋較新的訂閱狀態。
- 回答提示與會議紀錄只允許當天已保留會議額度或具有有效 Pro entitlement 的使用者。專案問答與計畫建議使用上面的每日次數，不必先開會。

後端程式可公開；上述 secret 與商店伺服器憑證不可提交。這個 repo 不會自動替你建立 Supabase、App Store、Google Play 或 RevenueCat 的雲端設定。
