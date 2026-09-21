import { complete, clipped } from "../_shared/openai.ts";
import {
  corsHeaders,
  failure,
  jsonResponse,
  requireHostedAccess,
  requireUser,
} from "../_shared/http.ts";

const system = `你是繁體中文專案規劃助理。只根據 evidence 擷取可追蹤工作，不得猜測日期、負責人或完成狀態。
只輸出 JSON：{"tasks":[{"title":"工作名稱","startDate":"YYYY-MM-DD 或 null","endDate":"YYYY-MM-DD 或 null","owner":"未記載則空字串","status":"planned|inProgress|blocked|done|uncertain","sourceIds":["S1"]}]}。
提案、承諾與已完成必須區分；缺乏明確證據時 status 使用 uncertain。日期已過不代表完成。相同工作只輸出一次，衝突時採較新的明確資料並保留所有相關來源 ID。最多 40 項。`;

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return jsonResponse({ error: "METHOD_NOT_ALLOWED" }, 405);
  try {
    const { userClient } = await requireUser(req);
    await requireHostedAccess(userClient);
    const body = await req.json();
    const evidence = clipped(body.evidence, 48000);
    if (!evidence) return jsonResponse({ error: "INVALID_PROJECT_PLAN" }, 400);
    const result = await complete({
      system,
      user: evidence,
      temperature: 0.1,
      jsonObject: true,
      maxTokens: 2500,
    });
    return jsonResponse({ ...JSON.parse(result.content), usage: result.usage });
  } catch (error) {
    return failure(error);
  }
});
