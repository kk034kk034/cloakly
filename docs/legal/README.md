# Cloakly 法律頁

`privacy.*.html`、`terms.*.html`、`delete-account.*.html` 依照目前程式撰寫：Supabase 帳號、Soniox 即時轉寫、OpenAI Chat Completions、RevenueCat、裝置識別的 SHA-256，以及 `delete-account` 實際刪除與留下的資料。

已填上的項目：

- 營運者：Cloud52（對應 `com.cloud52` 與 cloud-52.com）
- 地址：台灣（沒有街道地址）
- 準據法：中華民國（台灣）法律；第一審法院：臺灣臺北地方法院
- 最低年齡：13 歲
- 責任上限：該請求前 12 個月內，使用者實際支付給 Cloud52 的金額
- 生效日：2026-10-26；著作權年份：2026

Supabase 區域沒有寫在 `backend/supabase/config.toml`（只有 `project_id = "cloakly"`）、範例網址或文件裡，所以政策不指定城市或區域：資料存放在 Supabase 營運的資料中心，日誌保留一段有限期間，不寫死天數。

OpenAI 的句子依照其公開的 [API 資料控制說明](https://developers.openai.com/api/docs/guides/your-data)：API 內容預設不用於訓練，除非客戶明確加入；`/v1/chat/completions` 的濫用監控日誌最多約 30 天，法律要求時可能更久。程式只呼叫這個端點，沒有送出訓練加入，也沒有送音訊。後端的大型語言模型只有 OpenAI。

## 公開網址（GitHub Pages）

網站是公開 repo [kk034kk034/cloakly](https://github.com/kk034kk034/cloakly) 的 `/docs`。`docs/.nojekyll` 讓 GitHub 不要用 Jekyll 濾掉檔案。`docs/index.html` 是網站首頁。

**擁有者必須自己開啟：** GitHub 倉庫 → Settings → Pages → Branch `main`、資料夾 `/docs`。在那之前下面的網址是 404，商店審查會打不開。

| 頁面 | 網址 |
| --- | --- |
| 網站首頁 | https://kk034kk034.github.io/cloakly/ |
| 法律文件目錄 | https://kk034kk034.github.io/cloakly/legal/index.html |
| 隱私權政策（繁中） | https://kk034kk034.github.io/cloakly/legal/privacy.zh-TW.html |
| Privacy Policy | https://kk034kk034.github.io/cloakly/legal/privacy.en.html |
| 使用條款（繁中） | https://kk034kk034.github.io/cloakly/legal/terms.zh-TW.html |
| Terms of Use | https://kk034kk034.github.io/cloakly/legal/terms.en.html |
| 刪除帳號（繁中） | https://kk034kk034.github.io/cloakly/legal/delete-account.zh-TW.html |
| Delete account | https://kk034kk034.github.io/cloakly/legal/delete-account.en.html |

iOS 的 `privacy_url` 指向該語系的隱私權政策，`support_url` 指向法律文件目錄，`marketing_url` 指向網站首頁。Google Play 的隱私權政策請填對應語系頁。Play Console 的帳號刪除網址請填：

https://kk034kk034.github.io/cloakly/legal/delete-account.zh-TW.html

英文審查可改用 `delete-account.en.html`。該頁說明 App 內刪除，以及無法登入時寄信。

## 聯絡信箱

支援、個資請求與無法登入時的刪除申請都使用 `contact@cloud-52.com`。

`python3 apps/mobile/tool/check_store_metadata.py --strict` 會檢查商店文案字數，並掃描商店文案與 `docs/legal`。這兩個位置若再出現未填佔位符，**Mobile Store Metadata** 與 fastlane 的 `metadata` lane 會拒絕上傳。目前這項檢查可以通過。

審核示範帳號的帳號密碼只填在 App Store Connect 與 Play Console，不要 commit。網站由 GitHub Pages 提供：Settings → Pages → 分支 `main`、資料夾 `/docs`。
