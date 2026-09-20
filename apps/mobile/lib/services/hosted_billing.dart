import 'package:cloakly_mobile/config/hosted_config.dart';
import 'package:cloakly_mobile/services/hosted_plan.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

export 'package:cloakly_mobile/services/hosted_plan.dart';

String packagePeriodLabel(Package package) {
  return switch (package.packageType) {
    PackageType.annual => '年繳',
    PackageType.sixMonth => '半年繳',
    PackageType.threeMonth => '季繳',
    PackageType.twoMonth => '兩個月',
    PackageType.monthly => '月繳',
    PackageType.weekly => '週繳',
    PackageType.lifetime => '永久',
    _ => '訂閱',
  };
}

bool isPurchaseCancelled(Object error) {
  if (error is PlatformException) {
    try {
      return PurchasesErrorHelper.getErrorCode(error) ==
          PurchasesErrorCode.purchaseCancelledError;
    } catch (_) {}
  }
  return looksLikePurchaseCancelled(error);
}

class HostedBilling {
  HostedBilling._(this._supabase);

  final SupabaseClient _supabase;

  static Future<HostedBilling?> configure({
    required SupabaseClient supabase,
    String? appUserId,
  }) async {
    final apiKey = HostedConfig.revenueCatApiKey;
    if (apiKey.isEmpty) return null;
    try {
      await Purchases.setLogLevel(
        kDebugMode ? LogLevel.debug : LogLevel.info,
      );
      final configuration = PurchasesConfiguration(apiKey);
      if (appUserId != null && appUserId.isNotEmpty) {
        configuration.appUserID = appUserId;
      }
      configuration.shouldShowInAppMessagesAutomatically = true;
      await Purchases.configure(configuration);
      return HostedBilling._(supabase);
    } catch (error, stack) {
      debugPrint('RevenueCat 初始化失敗：$error\n$stack');
      return null;
    }
  }

  Future<void> identify({required String userId, String? email}) async {
    final currentId = await Purchases.appUserID;
    if (currentId != userId) {
      final anonymous = await Purchases.isAnonymous;
      if (!anonymous && currentId.isNotEmpty) {
        try {
          await Purchases.logOut();
        } catch (_) {}
      }
      await Purchases.logIn(userId);
    }
    if (email != null && email.trim().isNotEmpty) {
      await Purchases.setEmail(email.trim());
    }
    await syncEntitlement();
  }

  Future<void> signOut() async {
    try {
      if (!await Purchases.isAnonymous) {
        await Purchases.logOut();
      }
    } catch (_) {}
  }

  Future<CustomerInfo> purchase(Package package) async {
    final result = await Purchases.purchase(PurchaseParams.package(package));
    await syncEntitlement();
    return result.customerInfo;
  }

  Future<CustomerInfo> restore() async {
    final info = await Purchases.restorePurchases();
    await syncEntitlement();
    return info;
  }

  Future<(CustomerInfo, List<Package>)> loadStore() async {
    final values = await Future.wait<Object>([
      Purchases.getCustomerInfo(),
      Purchases.getOfferings(),
    ]);
    final info = values[0] as CustomerInfo;
    final offerings = values[1] as Offerings;
    return (info, offerings.current?.availablePackages ?? const <Package>[]);
  }

  Future<void> syncEntitlement() async {
    try {
      await _supabase.functions.invoke('sync-entitlement');
    } catch (_) {
      // The signed RevenueCat webhook will reconcile the entitlement later.
    }
  }

  Future<HostedPlanSnapshot> loadPlan({CustomerInfo? customerInfo}) async {
    DateTime? expiresAt;
    String? productId;
    var isPro = false;
    final userId = _supabase.auth.currentUser?.id;

    if (userId != null) {
      try {
        final row = await _supabase
            .from('entitlements')
            .select()
            .eq('user_id', userId)
            .maybeSingle();
        if (row != null) {
          final status = row['status'] as String?;
          final rawExpires = row['expires_at'] as String?;
          expiresAt = rawExpires == null ? null : DateTime.tryParse(rawExpires);
          productId = row['product_id'] as String?;
          isPro =
              status == 'active' &&
              (expiresAt == null || expiresAt.isAfter(DateTime.now()));
        }
      } catch (_) {}
    }

    if (!isPro && customerInfo != null) {
      final entitlement =
          customerInfo.entitlements.all[HostedConfig.entitlementId];
      isPro = entitlement?.isActive == true;
      productId ??= entitlement?.productIdentifier;
      expiresAt ??= entitlement?.expirationDate == null
          ? null
          : DateTime.tryParse(entitlement!.expirationDate!);
    }

    var remaining = hostedFreeDailyLimitSeconds;
    if (!isPro && userId != null) {
      try {
        final today = DateTime.now().toUtc();
        final usageDate =
            '${today.year.toString().padLeft(4, '0')}-'
            '${today.month.toString().padLeft(2, '0')}-'
            '${today.day.toString().padLeft(2, '0')}';
        final rows = await _supabase
            .from('usage_ledger')
            .select('reserved_seconds')
            .eq('user_id', userId)
            .eq('usage_date', usageDate)
            .eq('allowance', 'free_daily');
        remaining = remainingFreeSecondsFromReservations(
          (rows as List<dynamic>).map((row) {
            final value = (row as Map)['reserved_seconds'];
            return value is int ? value : int.tryParse('$value') ?? 0;
          }),
        );
      } catch (_) {}
    }

    return HostedPlanSnapshot(
      isPro: isPro,
      remainingFreeSeconds: remaining,
      productId: productId,
      expiresAt: expiresAt,
    );
  }
}
