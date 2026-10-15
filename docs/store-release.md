# Cloakly 手機版內部測試發版

目標：用 GitHub Actions 建置並上傳 **Play 內部測試** 與 **TestFlight**。  
App ID：`com.cloud52.cloakly`  
商店名稱（ASC）：`Cloakly Project Meetings`  
桌面顯示名：`Cloakly`

## 標準流程（記得照這個走）

1. 在 `main` 上合併／推送會改到手機 App 的程式（`apps/mobile/**` 或 `packages/cloakly_core/**`）。
2. GitHub Actions 會**自動**跑 **Mobile Internal Release（both）**。
3. CI 會在建置前**自動把 build number 往上加**（不必再手動改 `pubspec.yaml` 的 `+N` 才能過 TestFlight／Play）。
4. 等 Actions 綠燈：
   - Android → Play **內部測試** track
   - iOS → **TestFlight**
5. 用下面「怎麼拿到內測包」安裝；**不要**指望在商店搜尋到。

手動補跑：Actions → **Mobile Internal Release** → Run workflow → `both`／`android`／`ios`。

只改文件、後端、桌面版時，**不會**自動觸發；要發版再手動 Run，或順便動到上面 path。

## 訂閱定價（暫定正式價）

| 方案 | 價格 (USD) |
| --- | --- |
| 月繳 | **$19.99** |
| 年繳 | **$199.99**（約等於 10 個月，送約 2 個月） |

商店／RevenueCat 若仍是測試價（如 0.99／9.99），正式開賣前改成上表。SKU 建議：`cloakly_pro_monthly`、`cloakly_pro_yearly`（與 entitlement `pro` 對齊）。

## 本機已備妥（勿 commit）

| 檔案 | 用途 |
| --- | --- |
| `secrets/AuthKey_C6699HN474.p8` | App Store Connect API |
| `secrets/asc-api.txt` | Issuer ID / Key ID |
| `secrets/cloakly-play-*.json` | Play 服務帳號 |
| `apps/mobile/android/upload-keystore.p12` | Android 上傳簽章 |
| `apps/mobile/android/key.properties` | keystore 密碼 |

## GitHub Actions

Workflow：`.github/workflows/mobile-internal.yml`

| 觸發 | 行為 |
| --- | --- |
| `push` → `main` 且改到 `apps/mobile/**`、`packages/cloakly_core/**`、或本 workflow | 自動 **both** |
| `workflow_dispatch` | 手動選 android／ios／both |

版號：CI 執行 `.github/scripts/bump_mobile_build.py`，以 `max(GITHUB_RUN_NUMBER, pubspec+1)` 寫入本次建置的 `apps/mobile/pubspec.yaml`（不回寫 git）。本機 `version:` 可偶爾對齊，但**發版不再依賴你記得 +1**。

### 必填 Repository secrets

在 GitHub repo → Settings → Secrets and variables → Actions 新增：

| Secret | 內容 |
| --- | --- |
| `ASC_ISSUER_ID` | `af31862b-9744-445a-955e-01615a1ab0cb` |
| `ASC_KEY_ID` | `C6699HN474` |
| `ASC_KEY_P8` | `.p8` 檔**全文**（含 BEGIN／END） |
| `PLAY_SERVICE_ACCOUNT_JSON` | Play 服務帳號 JSON **全文** |
| `ANDROID_KEYSTORE_BASE64` | `upload-keystore.p12` 的 base64 |
| `ANDROID_KEYSTORE_PASSWORD` | 與 `key.properties` 的 storePassword 相同 |
| `ANDROID_KEY_PASSWORD` | 與 `key.properties` 的 keyPassword 相同 |
| `ANDROID_KEY_ALIAS` | `cloakly` |
| `SUPABASE_URL` | 正式 Hosted URL |
| `SUPABASE_PUBLISHABLE_KEY` | 正式 publishable key |
| `REVENUECAT_APPLE_API_KEY` | `appl_…`（可先空字串，訂閱頁不顯示） |
| `REVENUECAT_GOOGLE_API_KEY` | `goog_…` |
| `REVENUECAT_ENTITLEMENT_ID` | 預設 `pro`（可省略） |

### 產生 `ANDROID_KEYSTORE_BASE64`（PowerShell）

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes(
  "C:\Kate\sideProject\cloakly\apps\mobile\android\upload-keystore.p12"
)) | Set-Clipboard
```

剪貼簿內容貼進 GitHub secret。

### 讀取本機密碼（勿貼到公開處）

```powershell
Get-Content C:\Kate\sideProject\cloakly\apps\mobile\android\key.properties
```

## 版號

`apps/mobile/pubspec.yaml` 的 `version: x.y.z+build`

| 欄位 | 用途 |
| --- | --- |
| `x.y.z` | versionName／CFBundleShortVersionString（行銷版號，手動改） |
| `build` | versionCode／CFBundleVersion（**CI 自動遞增**；TestFlight／Play 都要求每次上傳更高） |

## 怎麼拿到內測包

### Android（Play 內部測試）— 搜尋找不到是正常的

內部測試**不會**出現在一般 Play 商店搜尋結果。加了 tester email 還不夠，測試者必須用**加入連結**當過一次 tester。

1. [Play Console](https://play.google.com/console) → 你的 App → **測試** → **內部測試**。
2. 確認最新 release 狀態是「可供測試者使用」／已推出（CI 用 `track: internal`、`status: completed`）。
3. **測試人員**分頁：email 名單或 Google 群組已加入，並**複製「如何加入」連結**（形如  
   `https://play.google.com/apps/testing/com.cloud52.cloakly`）。
4. 用**同一個 Google 帳號**（名單裡的那個）在手機瀏覽器打開連結 → 點「成為測試人員」→ 等幾分鐘到幾小時。
5. 再從連結進商店頁下載／更新；或 Play 商店 → 個人檔案確認登入正確帳號後開該連結。
6. 若一直沒有：檢查是否完成「應用程式存取權／隱私權政策／內容分級」等基本設定、服務帳號是否有「發布至測試群組」權限、手機是否登入錯帳號、是否需清除 Play 商店快取。

首次上架內部測試後，有時要過一陣子商店頁才會對測試者可見。

### iOS（TestFlight）

1. App Store Connect → TestFlight → 建置出現後加 Internal／External tester。
2. 測試者用邀請信或 TestFlight App 兌換碼安裝。
3. bundle version 必須嚴格遞增（已由 CI bump 處理）。

## 常見卡關

- Play 第一次上傳可能要求在 Console 完成「應用程式完整性／Play App Signing」同意流程。
- iOS CI：首次若 Distribution 憑證額滿，workflow 勾選 `revoke_ios_certs` 撤銷孤兒憑證並匯出 `dist-ci.p12`；之後把 `APPLE_CERT_P12_BASE64`／`APPLE_CERT_PASSWORD`（預設 `cloakly-ci-cert`）存進 Secrets，避免每跑一次就新建憑證。
- Android `ANDROID_KEYSTORE_BASE64` 必須是純 ASCII base64；若用 PowerShell pipe 寫入 secret 可能變成 UTF-16 導致 `base64: invalid input`。
- 服務帳號須已在 Play「使用者和權限」被邀請，並具備「發布至測試群組」權限。
- RevenueCat Dashboard 的 App 須改為新的 bundle／package。
- TestFlight：`The bundle version must be higher than …` → 舊流程忘了 +1；現在應由 CI bump 避免。

## 送審前另補

隱私權政策 URL、截圖、描述、訂閱商品、審核測試帳號。本 workflow **不會**自動送審。
