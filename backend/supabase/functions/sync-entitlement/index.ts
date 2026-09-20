import {
  corsHeaders,
  failure,
  HttpError,
  jsonResponse,
  requireUser,
  requiredEnv,
} from "../_shared/http.ts";
import { fetchSubscriber, snapshotFromSubscriber } from "../_shared/revenuecat.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return jsonResponse({ error: "METHOD_NOT_ALLOWED" }, 405);
  try {
    const { user, adminClient } = await requireUser(req);
    let payload: unknown;
    try {
      payload = await fetchSubscriber(user.id, requiredEnv("REVENUECAT_SECRET_API_KEY"));
    } catch (error) {
      console.error(error);
      throw new HttpError(502, "SUBSCRIPTION_PROVIDER_FAILED");
    }
    const entitlementId = Deno.env.get("REVENUECAT_ENTITLEMENT_ID")?.trim() || "pro";
    const snapshot = snapshotFromSubscriber(payload, entitlementId);
    const timestamp = Date.now();
    const { error } = await adminClient.rpc("apply_revenuecat_event", {
      p_event_id: `sync:${user.id}`,
      p_event_type: "CUSTOMER_SYNC",
      p_user_id: user.id,
      p_entitlement_id: entitlementId,
      p_status: snapshot.active ? "active" : "expired",
      p_product_id: snapshot.productId,
      p_expires_at: snapshot.expiresAt,
      p_event_timestamp_ms: timestamp,
      p_payload: payload,
    });
    if (error) throw error;
    return jsonResponse({
      active: snapshot.active,
      entitlementId,
      expiresAt: snapshot.expiresAt,
      productId: snapshot.productId,
    });
  } catch (error) {
    return failure(error);
  }
});
