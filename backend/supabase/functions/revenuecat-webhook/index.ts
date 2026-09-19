import {
  failure,
  HttpError,
  jsonResponse,
  requiredEnv,
} from "../_shared/http.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

const uuidPattern = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

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
    const entitlementIds = Array.isArray(event.entitlement_ids)
      ? event.entitlement_ids
      : [event.entitlement_id].filter(Boolean);
    if (!entitlementIds.includes(expectedEntitlement)) {
      return jsonResponse({ ok: true, ignored: "OTHER_ENTITLEMENT" });
    }

    const candidates = [event.app_user_id, event.original_app_user_id, ...(event.aliases ?? [])]
      .filter((value, index, all) => typeof value === "string" && uuidPattern.test(value) && all.indexOf(value) === index);
    if (candidates.length === 0) throw new HttpError(400, "NO_SUPABASE_USER_ID");

    const secretKey = Deno.env.get("SUPABASE_SECRET_KEY") ?? requiredEnv("SUPABASE_SERVICE_ROLE_KEY");
    const admin = createClient(requiredEnv("SUPABASE_URL"), secretKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const { data: profiles, error: profileError } = await admin
      .from("profiles").select("id").in("id", candidates);
    if (profileError) throw profileError;
    const known = new Set((profiles ?? []).map((row) => row.id));
    const userId = candidates.find((candidate) => known.has(candidate));
    if (!userId) throw new HttpError(404, "USER_NOT_FOUND");

    const expirationMs = typeof event.expiration_at_ms === "number"
      ? event.expiration_at_ms
      : null;
    const expired = event.type === "EXPIRATION" ||
      (expirationMs !== null && expirationMs <= Date.now());
    const { data, error } = await admin.rpc("apply_revenuecat_event", {
      p_event_id: event.id,
      p_event_type: event.type,
      p_user_id: userId,
      p_entitlement_id: expectedEntitlement,
      p_status: expired ? "expired" : "active",
      p_product_id: event.product_id ?? null,
      p_expires_at: expirationMs === null ? null : new Date(expirationMs).toISOString(),
      p_event_timestamp_ms: Number(event.event_timestamp_ms ?? Date.now()),
      p_payload: payload,
    });
    if (error) throw error;
    return jsonResponse({ ok: true, applied: data === true });
  } catch (error) {
    return failure(error);
  }
});
