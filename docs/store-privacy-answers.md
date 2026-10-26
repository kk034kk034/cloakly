# 商店隱私問卷、分級與送審清單

答案依照目前程式，不是依照希望中的架構。法律頁已填 Cloud52、台灣、準據法、年齡，以及支援信箱 `contact@cloud-52.com`。審核示範帳號的帳號密碼只填在 App Store Connect 與 Play Console，不要 commit。

對照文件：[商店文案](store-listing.md)、[法律頁](legal/README.md)、[內部測試](store-release.md)。

程式事實（填表時不要講得比這更廣）：

- 帳號是 Supabase Email／密碼，必須確認信箱。沒有社群登入。
- 麥克風音訊留在手機，並以即時 WebSocket 送到 Soniox。不會把音訊檔放進 Cloakly 的資料庫，也不會把音訊送給 OpenAI。
- 逐字稿、筆記、會議紀錄、專案索引存在手機。使用 AI 功能時，文字摘錄經後端送到 OpenAI Chat Completions（預設 `gpt-4o-mini`）。
- 裝置識別：iOS 為 IDFV，Android 為 `ANDROID_ID`。資料庫只存 SHA-256。用途是免費額度，不是廣告。
- 訂閱經 RevenueCat。App User ID 是 Supabase 使用者 UUID，並會 `setEmail`。卡號不進 Cloakly。
- 沒有定位、相機、相簿、通訊錄、廣告 SDK、分析 SDK、當機 SDK。
- 刪除帳號走 App 內 `delete-account`。本機資料不刪。`free_device_claims` 不會被這支函式刪除。商店訂閱不取消。

## Apple App 隱私（營養標籤）

「用於追蹤」全部答 **否**。沒有 ATT、沒有廣告識別碼、沒有把資料交給資料仲介。若上傳後 App Store Connect 偵測到二進位連結了 AdSupport，仍答不用於追蹤，並到 RevenueCat 關閉廣告歸因，不要為了消警告而去請求追蹤權限。

「連結到使用者身分」下表皆為 **是**（都發生在已登入帳號）。

目的只勾 **App 功能**。Email 可再勾帳號管理若表單把帳號管理拆開；Apple 的目的清單沒有單獨的「帳號管理」時，用 App 功能即可。不要勾第三方廣告、開發者廣告、分析、產品個人化。

| 資料類型 | 要不要宣告 | 收集 | 連結身分 | 追蹤 | 目的 |
| --- | --- | --- | --- | --- | --- |
| 聯絡資訊 → Email | 要 | 是 | 是 | 否 | App 功能 |
| 聯絡資訊 → 姓名、電話、地址 | 不要 | | | | 程式沒有這些欄位 |
| 識別碼 → 使用者 ID | 要 | 是 | 是 | 否 | App 功能 |
| 識別碼 → 裝置 ID | 要 | 是 | 是 | 否 | App 功能（免費額度；IDFV／ANDROID_ID 的雜湊） |
| 購買 → 購買紀錄 | 要 | 是 | 是 | 否 | App 功能 |
| 購買 → 付款資訊 | 不要 | | | | 卡號在 Apple，App 拿不到 |
| 使用者內容 → 音訊資料 | 要 | 是 | 是 | 否 | App 功能（麥克風串到 Soniox） |
| 使用者內容 → 其他使用者內容 | 要 | 是 | 是 | 否 | App 功能（逐字稿、筆記、問答、文件摘錄） |
| 使用者內容 → 照片或影片、客戶支援 | 不要 | | | | 沒有相簿／相機，也沒有客服聊天 |
| 使用資料 → 產品互動 | 要 | 是 | 是 | 否 | App 功能（會議秒數、AI 次數；不是分析產品） |
| 使用資料 → 廣告資料 | 不要 | | | | |
| 診斷 → 當機資料 | 見下方 | | | | |
| 診斷 → 效能資料 | 不要 | | | | 沒有效能 SDK |
| 位置、健康、財務、聯絡人、瀏覽紀錄、搜尋紀錄、敏感資訊、環境掃描 | 不要 | | | | 沒有對應功能。`Info.plist` 雖有使用期間定位說明，那是檔案選擇元件被編進去，App 不收集位置，這裡仍答不要。會議裡碰巧講到的內容算音訊／其他使用者內容，不要另勾健康或敏感資訊 |
| 用於追蹤你的資料 | 無 | | | | |

