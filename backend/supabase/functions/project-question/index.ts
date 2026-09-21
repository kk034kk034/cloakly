import { complete } from "../_shared/openai.ts";
import {
  corsHeaders, failure, jsonResponse, requireHostedAccess, requireUser,
} from "../_shared/http.ts";
import { projectQuestionPrompt, validateProjectQuestion } from "../_shared/project_question.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return jsonResponse({ error: "METHOD_NOT_ALLOWED" }, 405);
  try {
    const { userClient } = await requireUser(req);
    await requireHostedAccess(userClient);
    const body = await req.json();
    const input = validateProjectQuestion(body);
    if (!input) return jsonResponse({ error: "INVALID_PROJECT_QUESTION" }, 400);
    const result = await complete({
      system: projectQuestionPrompt,
      user: JSON.stringify(input),
      temperature: 0.1,
      maxTokens: 1200,
    });
    return jsonResponse({ answer: result.content, usage: result.usage });
  } catch (error) {
    return failure(error);
  }
});
