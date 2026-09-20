# Database migrations

`202609190001_hosted_billing.sql` 建立核心資料表與 RLS；`202609190002_cumulative_daily_usage.sql` 讓免費帳號每天可有多場會議，但加總最多 1,800 秒，並在結束時回收未使用的預留額度；`202609190003_revenuecat_event_sync.sql` 讓客戶端同步可重複套用，同時 webhook 事件仍去重。
