import {
  corsHeaders,
  failure,
  HttpError,
  jsonResponse,
  requireUser,
} from "../_shared/http.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return jsonResponse({ error: "METHOD_NOT_ALLOWED" }, 405);
  try {
    const { userClient } = await requireUser(req);
    const body = await req.json();
    const sessionId = typeof body.sessionId === "string" ? body.sessionId : "";
    const durationSeconds = Number.isFinite(body.durationSeconds)
      ? Math.max(0, Math.min(1800, Math.floor(body.durationSeconds)))
      : 0;
    if (!sessionId) throw new HttpError(400, "SESSION_ID_REQUIRED");
    const { data, error } = await userClient.rpc("finish_meeting_session", {
      p_session_id: sessionId,
      p_duration_seconds: durationSeconds,
    });
    if (error) throw new HttpError(500, "SESSION_FINALIZATION_FAILED");
    if (data !== true) throw new HttpError(404, "SESSION_NOT_FOUND");
    return jsonResponse({ ok: true });
  } catch (error) {
    return failure(error);
  }
});
