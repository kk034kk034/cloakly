import 'package:cloakly_mobile/services/hosted_plan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('free remaining seconds never go below zero', () {
    expect(remainingFreeSecondsFromReservations(const []), 1800);
    expect(remainingFreeSecondsFromReservations(const [600, 300]), 900);
    expect(remainingFreeSecondsFromReservations(const [1800]), 0);
    expect(remainingFreeSecondsFromReservations(const [1200, 900]), 0);
  });

  test('remaining time copy uses minutes and seconds', () {
    expect(formatRemainingFreeTime(1800), '今日免費額度剩餘 30 分鐘');
    expect(formatRemainingFreeTime(90), '今日免費額度剩餘 1 分 30 秒');
    expect(formatRemainingFreeTime(45), '今日免費額度剩餘 45 秒');
  });

  test('used free seconds match the daily cap', () {
    const plan = HostedPlanSnapshot(isPro: false, remainingFreeSeconds: 600);
    expect(plan.usedFreeSeconds, 1200);
  });

  test('cancelled purchase errors are recognized without the store SDK', () {
    expect(looksLikePurchaseCancelled('PurchaseCancelledError'), isTrue);
    expect(looksLikePurchaseCancelled('network timeout'), isFalse);
  });
}