當機資料：App 沒有把當機報告上傳到 Sentry 或 Crashlytics。若你會在 App Store Connect 看使用者選擇分享的當機紀錄，表單可能仍要你宣告。建議：收集＝是（僅限使用者同意分享給開發者的系統當機）、連結身分＝否、追蹤＝否、目的＝App 功能。若你完全不看那些報告，可答不收集，並在被問到時說明 App 沒有當機 SDK。

## Google Play 資料安全性

傳輸中加密：**是**（HTTPS／WSS）。不要回答「本機資料庫有加密」；SQLite 沒有再加密。

使用者可要求刪除：**是**。路徑是 App 內帳號頁。無法登入時寄到 `contact@cloud-52.com`。Play Console 的帳號刪除網址填 https://kk034kk034.github.io/cloakly/legal/delete-account.zh-TW.html 。頁面由 GitHub Pages 提供（Settings → Pages → `main` / `/docs`）。

「分享」的保守填法：獨立第三方收到內容就勾分享，目的只有 App 功能（裝置識別另加詐欺預防／安全）。Supabase 是我們的後端，算處理者，不另勾成廣告分享。若你與 Soniox、OpenAI、RevenueCat 的合約明確禁止他們自用，且你願意對這個認定負責，可以把對應列改成「收集、不分享」，並在說明寫服務供應商。下面這張是審查時比較站得住的勾法。

| 類型 | 收集 | 分享 | 分享對象與目的 |
| --- | --- | --- | --- |
| Email | 是 | 是 | RevenueCat，App 功能／帳號管理。雜湊只留在 Supabase，用於防止當天重註冊洗免費額度 |
| 使用者 ID | 是 | 是 | RevenueCat；Soniox 的 `client_reference_id` 含使用者 UUID。App 功能 |
| 裝置或其他 ID | 是 | 否 | 只送到自己的後端，存 SHA-256。App 功能、詐欺預防。不是廣告 ID |
| 音訊 | 是 | 是 | Soniox 即時轉寫。App 功能。使用者按下開始會議才收集 |
| 檔案與文件 | 是 | 是 | 專案文件文字摘錄送到 OpenAI。選資料夾才會發生。App 功能 |
| 其他使用者產生內容 | 是 | 是 | 逐字稿、筆記、問題、會議紀錄文字送到 OpenAI。App 功能 |
| App 互動 | 是 | 否 | 會議秒數與 AI 次數留在 Supabase。App 功能 |
| 購買紀錄 | 是 | 是 | RevenueCat。App 功能 |
| 精確／大約位置、相片、聯絡人、簡訊、網頁瀏覽、財務資訊 | 否 | | 卡號由 Google Play 處理，不要勾財務資訊 |
| 當機紀錄、效能 | 否（App 未接 SDK） | | Play 自身的 Android Vitals 不必因此改勾，除非表單明文問你是否使用那些報告做產品決策 |

資料不是用來做廣告。專案資料夾與 AI 功能可選；帳號 Email 為使用 App 所必需；麥克風只在會議進行時使用。

## 內容分級

App 沒有暴力、性、毒品、賭博、恐怖、粗話素材，也沒有內建瀏覽器、使用者之間的聊天，或公開動態牆。會議內容留在該帳號的手機上。

### Apple 年齡分級

預期結果：**4+**。Made for Kids：**否**。

| 題目 | 答案 |
| --- | --- |
| 卡通或寫實暴力、性與裸露、粗話、酒菸藥、成人主題、恐怖、醫療資訊、賭博 | 無／None |
| 不受限制的網頁存取 | 否 |
| 使用者互相傳送訊息或公開分享使用者內容 | 否 |
| App 內購買／訂閱 | 是 |
| 廣告 | 否 |
| 年齡保證、家長控管 | 不適用 |

若問卷把「使用者可以錄下任何說話內容」導向「使用者產生內容」，選「有，但不對其他 Cloakly 使用者公開、也沒有社群互動」。不要改答成聊天室，否則分級與審核要求會上升。

### Google Play／IARC

