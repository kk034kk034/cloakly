# Cloakly

會議進行中記筆記與查看串流逐字稿，結束後產出會議紀錄。即時轉寫使用 Soniox；中文與多人準確率仍待真實錄音雲端驗收。

Cloakly 使用一個公開 monorepo 維護 **桌面版、手機版、共用核心與 Hosted 後端**。桌面版採自備 API 金鑰；手機版使用 Supabase 登入與用量服務、RevenueCat 訂閱，以及後端簽發的短效轉寫金鑰。產品定位是你自己看得到的會議助手，不是隱藏視窗或面試作弊工具。

## 功能

- **專案問答**：提問前自動掃描專案資料夾內所有支援文件，並查找歷次會議逐字稿、筆記與會議紀錄；回答附可查看的來源片段、頁碼／行號及會議時間點。詢問現況時會自動優先整理近期資料。
- **甘特圖**：以階段（phase）拆看板，手動或 AI 建議工作、期限、負責人與狀態；階段全部完成後可封存，避免完成欄過長。
- **全部專案看板**：首頁列出各專案「現行未封存階段」的工作，方便跨專案拖曳狀態。
- **AI 用量**：專案回答、回答提示、會議紀錄及其他 AI 功能顯示實際輸入／輸出 tokens 與估計美元、台幣費用。
- **系統聲音**：電腦版可擷取耳機／喇叭正在播放的會議聲音（不必加 bot）。耳機模式麥克風是「我」，其他人由同一條持續串流區分。
- **專案知識庫**：會議前選定資料夾，提示會依規格、時程、Issue 與承諾，而不是臨場編
- **邊錄邊記**：麥克風錄音時可同時寫現場筆記
- **被問到時給提示**：可在「偵測到問題 / 每次停頓 / 手動」三種時機產生回答建議
- **發言人逐字稿**：持續傳送音訊，文字先暫定再定稿；同一連線保留人物標籤。模型標籤不是已驗證的真實姓名，未知人物不觸發自動回答。
- **會議紀錄**：結束後依逐字稿與筆記產出摘要、決議與待辦
- **示範模式**：沒填金鑰也能按「開始會議」，會播放模擬週會

## 準備

1. 安裝 [Flutter](https://docs.flutter.dev/get-started/install) 3.24 以上
2. 手機：Android Studio / Xcode；電腦：Windows 需 Visual Studio（含「使用 C++ 的桌面開發」）
3. Windows 若 `flutter pub get` 提示 symlink，請先開 [開發人員模式](ms-settings:developers)

```powershell
# 在 repo 根目錄安裝整個 workspace 的套件
flutter pub get

# Windows 桌面版
cd C:\Kate\sideProject\cloakly\apps\desktop
flutter run -d windows

# Android／iOS 手機版（另一個 PowerShell）
cd C:\Kate\sideProject\cloakly\apps\mobile
flutter devices
flutter run -d <device-id> --dart-define-from-file=config/local.json
```

repo 根目錄現在是 Dart workspace，沒有 `lib/main.dart`，所以在 `C:\Kate\sideProject\cloakly` 直接執行 `flutter run -d windows` 會出現 `Target file "lib\main.dart" not found.`。請先進入對應的 `apps/desktop` 或 `apps/mobile`。

第一次請允許麥克風。Windows 會用 WASAPI loopback 聽系統聲音；macOS 第一次要允許「螢幕錄製」（只為了聽會議音訊，不是要錄畫面）。手機無法擷取其他 App 的會議聲音，請用電腦版。

設定裡預設開啟「擷取電腦正在播放的聲音」。戴耳機開 Teams / Meet / Zoom 時，客戶的聲音走系統音，你的聲音走麥克風。

## 金鑰（選填，但真實轉寫與提示需要）

桌面版到 App 內「設定」填入 **Soniox API 金鑰**，啟用多人即時轉寫；選擇中文、中英混合、英文或自動，並填入專有名詞。**OpenAI API 金鑰**另用於回答建議與會議摘要（預設 `gpt-4o-mini`）。只有 Soniox 金鑰仍可錄音、轉寫、存筆記；沒有 OpenAI 時保留本機逐字稿，不產生 AI 摘要。兩種金鑰都沒有才是示範模式。

桌面版保留自備金鑰模式。手機版需要 Supabase URL／publishable key 與 RevenueCat 公開 SDK key，設定方式見 [`apps/mobile/README.md`](apps/mobile/README.md)。Soniox、OpenAI 與 RevenueCat 的伺服器金鑰只存在 Supabase Secrets。

## 使用

1. 按資料夾圖示或首頁卡片，**選定專案資料夾**（可略過）
2. 把簡報、PDF、試算表、文件或程式碼放入專案資料夾及子資料夾，無需另外匯入或勾選
3. 按「開始會議」；被問到時，提示會帶上這些文件與即時逐字稿

支援 PPTX（投影片與講者備忘稿）、PDF（文字層）、XLSX（儲存格與公式快取）、DOCX（本文與表格段落）、文字與常見程式碼。直接以專案資料夾為來源，保留相對路徑；略過隱藏檔、`node_modules`、`.git` 與建置產物。不另外複製或搬移檔案。詳細支援與限制見 [專案問答](docs/project-questions.md)。

## 架構摘要

```
apps/desktop ─┐
              ├→ packages/cloakly_core
apps/mobile ──┘

backend/supabase → 手機版登入、訂閱、額度與短效 Soniox 金鑰

選定專案資料夾 → 自動掃描支援文件與子資料夾
錄音：麥克風（我）+ 系統聲音 loopback
      → Soniox 持續 WebSocket（各音源各一條連線）
      → 暫定文字修訂 → 定稿文字 + 時間戳 + 人物標籤
      → 問題偵測 → LLM（prompt + 專案文件 + 逐字稿）
         → 結束時 LLM 會議紀錄
         → 本機 SQLite
```

目前會議資料存在應用程式文件目錄的 `cloakly/`。桌面版金鑰保存在本機設定；手機 Hosted 版不內建 Soniox 或 OpenAI 長效金鑰。免費額度可每日分多場使用，合計最多 30 分鐘。

## 逐字稿品質驗證

- 收音後立即送出 PCM，包含自然停頓；不以固定秒數重建辨識請求，也不在 VAD 停頓時強制定稿。暫停時用 keepalive 保留連線。
- 暫定結果以句段 ID 更新，可修正文字及人物；定稿依標點、人物切換與音訊間隔組句。結束時等待服務端 finished 與資料庫寫入。
- 使用音訊時間戳排序；斷線與逾時明確顯示錯誤，原音訊保留供重跑。目前不自動重連，避免重置人物標籤卻繼續冒用原身分。
- 在 `packages/cloakly_core` 執行 `flutter test`，會驗證多人映射、暫定結果撤回、尾句、語言設定、本機 WebSocket 傳輸等行為；它們不代表真實辨識率。
- 上線驗收仍需固定的多人會議錄音與人工標註，量測文字錯誤率、人物歸屬錯誤率、停頓到顯示的 P50/P95 延遲，並涵蓋中英混合、專有名詞、插話與同時發言。在跨片段人物一致性完成之前，不應把人物提問追蹤視為已完成。

回放指令、架構取捨與本次錄音檢查見 [串流驗證說明](docs/streaming-validation.md)。舊的 `WhisperStt` 僅保留為歷史比較實作，不再由即時會議工廠選用。
