const hostedFreeDailyLimitSeconds = 1800;

class HostedPlanSnapshot {
  const HostedPlanSnapshot({
    required this.isPro,
    required this.remainingFreeSeconds,
    this.productId,
    this.expiresAt,
  });

  final bool isPro;
  final int remainingFreeSeconds;
  final String? productId;
  final DateTime? expiresAt;

  int get usedFreeSeconds =>
      (hostedFreeDailyLimitSeconds - remainingFreeSeconds).clamp(
        0,
        hostedFreeDailyLimitSeconds,
      );
}

int remainingFreeSecondsFromReservations(Iterable<int> reservedSeconds) {
  final used = reservedSeconds.fold<int>(0, (sum, value) => sum + value);
  return (hostedFreeDailyLimitSeconds - used).clamp(
    0,
    hostedFreeDailyLimitSeconds,
  );
}

String formatRemainingFreeTime(int seconds) {
  final safe = seconds.clamp(0, hostedFreeDailyLimitSeconds);
  final minutes = safe ~/ 60;
  final remainder = safe % 60;
  if (minutes == 0) return '今日免費額度剩餘 $remainder 秒';
  if (remainder == 0) return '今日免費額度剩餘 $minutes 分鐘';
  return '今日免費額度剩餘 $minutes 分 $remainder 秒';
}

/// Play 在商品尚未審核時，會把套件名稱與 unreviewed 接在標題後面。
String displayStoreProductTitle(String raw) {
  final title = raw.trim();
  final cut = title.indexOf(' (');
  if (cut <= 0) return title;
  final suffix = title.substring(cut).toLowerCase();
  if (suffix.contains('unreviewed') || suffix.contains('.')) {
    return title.substring(0, cut).trim();
  }
  return title;
}

bool looksLikePurchaseCancelled(Object error) {
  final text = error.toString().toLowerCase();
  return text.contains('purchasecancelled') ||
      text.contains('purchase_cancelled') ||
      text.contains('purchase was cancelled');
}