| 題目 | 答案 |
| --- | --- |
| 暴力、性、語言、管制物品、幽默、恐怖、賭博 | 無 |
| 使用者可否與其他使用者互動或分享個人資訊 | 否 |
| 分享位置 | 否 |
| 數位購買 | 是 |
| 不受限制的網際網路（內建瀏覽器） | 否 |
| 使用者可在線上公開發布內容 | 否 |

預期分級約為 Everyone／PEGI 3／IARC 3+。以問卷算完的結果為準。若你改答「使用者可互動」＝是，分級會升高，而且可能被要求內容審核機制；以目前程式，那個答案是錯的。

## App 審核／Play「應用程式存取權」示範帳號

把帳號建在正式 Supabase，信箱要已確認。建議給這個帳號 Cloakly Pro（沙盒或授權測試訂閱），避免審查員撞上每日 30 分鐘或各 5 次的免費上限。

帳號、密碼與審查聯絡人只填在 App Store Connect 的審核資訊，以及 Play Console 的應用程式存取權。這是公開 repo，不要把密碼或示範帳號寫進 git，也不要寫進 fastlane metadata。此文件不預留可 commit 的帳密欄位。

可直接貼上的英文說明（在後台把示範信箱與密碼填在說明上方的專用欄位，不要寫進這段文字）：

```
Sign in with the demo email and password. The email is already confirmed.
No other login method works.

Cloakly is an on-screen meeting assistant. It is not a hidden window and it
does not type into other apps. Please allow the microphone. On Android a
notification, "Cloakly 正在錄音", stays visible while a meeting you started
is recording, including if the screen turns off. Stop the meeting and the
notification and microphone service stop. On iOS the system microphone
indicator stays on; background audio mode is only for that in-progress meeting.

The phone records its microphone. It cannot capture audio inside Teams, Meet,
or Zoom. Speak a sentence after you tap start, confirm the live transcript,
type a note, stop, then generate minutes.

Project folder, Q&A, and the Gantt/kanban board are optional. Subscriptions
are Cloakly Pro monthly (cloakly_pro_monthly) and yearly (cloakly_pro_yearly),
entitlement id pro. This demo account should already have Pro so the 30-minute
daily free cap does not block review. Delete-account is on the account screen;
please do not delete this demo account.
```

## Play 前景服務宣告（FOREGROUND_SERVICE_MICROPHONE）

Play Console → 應用程式內容 → 前景服務權限 → 麥克風。

可直接貼上的說明：

```
Cloakly starts a microphone foreground service only after the user taps start
on a meeting. The ongoing notification title is "Cloakly 正在錄音" and the text
says recording continues if the screen turns off. The service type is
microphone. It stops when the meeting ends or the task is removed. It is not
used to listen in the background when no meeting is running.
```

Google 要求一段示範影片。此 repo 無法代拍。影片需顯示：使用者按下開始 → 通知出現 → 關閉畫面或切換 App 後錄音仍繼續 → 回到 App 結束會議 → 通知消失且服務停止。把影片上傳到 Play 的該項宣告，不要只寫文字。

## 權限（已對過程式）

