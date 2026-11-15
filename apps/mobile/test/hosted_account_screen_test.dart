import 'dart:async';

import 'package:cloakly_core/l10n/app_localizations.dart';
import 'package:cloakly_core/l10n/cloakly_locale.dart';
import 'package:cloakly_mobile/features/account_copy.dart';
import 'package:cloakly_mobile/l10n/hosted_localizations.dart';
import 'package:cloakly_mobile/features/current_plan_row.dart';
import 'package:cloakly_mobile/features/hosted_account_screen.dart';
import 'package:cloakly_mobile/features/hosted_subscription_screen.dart';
import 'package:cloakly_mobile/services/hosted_billing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('plan copy stays stable in zh-Hant and en', () {
    final zh = AccountCopy.zh();
    final en = AccountCopy.en();
    expect(zh.accountTitle, '帳號與訂閱');
    expect(zh.currentPlan, '目前方案');
    expect(zh.restorePurchases, '恢復購買');
    expect(zh.manageSubscription, '管理商店訂閱');
    expect(zh.freePlanSummary, contains('會議每天合計 30 分鐘'));
    expect(zh.billingUnavailable, contains('RevenueCat 公開 SDK key'));
    expect(zh.proActiveHint, contains('恢復購買'));
    expect(zh.autoRenewDisclosure, contains('USD 19.99'));
    expect(zh.autoRenewDisclosure, contains('USD 199.99'));
    expect(zh.autoRenewDisclosure, contains('自動續訂'));
    expect(zh.privacyUrl, AccountCopy.privacyUrlZh);
    expect(zh.termsUrl, AccountCopy.termsUrlZh);

    expect(en.accountTitle, 'Account & Subscription');
    expect(en.currentPlan, 'Current plan');
    expect(en.restorePurchases, 'Restore Purchases');
    expect(en.manageSubscription, 'Manage Subscription');
    expect(en.autoRenewDisclosure, contains('auto-renewable'));
    expect(en.autoRenewDisclosure, contains('USD 19.99'));
    expect(en.privacyUrl, AccountCopy.privacyUrlEn);
    expect(en.termsUrl, AccountCopy.termsUrlEn);
    expect(
      zh.rowStatus(
        phase: PlanRowPhase.ready,
        isPro: false,
        plan: const HostedPlanSnapshot(isPro: false, remainingFreeSeconds: 90),
      ),
      '免費 · 今日剩餘 1 分 30 秒',
    );
    expect(
      en.rowStatus(
        phase: PlanRowPhase.ready,
        isPro: false,
        plan: const HostedPlanSnapshot(isPro: false, remainingFreeSeconds: 45),
      ),
      'Free · 45 sec left today',
    );
    final expires = DateTime.utc(2026, 12, 1, 8);
    final date = DateFormat('yyyy/MM/dd').format(expires.toLocal());
    expect(
      zh.rowStatus(
        phase: PlanRowPhase.ready,
        isPro: true,
        plan: HostedPlanSnapshot(
          isPro: true,
          remainingFreeSeconds: 0,
          expiresAt: expires,
        ),
      ),
      'Pro · 有效至 $date',
    );
    expect(
      en.rowStatus(phase: PlanRowPhase.failed, isPro: false, plan: null),
      "Couldn't load",
    );
    expect(zh.noOfferings(true), contains('App Store'));
    expect(zh.noOfferings(false), contains('Google Play'));
  });

  test('period labels keep the store wording', () {
    expect(periodLabelForType(PackageType.monthly), '月繳');
    expect(periodLabelForType(PackageType.annual), '年繳');
    expect(periodLabelForType(PackageType.monthly, english: true), 'Monthly');
    expect(periodLabelForType(PackageType.annual, english: true), 'Yearly');
    expect(periodLabelForType(PackageType.lifetime, english: true), 'Lifetime');
  });

  test('delete-account errors keep the zh-Hant outcome', () {
    final zh = AccountCopy.zh();
    expect(
      deleteAccountErrorMessage(
        const FunctionException(
          status: 400,
          details: {'error': 'CONFIRMATION_MISMATCH'},
        ),
        zh,
      ),
      '確認資料不一致，帳號尚未刪除。',
    );
    expect(
      deleteAccountErrorMessage(
        const FunctionException(
          status: 401,
          details: {'error': 'AUTH_REQUIRED'},
        ),
        zh,
      ),
      '登入已失效，請重新登入後再刪除。',
    );
    expect(
      deleteAccountErrorMessage(const FunctionException(status: 404), zh),
      '後端尚未部署刪除帳號，帳號尚未刪除。',
    );
    expect(
      deleteAccountErrorMessage(const FunctionException(status: 500), zh),
      '無法刪除帳號（500）。帳號尚未刪除。',
    );
    expect(
      deleteAccountErrorMessage(
        const FunctionException(status: 500),
        AccountCopy.en(),
      ),
      'Could not delete the account (500). The account was not deleted.',
    );
  });

  testWidgets('current plan row stays one height for every state', (
    tester,
  ) async {
    const samples = <(bool, String)>[
      (true, ''),
      (false, '免費 · 今日剩餘 30 分鐘'),
      (false, 'Pro · Valid until 2026/12/01'),
      (false, "Couldn't load"),
      (false, 'Not set up'),
      (false, '免費 · 今日剩餘 1 分 30 秒，後面還有一段很長的說明也不該把列撐高'),
    ];
    double? logoutDy;
    for (final sample in samples) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                CurrentPlanRow(
                  title: '目前方案',
                  status: sample.$2,
                  loading: sample.$1,
                  onTap: () {},
                ),
                const Text('登出'),
              ],
            ),
          ),
        ),
      );
      expect(
        tester.getSize(find.byType(CurrentPlanRow)).height,
        CurrentPlanRow.height,
      );
      final dy = tester.getTopLeft(find.text('登出')).dy;
      logoutDy ??= dy;
      expect(dy, logoutDy);
      expect(tester.takeException(), isNull);
    }

    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CurrentPlanRow(
            title: '目前方案',
            status: '',
            loading: true,
            onTap: () => taps++,
          ),
        ),
      ),
    );
    expect(find.byKey(CurrentPlanRow.skeletonKey), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    await tester.tap(find.byType(CurrentPlanRow));
    expect(taps, 1);
  });

  testWidgets(
    'account actions stay put while the plan loads, arrives, or fails',
    (tester) async {
      final pending = Completer<HostedPlanSnapshot?>();
      await _pumpAccount(tester, planLoader: () => pending.future);
      await tester.pumpAndSettle();

      expect(find.text('帳號與訂閱'), findsOneWidget);
      expect(find.text('目前方案'), findsOneWidget);
      expect(find.byKey(CurrentPlanRow.skeletonKey), findsOneWidget);
      expect(find.text('恢復購買'), findsNothing);
      expect(find.text('管理商店訂閱'), findsNothing);
      expect(find.text('登出'), findsOneWidget);
      expect(find.text('刪除帳號'), findsOneWidget);
      final logoutDy = tester.getTopLeft(find.text('登出')).dy;
      final deleteDy = tester.getTopLeft(find.text('刪除帳號')).dy;
      expect(
        tester.getSize(find.byType(CurrentPlanRow)).height,
        CurrentPlanRow.height,
      );

      pending.complete(
        const HostedPlanSnapshot(isPro: false, remainingFreeSeconds: 1800),
      );
      await tester.pumpAndSettle();

      expect(find.text('免費 · 今日剩餘 30 分鐘'), findsOneWidget);
      expect(tester.getTopLeft(find.text('登出')).dy, logoutDy);
      expect(tester.getTopLeft(find.text('刪除帳號')).dy, deleteDy);
      expect(find.text('恢復購買'), findsNothing);

      await _pumpAccount(
        tester,
        key: const Key('plan-failed'),
        planLoader: () async => throw StateError('offerings timed out'),
      );
      await tester.pumpAndSettle();
      expect(find.text('無法載入'), findsOneWidget);
      expect(find.textContaining('offerings timed out'), findsNothing);
      expect(tester.getTopLeft(find.text('登出')).dy, logoutDy);
      expect(
        tester.getSize(find.byType(CurrentPlanRow)).height,
        CurrentPlanRow.height,
      );
    },
  );

  testWidgets(
    'tapping the plan row opens purchases without moving account actions',
    (tester) async {
      await _pumpAccount(tester);
      await tester.pumpAndSettle();
      final logoutDy = tester.getTopLeft(find.text('登出')).dy;
      expect(find.text('尚未設定'), findsOneWidget);

      await tester.tap(find.byType(CurrentPlanRow));
      await tester.pumpAndSettle();

      expect(find.text('目前方案'), findsWidgets);
      expect(
        find.text(AccountCopy.zh().billingUnavailable),
        findsOneWidget,
      );
      expect(find.text('恢復購買'), findsNothing);
      expect(find.text('管理商店訂閱'), findsNothing);
      expect(find.textContaining('自動續訂'), findsOneWidget);
      expect(find.text('隱私權政策'), findsOneWidget);
      expect(find.text('使用條款（EULA）'), findsOneWidget);
      expect(find.text('登出'), findsNothing);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('登出'), findsOneWidget);
      expect(find.text('刪除帳號'), findsOneWidget);
      expect(tester.getTopLeft(find.text('登出')).dy, logoutDy);
    },
  );

  testWidgets('english account screen uses the english plan copy', (
    tester,
  ) async {
    await _pumpAccount(tester, locale: const Locale('en'));
    await tester.pumpAndSettle();
    expect(find.text('Account & Subscription'), findsOneWidget);
    expect(find.text('Current plan'), findsOneWidget);
    expect(find.text('Not set up'), findsOneWidget);
    expect(find.text('Log out'), findsOneWidget);
    expect(find.text('Delete account'), findsOneWidget);

    await tester.tap(find.byType(CurrentPlanRow));
    await tester.pumpAndSettle();
    expect(find.text('Restore Purchases'), findsNothing);
    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('Terms of Use (EULA)'), findsOneWidget);
    expect(find.textContaining('auto-renewable'), findsOneWidget);
  });

  testWidgets('plan screen keeps purchase, restore, manage, and disclosures', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final purchased = <int>[];
    var restored = 0;
    var managed = 0;
    final links = <String>[];
    final zh = AccountCopy.zh();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh', 'TW'),
        home: Scaffold(
          body: ListView(
            children: [
              SubscriptionPlanBody(
                copy: zh,
                ready: true,
                busy: false,
                isPro: false,
                storeIsIos: true,
                plan: const HostedPlanSnapshot(
                  isPro: false,
                  remainingFreeSeconds: 600,
                  productId: 'cloakly_pro_monthly',
                ),
                offers: const [
                  SubscriptionOffer(
                    title: 'Cloakly Pro 月繳',
                    subtitle: '月繳 · 每月續訂',
                    priceLabel: r'US$19.99',
                  ),
                  SubscriptionOffer(
                    title: 'Cloakly Pro 年繳',
                    subtitle: '年繳 · 每年續訂',
                    priceLabel: r'US$199.99',
                  ),
                ],
                onPurchase: purchased.add,
                onRestore: () => restored++,
                onManage: () => managed++,
                onOpenLink: links.add,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('目前方案：免費'), findsOneWidget);
    expect(find.textContaining('今日免費額度剩餘 10 分鐘'), findsOneWidget);
    expect(find.textContaining('商品：cloakly_pro_monthly'), findsOneWidget);
    expect(find.text(zh.freePlanSummary), findsOneWidget);
    expect(find.text('Cloakly Pro 月繳'), findsOneWidget);
    expect(find.text('Cloakly Pro 年繳'), findsOneWidget);
    expect(find.textContaining('USD 19.99'), findsOneWidget);
    expect(find.textContaining('1 個月'), findsOneWidget);
    expect(find.text('隱私權政策'), findsOneWidget);
    expect(find.text('使用條款（EULA）'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(SubscriptionPlanBody.progressKey)).height,
      4,
    );

    await tester.tap(find.text(r'US$19.99'));
    await tester.tap(find.text('恢復購買'));
    await tester.tap(find.text('管理商店訂閱'));
    await tester.ensureVisible(find.text('隱私權政策'));
    await tester.tap(find.text('隱私權政策'));
    await tester.ensureVisible(find.text('使用條款（EULA）'));
    await tester.tap(find.text('使用條款（EULA）'));
    await tester.pump();

    expect(purchased, [0]);
    expect(restored, 1);
    expect(managed, 1);
    expect(links, [zh.privacyUrl, zh.termsUrl]);
  });

  testWidgets('an active pro plan still offers restore and manage', (
    tester,
  ) async {
    final en = AccountCopy.en();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        home: Scaffold(
          body: ListView(
            children: [
              SubscriptionPlanBody(
                copy: en,
                ready: true,
                busy: true,
                isPro: true,
                storeIsIos: false,
                offers: const [
                  SubscriptionOffer(
                    title: 'Hidden while subscribed',
                    subtitle: 'Monthly',
                    priceLabel: r'US$19.99',
                  ),
                ],
                plan: HostedPlanSnapshot(
                  isPro: true,
                  remainingFreeSeconds: 0,
                  expiresAt: DateTime.utc(2026, 12, 1),
                ),
                onPurchase: (_) {},
                onRestore: () {},
                onManage: () {},
                onOpenLink: (_) {},
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Current plan: Pro'), findsOneWidget);
    expect(find.textContaining('Valid until'), findsOneWidget);
    expect(find.text(en.proActiveHint), findsOneWidget);
    expect(find.text('Hidden while subscribed'), findsNothing);
    expect(find.text('Restore Purchases'), findsOneWidget);
    expect(find.text('Manage Subscription'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsWidgets);
    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('Terms of Use (EULA)'), findsOneWidget);
    final restore = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Restore Purchases'),
    );
    expect(restore.onPressed, isNull);
  });
}

Future<void> _pumpAccount(
  WidgetTester tester, {
  Locale locale = const Locale('zh', 'TW'),
  HostedPlanLoader? planLoader,
  Key? key,
}) {
  return tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: [
          HostedLocalizations.delegate,
          ...AppLocalizations.localizationsDelegates,
        ],
        localeResolutionCallback: resolveCloaklyLocale,
        builder: cloaklyLocaleBuilder,
        home: HostedAccountScreen(
          key: key,
          accountEmail: 'member@example.com',
          planLoader: planLoader,
        ),
      ),
    ),
  );
}
