# 串流重構與錄音驗證

## 實作狀態

即時會議改用 `SonioxStt`，每個音源只有一個持續 WebSocket session。
傳輸小音訊包不等於獨立辨識請求；VAD 不再 flush 或重置辨識上下文。
`StreamingTranscript` 用穩定句段 ID 合併 final tokens 與可替換的 non-final tokens；
人物修訂不會新增重複列。已定稿的同一服務端 speaker ID 在整個 session 內維持相同標籤。
中文與中英混合分別送出語言限制；未知人物仍標示待確認。

Soniox 是功能匹配的第一個候選，並未經這場錄音證明優於其他供應商。
`SttEngine` 保持可替換；OpenAI 現有檔案轉寫類別保留作歷史比較，但不再進入即時會議路徑。
API 金鑰只由本機設定或環境變數讀取，回放工具不輸出金鑰。

## 已檢查的錄音

- 來源：使用者提供的「20260917-1542 博班進度會議紀錄.m4a」，不修改原檔。
- 完整解碼長度：3488.1945 秒（58 分 8 秒）。
- 原始音訊：AAC、44100 Hz、單聲道、42,460,419 bytes。
- SHA-256：`577636d9d37b3d7dcd8b4933e8b21b4fa7cbbc5b2f78bb9e01393911a1e70d2d`。
- 解碼為 16000 Hz / mono / PCM s16le：111,622,224 bytes。
- 完整本機 WebSocket 回放：1 條連線、29,069 個音訊包、111,622,224 bytes 全部逐 byte 相符。
- 解碼後 RMS 約 -23.30 dBFS，峰值約 -1.11 dBFS，未偵測到數值削波。
- 單聲道音訊不含每位參與者的獨立聲道，需由模型推估人物。

以上僅證明檔案與數位音訊完整可讀，不證明人聲清楚、原始收音無失真或辨識準確。
缺少 Soniox 金鑰，尚未將錄音上傳 Soniox，也未取得真實辨識結果。
完整逐字稿、字錯率、人物錯誤率與實際延遲仍未量測。
個人錄音與報告留在 git 忽略的 `build/stt_validation/`。

26 項一般回歸測試通過，涵蓋五人標籤映射、人物與文字修訂、設定遷移、窄螢幕設定頁、暫停時間映射與尾句逾時。
完整錄音傳輸測試另以本機音訊路徑啟用並通過；一般測試預設跳過該私有錄音測試。

## 重跑方式

本機解碼（需要 Python 的 PyAV 與 NumPy）：

```powershell
python tool/prepare_audio.py '你的錄音.m4a' --output build/stt_validation/meeting
```

填入 App 設定的 Soniox 金鑰，或在本機設好 `SONIOX_API_KEY`，再執行：

```powershell
dart run tool/replay_stt.dart build/stt_validation/meeting/input.pcm build/stt_validation/meeting/cloud 1
```

預設中英混合；可用 `STT_LANGUAGE=zh` 比較中文限制。速度 `1` 為真實時間回放；
速度 `0` 只適合吞吐與功能測試，**不能把其耗時當成會中延遲**。
回放使用與 App 相同的 Soniox 引擎與句段組裝器，输出 events.jsonl、transcript.txt、run_report.json。
記錄的模型人物數只表示輸出了多少個標籤，不表示每個人都分對。

只測本機傳輸、完全不上傳雲端：

```powershell
$env:CLOAKLY_TEST_PCM = '已解碼 input.pcm 的完整路徑'
flutter test test/recording_transport_test.dart
```

此測試使用本機 WebSocket，逐包逐 byte 對比完整錄音，確認只用一條連線且沒有遺失音訊。
它不執行語音辨識。

## 雲端驗收仍待完成

1. 以真實時間播放同一音訊，記錄暫定與定稿的 P50/P95 延遲、錯誤與漏句。
2. 人工標註多段中文／中英混合內容，計算中文字錯率與專有名詞錯誤。
3. 人工確認 4～5 位發言人的時間區間；檢查人物合併、同人拆分與稍後再發言的穩定性。
4. 分別檢查短句、同時發言、回音和語言誤判。不能用五個標籤或單元測試通過代替這些驗收。
5. 如需比較其他引擎，沿用同一 PCM 與人工標註，保持取樣率、語言設定及量測方式一致。

目前遇到斷線會提示結束並重跑，沒有自動重連的人物延續，也沒有會後整場聲紋重校正。
缺少人工對照前，不應宣稱達到產品品質目標。

## 官方依據

- [Soniox 持續串流與結果更新](https://soniox.com/docs/stt/rt/real-time-transcription)
- [Soniox 人物辨識取捨](https://soniox.com/docs/stt/concepts/speaker-diarization)：過早 endpoint/finalize 可能降低人物準確率，因此不由客戶端定時強制定稿。
- [Soniox 語言限制](https://soniox.com/docs/stt/concepts/language-restrictions)：屬強引導，並非保證不會輸出其他語言。
- [Deepgram streaming](https://developers.deepgram.com/docs/understand-endpointing-interim-results)：其他可比較的串流架構。
