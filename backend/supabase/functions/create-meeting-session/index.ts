import {
  corsHeaders,
  failure,
  HttpError,
  jsonResponse,
  requireUser,
  requiredEnv,
} from "../_shared/http.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return jsonResponse({ error: "METHOD_NOT_ALLOWED" }, 405);

  let sessionId: string | undefined;
  let cleanupReservation: (() => Promise<void>) | undefined;
  try {
    const { user, userClient, adminClient } = await requireUser(req);
    let sonioxApiKey: string;
    try {
      sonioxApiKey = requiredEnv("SONIOX_API_KEY");
    } catch (_) {
      throw new HttpError(503, "TRANSCRIPTION_NOT_CONFIGURED");
    }
    const { data, error } = await userClient.rpc("reserve_meeting_session");
    if (error) {
      if (error.message.includes("FREE_DAILY_LIMIT_REACHED")) {
        throw new HttpError(429, "FREE_DAILY_LIMIT_REACHED");
      }
      throw new HttpError(500, "ALLOWANCE_RESERVATION_FAILED");
    }
    const reservation = Array.isArray(data) ? data[0] : data;
    sessionId = reservation?.session_id;
    const durationLimitSeconds = reservation?.duration_limit_seconds ?? 1800;
    if (!sessionId) throw new HttpError(500, "INVALID_RESERVATION");
    cleanupReservation = async () => {
      const sessionUpdate = await adminClient
        .from("meeting_sessions")
        .update({ status: "failed" })
        .eq("id", sessionId);
      const usageDelete = await adminClient
        .from("usage_ledger")
        .delete()
        .eq("meeting_session_id", sessionId);
      if (sessionUpdate.error) console.error("Failed to release meeting session", sessionUpdate.error);
      if (usageDelete.error) console.error("Failed to release usage reservation", usageDelete.error);
    };

    const sonioxResponse = await fetch(
      "https://api.soniox.com/v1/auth/temporary-api-key",
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${sonioxApiKey}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          usage_type: "transcribe_websocket",
          expires_in_seconds: 60,
          single_use: true,
          max_session_duration_seconds: durationLimitSeconds,
          client_reference_id: `${user.id}:${sessionId}`,
        }),
      },
    );
    if (!sonioxResponse.ok) {
      console.error("Soniox temporary key failed", sonioxResponse.status, await sonioxResponse.text());
      throw new HttpError(502, "TRANSCRIPTION_PROVIDER_FAILED");
    }
    const temporaryKey = await sonioxResponse.json();
    await adminClient.from("meeting_sessions").update({ status: "active" }).eq("id", sessionId);
    cleanupReservation = undefined;
    return jsonResponse({
      sessionId,
      allowance: reservation.allowance,
      durationLimitSeconds,
      temporaryApiKey: temporaryKey.api_key,
      expiresAt: temporaryKey.expires_at,
    });
  } catch (error) {
    if (cleanupReservation) {
      try {
        await cleanupReservation();
      } catch (cleanupError) {
        console.error("Failed to clean up rejected meeting", cleanupError);
      }
    }
    return failure(error);
  }
});
