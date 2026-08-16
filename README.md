# Cloakly

會議進行中就能記筆記、在被問到時拿到可說出口的提示，結束後自動產出含發言人的會議紀錄。

同一套 Flutter 程式可跑在 **Android、iOS、Windows、macOS、Linux**。產品定位是你自己看得到的會議助手，不是隱藏視窗或面試作弊工具。

## 功能

- **系統聲音**：電腦版可擷取耳機／喇叭正在播放的會議聲音（不必加 bot）。麥克風是「我」，系統聲音依聲紋拆成對方A / 對方B
- **專案知識庫**：會議前選定資料夾，提示會依 Spec / WBS / Issue / 承諾，而不是臨場編
- **邊錄邊記**：麥克風錄音時可同時寫現場筆記
- **被問到時給提示**：可在「偵測到問題 / 每次停頓 / 手動」三種時機產生回答建議
- **發言人逐字稿**：麥克風是「我」；系統聲音依聲紋拆成對方A / 對方B / 對方C。現場只開麥時拆成發言人 1、2、3。
- **會議紀錄**：結束後依逐字稿與筆記產出摘要、決議與待辦
- **示範模式**：沒填金鑰也能按「開始會議」，會播放模擬週會

## 準備

1. 安裝 [Flutter](https://docs.flutter.dev/get-started/install) 3.24 以上
2. 手機：Android Studio / Xcode；電腦：Windows 需 Visual Studio（含「使用 C++ 的桌面開發」）
3. Windows 若 `flutter pub get` 提示 symlink，請先開 [開發人員模式](ms-settings:developers)

```bash
flutter pub get
flutter run          # 目前已連的裝置
flutter run -d windows
flutter run -d macos
flutter run -d linux
```

第一次請允許麥克風。Windows 會用 WASAPI loopback 聽系統聲音；macOS 第一次要允許「螢幕錄製」（只為了聽會議音訊，不是要錄畫面）。手機無法擷取其他 App 的會議聲音，請用電腦版。

設定裡預設開啟「擷取電腦正在播放的聲音」。戴耳機開 Teams / Meet / Zoom 時，客戶的聲音走系統音，你的聲音走麥克風。

## 金鑰（選填，但真實轉寫與提示需要）

到 App 內「設定」填入 OpenAI API 金鑰。對話預設用 `gpt-4o-mini`，轉寫用 OpenAI（系統聲音會拆對方A/B）。沒有金鑰則走示範模式。

## 使用

1. 按資料夾圖示或首頁卡片，**選定專案資料夾**（可略過）
2. 勾選要帶進會議的文件（檔名含 spec / wbs / agenda / issue / 承諾 的會自動勾）
3. 按「開始會議」；被問到時，提示會帶上這些文件與即時逐字稿

建議資料夾內放：專案背景、WBS、API Spec、議程、已知 Issue、客戶承諾事項。只索引 `.md` `.txt` `.json` `.yaml` `.csv` 等文字檔，並略過 `node_modules`、`.git`。

## 架構摘要

```
選定專案資料夾 → 勾選文件
錄音：麥克風（我）+ 系統聲音 loopback
      → OpenAI 轉寫
      → 對方A / 對方B / 對方C
      → 問題偵測 → LLM（prompt + 專案文件 + 逐字稿）
         → 結束時 LLM 會議紀錄
         → 本機 SQLite
```

資料存在應用程式文件目錄的 `cloakly/`，金鑰存在本機設定，不會上傳到我們的伺服器。
