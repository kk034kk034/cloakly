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
  try {
    const { user, adminClient } = await requireUser(req);
    const response = await fetch(
      `https://api.revenuecat.com/v1/subscribers/${encodeURIComponent(user.id)}`,
      { headers: { Authorization: `Bearer ${requiredEnv("REVENUECAT_SECRET_API_KEY")}` } },
    );
    if (!response.ok) {
      console.error("RevenueCat subscriber lookup failed", response.status, await response.text());
      throw new HttpError(502, "SUBSCRIPTION_PROVIDER_FAILED");
    }
    const payload = await response.json();
    const entitlementId = Deno.env.get("REVENUECAT_ENTITLEMENT_ID")?.trim() || "pro";
    const entitlement = payload?.subscriber?.entitlements?.[entitlementId];
    const expiresAt = typeof entitlement?.expires_date === "string"
      ? entitlement.expires_date
      : null;
    const active = entitlement != null &&
      (expiresAt === null || Date.parse(expiresAt) > Date.now());
    const timestamp = Date.now();
    const { error } = await adminClient.rpc("apply_revenuecat_event", {
      p_event_id: `sync:${user.id}:${timestamp}`,
      p_event_type: "CUSTOMER_SYNC",
      p_user_id: user.id,
      p_entitlement_id: entitlementId,
      p_status: active ? "active" : "expired",
      p_product_id: entitlement?.product_identifier ?? null,
      p_expires_at: expiresAt,
      p_event_timestamp_ms: timestamp,
      p_payload: payload,
    });
    if (error) throw error;
    return jsonResponse({ active, entitlementId, expiresAt });
  } catch (error) {
    return failure(error);
  }
});