| 項目 | 結論 |
| --- | --- |
| iOS 麥克風 | 保留。會議轉寫需要 |
| iOS 定位 | 保留 `NSLocationWhenInUseUsageDescription`。App 不要求也不使用定位，App 隱私營養標籤的「位置」仍答不要。觸發掃描的是 `file_picker` 連進來的 `DKCameraLocationManager`（`CLLocationManager.requestWhenInUseAuthorization()`）以及 `DKAsset.location`（照片上的 `CLLocation`）。沒有 `requestAlwaysAuthorization`，不加「總是」定位說明。文件裡的 location 是頁碼／行號 |
| iOS 相簿、相機、音樂資料庫 | 保留用途說明。App 只呼叫 `FilePicker.getDirectoryPath`，但 iOS 以 Swift Package Manager 連結 `file_picker` 10.3.10，其 `Package.swift` 固定編譯相簿、音樂選擇，並依賴 `DKImagePickerController`／`DKCamera`（`AVCaptureDevice` 的影片裝置）。CocoaPods 的 `Pod::PICKER_MEDIA = false` 對這份工程無效。營養標籤仍不要勾相片或相機 |
| iOS 寫入相簿 | 保留 `NSPhotoLibraryAddUsageDescription`。`DKImagePickerController` 呼叫 `PHAssetChangeRequest.creationRequestForAsset`，`DKPhotoGallery` 呼叫 `PHAssetCreationRequest` 與 `UIImageWriteToSavedPhotosAlbum`。App 不會把檔案存進相簿 |
| iOS 通訊錄、藍牙、語音辨識 | 不加。上述套件與 `DKImagePickerController`／`DKCamera`／`DKPhotoGallery` 沒有 `CNContactStore`、`CBCentralManager` 或 `SFSpeechRecognizer` |
| iOS 背景音訊 | 保留。只為了進行中的會議在鎖屏時繼續收音 |
| iOS 檔案分享 | 保留。錄音與資料庫在 App 文件目錄，使用者可從「檔案」App 取出 |
| iOS 出口合規 | `ITSAppUsesNonExemptEncryption` 為 false。只有 HTTPS／WSS，沒有自訂加密。上傳時若仍問出口合規，答使用標準加密 |
| Android `WRITE_EXTERNAL_STORAGE` | 保留，且 `maxSdkVersion="28"`。`MainActivity.saveToDownloads` 在 API 28 以下會寫入公開的下載資料夾；API 29 以上走 MediaStore，不需要此權限。沒有移除，因為舊系統的匯出仍會走到那段程式 |
| 麥克風前景服務、通知、帳單、網路、音訊設定、喚醒鎖 | 保留。分別對應錄音通知、Play 結帳、錄音與會議中保持 CPU |

## 送審前清單

兩邊都要：

- [ ] GitHub → Settings → Pages → 分支 `main`、資料夾 `/docs` 已開啟，法律頁網址在無痕視窗開得起來
- [ ] `python3 apps/mobile/tool/check_store_metadata.py --strict` 通過（聯絡信箱已是 `contact@cloud-52.com`）
- [ ] Play Console 隱私權政策網址與帳號刪除網址已填（刪除頁：https://kk034kk034.github.io/cloakly/legal/delete-account.zh-TW.html ）
- [ ] 執行 **Mobile Store Metadata**（不要開送審；這個 workflow 本身也不會送審）
- [ ] App Store／Play 的訂閱價格改成月繳 USD 19.99、年繳 USD 199.99，商品 ID 為 `cloakly_pro_monthly`、`cloakly_pro_yearly`，權益 `pro`，並接到 RevenueCat 的 Current Offering
- [ ] 實機截圖放到 [store-listing.md](store-listing.md) 的目錄，需要時才把 workflow 的 `upload_screenshots` 打開
- [ ] 示範帳號已確認信箱且具有 Pro，說明已貼上，密碼沒有進 git
- [ ] 隱私問卷依本文件勾選，沒有勾定位、相片、追蹤

只做 App Store：

- [ ] 建立或選取可編輯版本（例如 1.0.0）。若沒有，workflow 的 `ios_app_version` 填該版號
- [ ] 描述中的隱私權政策、使用條款、Apple 標準 EULA 連結在手機瀏覽器開得起來
- [ ] App 隱私營養標籤與本文件一致
- [ ] 年齡分級 4+，不是兒童類別
- [ ] 審核備註貼上示範帳號英文說明。審查員若鎖定畫面，說明背景音訊只服務進行中的會議
- [ ] 訂閱的審查截圖與價格在 App Store Connect 的訂閱項目另填（文案 workflow 不會建立訂閱商品）
- [ ] 確認後才在 App Store Connect 按送審。不要靠 fastlane 送審

只做 Google Play：

- [ ] 資料安全性表單與帳號刪除網址已填
- [ ] 內容分級問卷已送出
- [ ] 前景服務麥克風宣告已填，示範影片已上傳
- [ ] 應用程式存取權已填示範帳號
- [ ] 目標對象不含兒童
- [ ] 廣告宣告：否
- [ ] 功能圖像 1024×500、512 圖示、手機截圖已上傳
- [ ] 從內部測試推進到正式版時，在 Play Console 自行送審。文案 workflow 設了 `changes_not_sent_for_review`，不會代替你按送審
