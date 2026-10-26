# Cloakly 法律頁（草稿）

`privacy.*.html`、`terms.*.html`、`delete-account.*.html` 依照目前程式撰寫：Supabase 帳號、Soniox 即時轉寫、OpenAI Chat Completions、RevenueCat、裝置識別的 SHA-256，以及 `delete-account` 實際刪除與留下的資料。

標成 `[[REPLACE_ME:…]]` 的欄位不能從程式庫得知。公開前請填上並請法律顧問審過。完整清單在 [商店上架說明](../store-listing.md)。

## 怎麼公開成 HTTPS 網址

商店要的是公開、無需登入就能打開的 HTTPS。此 repo 沒有現成的正式網域。

1. **GitHub Pages，來源選 `/docs`。** 在 GitHub 倉庫 Settings → Pages → Deploy from branch，分支用預設分支，資料夾選 `/docs`。隱私權政策會落在 `https://<GitHub 擁有者>.github.io/<倉庫>/legal/privacy.zh-TW.html`（英文把檔名換成 `privacy.en.html`）。擁有者與倉庫名稱以你的 GitHub 為準，這裡不猜測。Pages 會一併公開 `docs/` 底下其他文件；不要把真正的審核密碼寫進那些檔案。
2. **沿用 `apps/cloakly-auth/` 的靜態站。** 該目錄現在只有信箱確認頁 `index.html`。若這個目錄已經部署到某個公開網址，可以把 `docs/legal/` 的 HTML 放到同一個主機，讓確認信與政策共用一個網域。此 repo 沒有記錄那個網址。
3. **任何其他靜態主機。** 上傳 `docs/legal/` 即可。頁面沒有外部腳本，相對連結在同一目錄下即可運作。

公開後用瀏覽器無痕視窗點一次，確認不需要登入。再把最終網址寫進：

- `apps/mobile/ios/fastlane/metadata/<locale>/privacy_url.txt`
- `apps/mobile/ios/fastlane/metadata/<locale>/support_url.txt`
- `apps/mobile/ios/fastlane/metadata/<locale>/marketing_url.txt`（沒有行銷網站就填支援網址，或刪掉這行之前先確定 deliver 不會清掉已存在的值）
- 兩個平台的描述檔裡所有 `https://example.com/REPLACE_ME/...`
- Google Play Console 的隱私權政策網址，以及帳號刪除的網頁連結（可用 `delete-account.zh-TW.html`）

然後執行 `python3 apps/mobile/tool/check_store_metadata.py --strict`。還有 `REPLACE_ME` 時，上傳 workflow 會拒絕執行。
