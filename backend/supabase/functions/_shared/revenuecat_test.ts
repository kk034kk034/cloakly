import {
  snapshotForUser,
  snapshotFromSubscriber,
  subscriberIdsFromEvent,
} from "./revenuecat.ts";

function assertEquals(actual: unknown, expected: unknown): void {
  const left = JSON.stringify(actual);
  const right = JSON.stringify(expected);
  if (left !== right) {
    throw new Error(`Expected ${right}, got ${left}`);
  }
}

Deno.test("extracts only Supabase UUIDs from webhook identities", () => {
  assertEquals(
    subscriberIdsFromEvent({
      type: "INITIAL_PURCHASE",
      app_user_id: "$RCAnonymousID:abc",
      original_app_user_id: "11111111-1111-4111-8111-111111111111",
      aliases: ["22222222-2222-4222-8222-222222222222", "not-a-uuid"],
    }),
    [
      "11111111-1111-4111-8111-111111111111",
      "22222222-2222-4222-8222-222222222222",
    ],
  );
});

Deno.test("TRANSFER includes source and destination customers", () => {
  assertEquals(
    subscriberIdsFromEvent({
      type: "TRANSFER",
      app_user_id: "11111111-1111-4111-8111-111111111111",
      transferred_from: ["22222222-2222-4222-8222-222222222222"],
      transferred_to: ["11111111-1111-4111-8111-111111111111"],
    }),
    [
      "22222222-2222-4222-8222-222222222222",
      "11111111-1111-4111-8111-111111111111",
    ],
  );
});

Deno.test("subscriber snapshot treats future expiry as active", () => {
  const expiresAt = new Date(Date.now() + 60_000).toISOString();
  assertEquals(
    snapshotFromSubscriber({
      subscriber: {
        entitlements: {
          pro: { expires_date: expiresAt, product_identifier: "cloakly_pro_monthly" },
        },
      },
    }, "pro"),
    { active: true, productId: "cloakly_pro_monthly", expiresAt },
  );
});

Deno.test("TRANSFER source is expired even if the destination still has Pro", () => {
  const expiresAt = new Date(Date.now() + 60_000).toISOString();
  const payload = {
    subscriber: {
      entitlements: {
        pro: { expires_date: expiresAt, product_identifier: "cloakly_pro_monthly" },
      },
    },
  };
  const event = {
    type: "TRANSFER",
    transferred_from: ["22222222-2222-4222-8222-222222222222"],
    transferred_to: ["11111111-1111-4111-8111-111111111111"],
  };
  assertEquals(
    snapshotForUser("22222222-2222-4222-8222-222222222222", event, payload, "pro").active,
    false,
  );
  assertEquals(
    snapshotForUser("11111111-1111-4111-8111-111111111111", event, payload, "pro").active,
    true,
  );
});
