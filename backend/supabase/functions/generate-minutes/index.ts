import { complete, clipped, transcriptText } from "../_shared/openai.ts";
import {
  corsHeaders,
  failure,
  jsonResponse,
  requireHostedAccess,
  requireUser,
} from "../_shared/http.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return jsonResponse({ error: "METHOD_NOT_ALLOWED" }, 405);
  try {
    const { userClient } = await requireUser(req);
    await requireHostedAccess(userClient);
    const body = await req.json();
    const title = clipped(body.meeting?.title, 300) || "會議紀錄";
    const startedAt = clipped(body.meeting?.startedAt, 80);
    const project = clipped(body.projectContext, 48000);
    const transcript = transcriptText(body.lines, 1000);
    const notes = Array.isArray(body.notes)
      ? body.notes.slice(0, 200).map((note: unknown) => `- ${clipped((note as { text?: unknown })?.text, 2000)}`).join("\n")
      : "";
    const raw = await complete({
      system: `你是會議紀錄秘書。只輸出 JSON 物件，不要 Markdown 圍欄。格式為 {"title":"精煉標題","minutesMarkdown":"繁體中文 Markdown，含 ## 摘要、## 討論重點、## 決議、## 待辦","speakerNames":{"我":"可選真名","對方A":"可選真名"}}。只根據輸入內容，不得發明事實。`,
      user: `原標題：${title}\n開始時間：${startedAt}\n\n現場筆記：\n${notes || "（無）"}\n\n專案資料：\n${project || "（無）"}\n\n逐字稿：\n${transcript || "（無）"}`,
      temperature: 0.2,
      jsonObject: true,
    });
    return jsonResponse(JSON.parse(raw));
  } catch (error) {
    return failure(error);
  }
});
