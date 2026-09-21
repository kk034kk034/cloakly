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
    const project = clipped(body.projectContext, 48000) ||
      "（沒有專案資料；不得編造時程、數字或承諾。）";
    const transcript = transcriptText(body.recent, 80);
    const trigger = clipped(body.trigger, 4000);
    const result = await complete({
      system: "你是繁體中文會議助手。只根據提供的資料，產生短、可直接說出口且不亂承諾的回答。資料不足時要明說並提出確認方式。",
      user: `專案資料：\n${project}\n\n近期對話：\n${transcript}\n\n觸發內容：\n${trigger}\n\n輸出格式：\n建議回答：<一句可說出口的話>\n要點：\n- …`,
      temperature: 0.3,
      maxTokens: 500,
    });
    return jsonResponse({ answer: result.content, usage: result.usage });
  } catch (error) {
    return failure(error);
  }
});
