# Android upload signing (local only)

本機 release 簽章檔（**不要 commit**）：

- `upload-keystore.p12`
- `key.properties`（可參考 `key.properties.example`）
- `upload_certificate.pem` / `.der`（公開憑證，給 Play「新增金鑰」用）

## Play Console：套件名稱註冊

1. 開啟 [Android 開發人員驗證](https://play.google.com/console) → Cloakly → **新增金鑰**
2. 上傳或貼上 `upload_certificate.pem` 全文（含 `BEGIN/END CERTIFICATE`）
3. 套件名稱確認為 `com.cloud52.cloakly`

憑證 SHA-256（核對用）：

```
51:EB:56:41:B1:D1:FC:2A:45:8E:22:10:5D:65:D3:89:49:EF:FE:22:AA:42:9A:B9:F5:AE:C8:F1:D2:0F:A4:C4
```

遺失 `upload-keystore.p12` 或密碼將無法以同一上傳金鑰發版；請另存密碼管理器備份。
