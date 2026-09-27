import {
  corsHeaders,
  failure,
  HttpError,
  jsonResponse,
  requireUser,
} from "../_shared/http.ts";
import {
  confirmedAccountDeletion,
  deleteSubscriber,
} from "../_shared/revenuecat.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return jsonResponse({ error: "METHOD_NOT_ALLOWED" }, 405);
  try {
    const { user, adminClient } = await requireUser(req);
    let body: unknown = {};
    try {
      body = await req.json();
    } catch (_) {
      body = {};
    }
    if (!confirmedAccountDeletion(body, user.email)) {
      throw new HttpError(400, "CONFIRMATION_MISMATCH");
    }

    let billingRecordDeleted = false;
    const revenueCatKey = Deno.env.get("REVENUECAT_SECRET_API_KEY")?.trim();
    if (revenueCatKey) {
      try {
        await deleteSubscriber(user.id, revenueCatKey);
        billingRecordDeleted = true;
      } catch (error) {
        console.error(error);
      }
    }

    const remembered = await adminClient.rpc("remember_deleted_free_usage", {
      p_user_id: user.id,
    });
    if (remembered.error) throw new HttpError(500, "ACCOUNT_DELETE_FAILED");

    const purged = await adminClient.rpc("purge_account_references", {
      p_user_id: user.id,
    });
    if (purged.error) throw new HttpError(500, "ACCOUNT_DELETE_FAILED");

    const deleted = await adminClient.auth.admin.deleteUser(user.id, false);
    if (deleted.error) throw new HttpError(500, "ACCOUNT_DELETE_FAILED");

    return jsonResponse({ deleted: true, billingRecordDeleted });
  } catch (error) {
    return failure(error);
  }
});
