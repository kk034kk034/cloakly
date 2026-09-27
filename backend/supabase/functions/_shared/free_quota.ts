import { SupabaseClient } from "npm:@supabase/supabase-js@2";
import { HttpError } from "./http.ts";

const quotaStatuses: Array<[string, number]> = [
  ["FREE_POOL_EXHAUSTED", 429],
  ["FREE_DAILY_LIMIT_REACHED", 429],
  ["FREE_QUESTION_LIMIT_REACHED", 429],
  ["FREE_PLAN_LIMIT_REACHED", 429],
  ["DEVICE_FREE_ACCOUNT_IN_USE", 403],
  ["DEVICE_REQUIRED", 400],
];

export function deviceIdOf(body: unknown): string {
  if (!body || typeof body !== "object") return "";
  const value = (body as { deviceId?: unknown }).deviceId;
  return typeof value === "string" ? value.trim() : "";
}

export function throwIfQuotaError(error: { message?: string }): void {
  const message = error.message ?? "";
  for (const [code, status] of quotaStatuses) {
    if (message.includes(code)) throw new HttpError(status, code);
  }
}

export async function claimFreeDevice(
  userClient: SupabaseClient,
  deviceId: string,
): Promise<void> {
  const { error } = await userClient.rpc("claim_free_device", {
    p_device_id: deviceId,
  });
  if (error) {
    throwIfQuotaError(error);
    throw new HttpError(500, "DEVICE_CHECK_FAILED");
  }
}

export async function consumeFreeAi(
  userClient: SupabaseClient,
  deviceId: string,
  action: "project_question" | "project_plan",
): Promise<boolean> {
  const { data, error } = await userClient.rpc("consume_free_ai", {
    p_device_id: deviceId,
    p_action: action,
  });
  if (error) {
    throwIfQuotaError(error);
    throw new HttpError(500, "AI_QUOTA_CHECK_FAILED");
  }
  return data === true;
}

export async function releaseFreeAi(
  userClient: SupabaseClient,
  action: "project_question" | "project_plan",
): Promise<void> {
  const { error } = await userClient.rpc("release_free_ai", { p_action: action });
  if (error) console.error("Failed to release free AI use", error);
}
