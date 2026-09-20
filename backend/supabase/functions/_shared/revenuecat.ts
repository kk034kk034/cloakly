export const uuidPattern =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

export type RevenueCatEvent = {
  id?: unknown;
  type?: unknown;
  app_user_id?: unknown;
  original_app_user_id?: unknown;
  aliases?: unknown;
  transferred_from?: unknown;
  transferred_to?: unknown;
  entitlement_ids?: unknown;
  entitlement_id?: unknown;
  product_id?: unknown;
  expiration_at_ms?: unknown;
  event_timestamp_ms?: unknown;
};

export type EntitlementSnapshot = {
  active: boolean;
  productId: string | null;
  expiresAt: string | null;
};

export function uniqueStrings(values: unknown[]): string[] {
  return values.filter((value, index, all): value is string =>
    typeof value === "string" && value.length > 0 && all.indexOf(value) === index
  );
}

export function uniqueUuids(values: unknown[]): string[] {
  return uniqueStrings(values).filter((value) => uuidPattern.test(value));
}

function stringList(value: unknown): unknown[] {
  return Array.isArray(value) ? value : [value];
}

export function subscriberIdsFromEvent(event: RevenueCatEvent): string[] {
  if (event.type === "TRANSFER") {
    return uniqueUuids([
      ...stringList(event.transferred_from),
      ...stringList(event.transferred_to),
      event.app_user_id,
    ]);
  }
  return uniqueUuids([
    event.app_user_id,
    event.original_app_user_id,
    ...stringList(event.aliases),
  ]);
}

export function snapshotFromSubscriber(
  payload: unknown,
  entitlementId: string,
): EntitlementSnapshot {
  const subscriber = (payload as {
    subscriber?: {
      entitlements?: Record<string, {
        expires_date?: string | null;
        product_identifier?: string | null;
      }>;
    };
  } | null)?.subscriber;
  const entitlement = subscriber?.entitlements?.[entitlementId];
  const expiresAt = typeof entitlement?.expires_date === "string"
    ? entitlement.expires_date
    : null;
  const active = entitlement != null &&
    (expiresAt === null || Date.parse(expiresAt) > Date.now());
  return {
    active,
    productId: entitlement?.product_identifier ?? null,
    expiresAt,
  };
}

export function snapshotForUser(
  userId: string,
  event: RevenueCatEvent,
  subscriberPayload: unknown,
  entitlementId: string,
): EntitlementSnapshot {
  const snapshot = snapshotFromSubscriber(subscriberPayload, entitlementId);
  if (event.type === "TRANSFER" && uniqueStrings(stringList(event.transferred_from)).includes(userId)) {
    return { ...snapshot, active: false };
  }
  if (event.type === "EXPIRATION") {
    return { ...snapshot, active: false };
  }
  return snapshot;
}

export async function fetchSubscriber(
  appUserId: string,
  secretKey: string,
): Promise<unknown> {
  const response = await fetch(
    `https://api.revenuecat.com/v1/subscribers/${encodeURIComponent(appUserId)}`,
    { headers: { Authorization: `Bearer ${secretKey}` } },
  );
  if (response.status === 404) return { subscriber: { entitlements: {} } };
  if (!response.ok) {
    const body = await response.text();
    throw new Error(`RevenueCat subscriber lookup failed ${response.status} ${body}`);
  }
  return await response.json();
}
