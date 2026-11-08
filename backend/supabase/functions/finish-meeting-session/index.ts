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
    const { user, userClient, adminClient } = await requireUser(req);
    const body = await req.json();
    let sessionId = typeof body.sessionId === "string" ? body.sessionId : "";
    const clientRequestId = typeof body.clientRequestId === "string"
      ? body.clientRequestId.trim()
      : "";
    const durationSeconds = Number.isFinite(body.durationSeconds)
      ? Math.max(0, Math.min(1800, Math.floor(body.durationSeconds)))
      : 0;
    if (!sessionId && clientRequestId) {
      const found = await adminClient
        .from("meeting_sessions")
        .select("id")
        .eq("user_id", user.id)
        .eq("client_request_id", clientRequestId)
        .order("created_at", { ascending: false })
        .limit(1)
        .maybeSingle();
      if (found.error) throw new HttpError(500, "SESSION_LOOKUP_FAILED");
      sessionId = found.data?.id ?? "";
    }
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
