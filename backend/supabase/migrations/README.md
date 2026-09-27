# Database migrations

`202609190001_hosted_billing.sql` 建立核心資料表與 RLS；`202609190002_cumulative_daily_usage.sql` 讓免費帳號每天可有多場會議，但加總最多 1,800 秒，並在結束時回收未使用的預留額度；`202609190003_revenuecat_event_sync.sql` 讓客戶端同步可重複套用，同時 webhook 事件仍去重。`202609270001_delete_account.sql` 提供僅 service role 可呼叫的 `purge_account_references`，刪除帳號前先清掉 webhook 裡對該使用者的引用。`202609270002_free_quota_carryover.sql` 在刪除時只保存 Email 的 SHA-256 與當天已用的免費秒數；同一個 Email 當天再註冊時，會把這段用量接回新帳號，過期的日期紀錄會在下次刪除或註冊時清掉。`202609270003_free_pool_and_device.sql` 加上全體免費會議每天 86,400 秒的上限，並把一支手機當天的免費額度鎖在第一個使用它的帳號；免費專案問答與計畫建議各 5 次。
