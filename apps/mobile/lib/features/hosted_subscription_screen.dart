import 'dart:async';
import 'dart:io';

import 'package:cloakly_mobile/config/hosted_config.dart';
import 'package:cloakly_mobile/features/account_copy.dart';
import 'package:cloakly_mobile/services/hosted_billing.dart';
import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class SubscriptionOffer {
  const SubscriptionOffer({
    required this.title,
    required this.subtitle,
    required this.priceLabel,
  });

  final String title;
  final String subtitle;
  final String priceLabel;
}

class HostedSubscriptionScreen extends StatefulWidget {
  const HostedSubscriptionScreen({
    this.billing,
    this.onCustomerInfo,
    super.key,
  });

  final HostedBilling? billing;
  final ValueChanged<CustomerInfo>? onCustomerInfo;

  @override
  State<HostedSubscriptionScreen> createState() =>
      _HostedSubscriptionScreenState();
}

class _HostedSubscriptionScreenState extends State<HostedSubscriptionScreen> {
  CustomerInfo? _customerInfo;
  HostedPlanSnapshot? _plan;
  List<Package> _packages = const [];
  String? _error;
  var _busy = false;
  CustomerInfoUpdateListener? _listener;

  bool get _ready => widget.billing != null;

  bool get _isPro =>
      _plan?.isPro == true ||
      _customerInfo?.entitlements.all[HostedConfig.entitlementId]?.isActive ==
          true;

