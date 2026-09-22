# Cloakly 手機版內部測試發版

目標：用 GitHub Actions 建置並上傳 **Play 內部測試** 與 **TestFlight**。  
App ID：`com.cloud52.cloakly`  
商店名稱（ASC）：`Cloakly Project Meetings`  
桌面顯示名：`Cloakly`

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
觸發：Actions → **Mobile Internal Release** → Run workflow（選 android / ios / both）

### 必填 Repository secrets

在 GitHub repo → Settings → Secrets and variables → Actions 新增：

| Secret | 內容 |
| --- | --- |
| `ASC_ISSUER_ID` | `af31862b-9744-445a-955e-01615a1ab0cb` |
| `ASC_KEY_ID` | `C6699HN474` |
| `ASC_KEY_P8` | `.p8` 檔**全文**（含 BEGIN/END） |
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
`x.y.z` = versionName／CFBundleShortVersionString  
`build` = versionCode／CFBundleVersion（每次上傳需遞增）

## 常見卡關

- Play 第一次上傳可能要求在 Console 完成「應用程式完整性／Play App Signing」同意流程。
- iOS CI 使用 Fastlane `cert` + `sigh` + App Store Connect API Key 簽章（不需在 runner 登入 Apple ID）。
- Android `ANDROID_KEYSTORE_BASE64` 必須是純 ASCII base64；若用 PowerShell pipe 寫入 secret 可能變成 UTF-16 導致 `base64: invalid input`。
- 服務帳號須已在 Play「使用者和權限」被邀請，並具備「發布至測試群組」權限。
- RevenueCat Dashboard 的 App 須改為新的 bundle／package。

## 送審前另補

隱私權政策 URL、截圖、描述、訂閱商品、審核測試帳號。本 workflow **不會**自動送審。
