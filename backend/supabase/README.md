# Cloakly Hosted Backend

此目錄是官方手機版使用的 Supabase migration 與 Edge Functions：

- 驗證 Supabase Auth JWT
- 接收 RevenueCat webhook 並更新 entitlement
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

先安裝 Supabase CLI，建立專案並在此目錄執行：

```powershell
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
supabase functions deploy generate-minutes
supabase functions deploy sync-entitlement
supabase functions deploy revenuecat-webhook
```

Supabase 會自動提供 `SUPABASE_URL`、`SUPABASE_ANON_KEY` 和 `SUPABASE_SERVICE_ROLE_KEY`。如果專案使用新式 publishable／secret key，也可另外設 `SUPABASE_PUBLISHABLE_KEY` 與 `SUPABASE_SECRET_KEY`。

在 Supabase Auth 開啟 Email provider，依需求決定是否要求確認信。RevenueCat 需建立 entitlement `pro`、月繳與年繳商品、Current Offering，App User ID 會使用 Supabase user UUID。Webhook URL 設成：

```text
https://<project-ref>.supabase.co/functions/v1/revenuecat-webhook
```

Webhook 的 Authorization header 要與 `REVENUECAT_WEBHOOK_AUTH` 完全相同。Soniox server key 需要 Temporary API keys 與 real-time speech-to-text 權限。

## 方案規則

- 免費帳號：每天可開多場，所有會議加總最多 1,800 秒，以 UTC 日期計算；結束會議後會釋放未使用的預留秒數。
- Pro：不受每日一場限制；目前每條轉寫連線仍以 1,800 秒為安全上限。
- RevenueCat webhook 以 event id 去重，舊事件不會覆蓋較新的訂閱狀態。
- AI endpoint 只允許當天已保留會議額度或具有有效 Pro entitlement 的使用者。

後端程式可公開；上述 secret 與商店伺服器憑證不可提交。這個 repo 不會自動替你建立 Supabase、App Store、Google Play 或 RevenueCat 的雲端設定。