  @override
  void initState() {
    super.initState();
    final billing = widget.billing;
    if (billing == null) return;
    _busy = true;
    _listener = (info) {
      if (!mounted) return;
      setState(() => _customerInfo = info);
      widget.onCustomerInfo?.call(info);
      unawaited(_reloadPlan(info));
    };
    Purchases.addCustomerInfoUpdateListener(_listener!);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_reload());
    });
  }

  @override
  void dispose() {
    final listener = _listener;
    if (listener != null) {
      Purchases.removeCustomerInfoUpdateListener(listener);
    }
    super.dispose();
  }

  Future<void> _reload() async {
    final billing = widget.billing;
    if (billing == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final store = await billing.loadStore();
      if (!mounted) return;
      setState(() {
        _customerInfo = store.$1;
        _packages = store.$2;
      });
      widget.onCustomerInfo?.call(store.$1);
      await _reloadPlan(store.$1);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reloadPlan(CustomerInfo? info) async {
    final billing = widget.billing;
    if (billing == null) return;
    try {
      final plan = await billing.loadPlan(customerInfo: info);
      if (mounted) setState(() => _plan = plan);
    } catch (_) {}
  }

  Future<void> _purchase(Package package) async {
    final billing = widget.billing;
    if (billing == null) return;
    final copy = AccountCopy.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final info = await billing.purchase(package);
      if (!mounted) return;
      setState(() => _customerInfo = info);
      widget.onCustomerInfo?.call(info);
      await _reloadPlan(info);
    } catch (error) {
      if (!mounted || isPurchaseCancelled(error)) return;
      setState(() => _error = copy.purchaseFailed(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    final billing = widget.billing;
    if (billing == null) return;
    final copy = AccountCopy.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final info = await billing.restore();
      if (!mounted) return;
      setState(() => _customerInfo = info);
      widget.onCustomerInfo?.call(info);
      await _reloadPlan(info);
      if (!mounted) return;
      final active =
          info.entitlements.all[HostedConfig.entitlementId]?.isActive == true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(active ? copy.restoreSuccess : copy.restoreEmpty),
        ),
      );
    } catch (error) {
      if (mounted) setState(() => _error = copy.restoreFailed(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _manageSubscription() async {
    final copy = AccountCopy.of(context);
    final fromStore = _customerInfo?.managementURL;
    final uri = (fromStore != null && fromStore.isNotEmpty)
        ? Uri.tryParse(fromStore)
        : null;
    final target =
        uri ??
        (Platform.isIOS
            ? Uri.parse('https://apps.apple.com/account/subscriptions')
            : Uri.parse(
                'https://play.google.com/store/account/subscriptions?package=com.cloud52.cloakly',
              ));
    final opened = await launchUrl(
      target,
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      setState(() => _error = copy.manageFailed);
    }
  }

  Future<void> _openLink(String url) async {
    final copy = AccountCopy.of(context);
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.isScheme('https')) {
      setState(() => _error = copy.linkFailed);
      return;
    }
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      setState(() => _error = copy.linkFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final copy = AccountCopy.of(context);
    final offers = [
      for (final package in _packages)
        SubscriptionOffer(
          title: displayStoreProductTitle(package.storeProduct.title),
          subtitle: packageSubtitle(package, english: copy.english),
          priceLabel: package.storeProduct.priceString,
        ),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(copy.currentPlan),
        actions: [
          IconButton(
            tooltip: copy.refresh,
            onPressed: !_ready || _busy ? null : _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SubscriptionPlanBody(
            copy: copy,
            ready: _ready,
            busy: _busy,
            isPro: _isPro,
            offers: offers,
            plan: _plan,
            storeIsIos: Platform.isIOS,
            error: _error,
            onPurchase: (index) => _purchase(_packages[index]),
            onRestore: _restore,
            onManage: _manageSubscription,
            onOpenLink: _openLink,
          ),
        ],
      ),
    );
  }
}

class SubscriptionPlanBody extends StatelessWidget {
  const SubscriptionPlanBody({
    required this.copy,
    required this.ready,
    required this.busy,
    required this.isPro,
    required this.offers,
    required this.plan,
    required this.storeIsIos,
    this.error,
    this.onPurchase,
    this.onRestore,
    this.onManage,
    this.onOpenLink,
    super.key,
  });

  static const Key progressKey = Key('subscription-progress');

  final AccountCopy copy;
  final bool ready;
  final bool busy;
  final bool isPro;
  final List<SubscriptionOffer> offers;
  final HostedPlanSnapshot? plan;
  final bool storeIsIos;
  final String? error;
  final ValueChanged<int>? onPurchase;
  final VoidCallback? onRestore;
  final VoidCallback? onManage;
  final ValueChanged<String>? onOpenLink;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          key: progressKey,
          height: 4,
          child: busy ? const LinearProgressIndicator() : null,
        ),
        if (plan != null) ...[
          const SizedBox(height: 8),
          _PlanStatusCard(plan: plan!, isPro: isPro, copy: copy),
        ],
        const SizedBox(height: 12),
        if (!ready)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(copy.billingUnavailable),
            ),
          )
        else ...[
          if (isPro)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(copy.proActiveHint),
            )
          else ...[
            Text(copy.freePlanSummary),
            const SizedBox(height: 12),
            for (var i = 0; i < offers.length; i++)
              Card(
                child: ListTile(
                  title: Text(offers[i].title),
                  subtitle: Text(offers[i].subtitle),
                  trailing: FilledButton(
                    onPressed: busy || onPurchase == null
                        ? null
                        : () => onPurchase!(i),
                    child: Text(offers[i].priceLabel),
                  ),
                ),
              ),
            if (!busy && offers.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(copy.noOfferings(storeIsIos)),
              ),
          ],
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: busy ? null : onRestore,
            child: Text(copy.restorePurchases),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: busy ? null : onManage,
            child: Text(copy.manageSubscription),
          ),
        ],
        if (error != null) ...[
          const SizedBox(height: 12),
          Text(error!, style: TextStyle(color: theme.colorScheme.error)),
        ],
        const SizedBox(height: 16),
        Text(copy.autoRenewDisclosure, style: theme.textTheme.bodySmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            TextButton(
              onPressed: onOpenLink == null
                  ? null
                  : () => onOpenLink!(copy.privacyUrl),
              child: Text(copy.privacyLabel),
            ),
            TextButton(
              onPressed: onOpenLink == null
                  ? null
                  : () => onOpenLink!(copy.termsUrl),
              child: Text(copy.termsLabel),
            ),
          ],
        ),
      ],
    );
  }
}

class _PlanStatusCard extends StatelessWidget {
  const _PlanStatusCard({
    required this.plan,
    required this.isPro,
    required this.copy,
  });

  final HostedPlanSnapshot plan;
  final bool isPro;
  final AccountCopy copy;

  @override
  Widget build(BuildContext context) {
    final expires = plan.expiresAt;
    final lines = <String>[
      if (isPro && expires != null) copy.validUntil(expires),
      if (isPro && expires == null) copy.lifetimePro,
      if (!isPro)
        formatRemainingFreeTime(
          plan.remainingFreeSeconds,
          english: copy.english,
        ),
      if (plan.productId != null && plan.productId!.isNotEmpty)
        copy.productLine(plan.productId!),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              copy.planTitle(isPro),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(lines.join('\n')),
            if (!isPro) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: hostedFreeDailyLimitSeconds == 0
                    ? 0
                    : plan.usedFreeSeconds / hostedFreeDailyLimitSeconds,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
