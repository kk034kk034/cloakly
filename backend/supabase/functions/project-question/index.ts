import { consumeFreeAi, deviceIdOf, releaseFreeAi } from "../_shared/free_quota.ts";
import { corsHeaders, failure, jsonResponse, requireUser } from "../_shared/http.ts";
import { complete } from "../_shared/openai.ts";
import { projectQuestionPrompt, validateProjectQuestion } from "../_shared/project_question.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return jsonResponse({ error: "METHOD_NOT_ALLOWED" }, 405);
  let consumed = false;
  let userClient: Awaited<ReturnType<typeof requireUser>>["userClient"] | undefined;
  try {
    ({ userClient } = await requireUser(req));
    const body = await req.json();
    const input = validateProjectQuestion(body);
    if (!input) return jsonResponse({ error: "INVALID_PROJECT_QUESTION" }, 400);
    consumed = await consumeFreeAi(userClient, deviceIdOf(body), "project_question");
    const result = await complete({
      system: projectQuestionPrompt,
      user: JSON.stringify(input),
      temperature: 0.1,
      maxTokens: 1200,
    });
    return jsonResponse({ answer: result.content, usage: result.usage });
  } catch (error) {
    if (consumed && userClient) await releaseFreeAi(userClient, "project_question");
    return failure(error);
  }
});
