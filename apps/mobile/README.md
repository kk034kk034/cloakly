# Cloakly Mobile

Android 與 iOS 的官方 Hosted 應用程式入口。它提供 Supabase Email／密碼登入，透過 RevenueCat 顯示、購買和恢復訂閱，並把轉寫與 AI 請求送到 `../../backend/supabase`。

Soniox 與 OpenAI 長效金鑰不得加入此目錄或編譯進 App。

## 啟動

複製 `config/example.json` 為不進版控的 `config/local.json`，填入 Supabase publishable key 與 RevenueCat 的 Apple／Google 公開 SDK key，再執行：

```powershell
flutter devices
flutter run -d <device-id> --dart-define-from-file=config/local.json
```

未設定 RevenueCat key 時仍可註冊、登入與使用免費額度，但訂閱商品不會顯示。手機版不支援 Windows target；桌面版請從 `../desktop` 啟動。
