# Cloakly 公開商店文案與截圖

內部測試仍走 [store-release.md](store-release.md) 的 **Mobile Internal Release**。這份說明是第一次公開上架用的文案、截圖位置，以及只上傳文案、不送審的 workflow。

App 內顯示名稱是 `Cloakly`。App Store Connect 的英文名稱維持 `Cloakly Project Meetings`。套件／Bundle ID：`com.cloud52.cloakly`。

## 文案放哪裡

| 平台 | 目錄 | 語系代碼 |
| --- | --- | --- |
| iOS（fastlane deliver） | `apps/mobile/ios/fastlane/metadata/<locale>/` | `en-US`、`zh-Hant` |
| iOS 非語系 | `apps/mobile/ios/fastlane/metadata/copyright.txt`、`primary_category.txt`、`secondary_category.txt` | 全 App 共用 |
| Android（fastlane supply） | `apps/mobile/android/fastlane/metadata/android/<locale>/` | `en-US`、`zh-TW` |

Apple 的繁體中文代碼是 `zh-Hant`，沒有 `zh-TW`。Google Play 的台灣繁體是 `zh-TW`。兩邊內容對齊，資料夾名稱依照各商店。

iOS 類別預設是 Productivity，次類別 Business。若 App Store Connect 已經設過別的類別，上傳前改這兩個檔，或在 deliver 拒絕更新時先拿掉。

字數上限（已由 `apps/mobile/tool/check_store_metadata.py` 檢查）：

| 欄位 | 上限 |
| --- | --- |
| iOS 名稱、副標題 | 30 |
| iOS 關鍵字 | 100 |
| iOS 宣傳文字 | 170 |
| iOS 描述、新功能 | 4000 |
| Play 標題 | 30 |
| Play 簡短說明 | 80 |
| Play 完整說明 | 4000 |
| Play 更新說明 `changelogs/default.txt` | 500 |

描述已寫明：這是顯示在畫面上的會議助手、錄音前要取得參與者同意、手機不能抓其他 App 的系統聲音、月繳 USD 19.99（`cloakly_pro_monthly`）、年繳 USD 199.99（`cloakly_pro_yearly`）、權益 `pro`、每一段轉寫 30 分鐘。iOS 描述另含 Apple 標準 EULA 連結。

## 必須先換掉的佔位符

文案裡的網址目前是 `https://example.com/REPLACE_ME/...`。版權是 `[[REPLACE_ME:COPYRIGHT_YEAR]] [[REPLACE_ME:LEGAL_ENTITY_NAME]]`。法律頁的佔位符見 [legal/README.md](legal/README.md)。

換完後執行：

```bash
python3 apps/mobile/tool/check_store_metadata.py --strict
```

沒加 `--strict` 只檢查字數，並列出還沒填的檔案。`--strict` 有 `REPLACE_ME` 就會失敗。上傳 workflow 使用 `--strict`。

## 只上傳文案、不送審

GitHub Actions → **Mobile Store Metadata** → Run workflow。

| 輸入 | 作用 |
| --- | --- |
| `platform` | `ios`、`android` 或 `both` |
| `upload_screenshots` | 預設關閉。打開才會一併上傳截圖，仍然不送審 |
| `ios_app_version` | 可留空，沿用 App Store Connect 目前可編輯的版本。第一次若還沒有可編輯版本，填 `1.0.0` |

使用既有 secret：`ASC_KEY_ID`、`ASC_ISSUER_ID`、`ASC_KEY_P8`、`PLAY_SERVICE_ACCOUNT_JSON`。沒有新增 secret。

iOS lane 是 `apps/mobile/ios/fastlane` 的 `metadata`：`deliver` 設 `skip_binary_upload`、預設 `skip_screenshots`、`submit_for_review: false`、`automatic_release: false`。不會上傳 IPA，也不會送審。

Android lane 是 `apps/mobile/android/fastlane` 的 `metadata`：`skip_upload_apk`、`skip_upload_aab`、預設略過圖片，並設 `changes_not_sent_for_review: true`。不會上傳 AAB，也不會把這次編輯送審。更新說明若對得上內部測試軌道已有的版本代碼，會寫到那個版本；不會因此建立正式版發行。

**Mobile Internal Release** 的觸發條件沒有改。推上 `main` 不會跑這個文案 workflow。

## 截圖（此次不提供檔案）

請用實機截圖。workflow 在 `upload_screenshots` 關閉時不會上傳截圖，缺檔也不會擋住文案上傳。

### iOS

放到 `apps/mobile/ios/fastlane/screenshots/<locale>/`，`<locale>` 用 `en-US` 與 `zh-Hant`。檔名要帶上下表的代碼，例如 `APP_IPHONE_69_01.png`。每種尺寸 3 到 10 張。送審前到 App Store Connect 再對一次「必要的截圖尺寸」，Apple 會新增機型。

| 裝置 | 直向像素 | 檔名請包含 |
| --- | --- | --- |
| iPhone 6.9 吋（目前新 App 通常必備） | 1320 × 2868，或 1290 × 2796、1260 × 2736 | `APP_IPHONE_69` |
| iPhone 6.5 吋（若後台仍另行要求） | 1284 × 2778 或 1242 × 2688 | `APP_IPHONE_65` |
| iPad Pro 13 吋 | 2064 × 2752 | `APP_IPAD_PRO_3GEN_129` 或 `IPAD_PRO_3GEN_129` |
| iPad Pro 12.9 吋（第 3 代以後，若與 13 吋分開要求） | 2048 × 2732 | 同上，並確認後台吃到的是 12.9 而非 13 吋欄位 |

本 App 的 Info.plist 有 iPad 方向，後台會把 iPad 截圖當必要項目。橫向請把寬高對調。不要用模擬器邊框圖充當唯一截圖，除非你確定審查接受。

### Android

放到 `apps/mobile/android/fastlane/metadata/android/<locale>/images/`：

| 檔案 | 規格 |
| --- | --- |
| `phoneScreenshots/` | 至少 2 張、最多 8 張。PNG 或 JPEG。每邊 320–3840 px，比例 16:9 或 9:16。建議 1080 × 1920 |
| `sevenInchScreenshots/` | 同上。App 沒有鎖手機版面，Play 若判定支援 7 吋平板就會要求 |
| `tenInchScreenshots/` | 同上，10 吋平板 |
| `featureGraphic.png` | 1024 × 500，商店資訊必備 |
| `icon.png` | 512 × 512、32-bit PNG |

`<locale>` 用 `en-US` 與 `zh-TW`。功能圖像與圖示每個語系各放一份，或至少放預設語系並在 Play Console 確認已套用。
