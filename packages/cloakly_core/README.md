# cloakly_core

Cloakly 桌面版與手機版共用的 Flutter 套件，包含會議 UI、資料模型、本機儲存、轉寫與摘要流程。平台入口透過 `runCloaklyApp()` 啟動。

`AiService` 定義 AI 能力；桌面版注入 `DirectAiService`，手機版注入自己的 `HostedAiService`。STT 同樣透過 `SttEngineFactory` 注入，因此共用核心不含訂閱判斷，也不持有 Hosted 供應商的長效金鑰。
