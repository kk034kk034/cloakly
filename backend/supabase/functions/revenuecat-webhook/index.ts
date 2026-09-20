import {
  failure,
  HttpError,
  jsonResponse,
  requiredEnv,
} from "../_shared/http.ts";
import {
  fetchSubscriber,
  snapshotForUser,
  subscriberIdsFromEvent,
} from "../_shared/revenuecat.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

Deno.serve(async (req) => {
  if (req.method !== "POST") return jsonResponse({ error: "METHOD_NOT_ALLOWED" }, 405);
  try {
    if (req.headers.get("Authorization") !== requiredEnv("REVENUECAT_WEBHOOK_AUTH")) {
      throw new HttpError(401, "INVALID_WEBHOOK_SECRET");
    }
    const payload = await req.json();
    const event = payload?.event;
    if (!event?.id || !event?.type) throw new HttpError(400, "INVALID_EVENT");

    const expectedEntitlement = Deno.env.get("REVENUECAT_ENTITLEMENT_ID")?.trim() || "pro";
    const candidates = subscriberIdsFromEvent(event);
    if (candidates.length === 0) {
      return jsonResponse({ ok: true, ignored: "NO_SUPABASE_USER_ID" });
    }

    const secretKey = Deno.env.get("SUPABASE_SECRET_KEY") ?? requiredEnv("SUPABASE_SERVICE_ROLE_KEY");
    const admin = createClient(requiredEnv("SUPABASE_URL"), secretKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const { data: profiles, error: profileError } = await admin
      .from("profiles").select("id").in("id", candidates);
    if (profileError) throw profileError;
    const known = new Set((profiles ?? []).map((row) => row.id as string));
    const userIds = candidates.filter((candidate) => known.has(candidate));
    if (userIds.length === 0) {
      return jsonResponse({ ok: true, ignored: "USER_NOT_FOUND" });
    }

    const revenueCatSecret = requiredEnv("REVENUECAT_SECRET_API_KEY");
    const eventTimestampMs = Number(event.event_timestamp_ms ?? Date.now());
    const applied: string[] = [];
    for (const userId of userIds) {
      let subscriber: unknown;
      try {
        subscriber = await fetchSubscriber(userId, revenueCatSecret);
      } catch (error) {
        console.error(error);
        throw new HttpError(502, "SUBSCRIPTION_PROVIDER_FAILED");
      }
      const snapshot = snapshotForUser(userId, event, subscriber, expectedEntitlement);
      const { data, error } = await admin.rpc("apply_revenuecat_event", {
        p_event_id: `${event.id}:${userId}`,
        p_event_type: event.type,
        p_user_id: userId,
        p_entitlement_id: expectedEntitlement,
        p_status: snapshot.active ? "active" : "expired",
        p_product_id: snapshot.productId ?? event.product_id ?? null,
        p_expires_at: snapshot.expiresAt,
        p_event_timestamp_ms: eventTimestampMs,
        p_payload: { event, subscriber },
      });
      if (error) throw error;
      if (data === true) applied.push(userId);
    }
    return jsonResponse({ ok: true, applied });
  } catch (error) {
    return failure(error);
  }
});
