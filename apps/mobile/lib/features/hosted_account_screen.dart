import 'dart:async';

import 'package:cloakly_mobile/config/hosted_config.dart';
import 'package:cloakly_mobile/services/hosted_billing.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HostedAccountScreen extends StatefulWidget {
  const HostedAccountScreen({this.billing, super.key});

  final HostedBilling? billing;

  @override
  State<HostedAccountScreen> createState() => _HostedAccountScreenState();
}

class _HostedAccountScreenState extends State<HostedAccountScreen> {
  CustomerInfo? _customerInfo;
  HostedPlanSnapshot? _plan;
  List<Package> _packages = const [];
  String? _error;
  var _busy = false;
  CustomerInfoUpdateListener? _listener;

  bool get _ready => widget.billing != null;

  @override
  void initState() {
    super.initState();
    if (_ready) {
      _listener = (info) {
        if (!mounted) return;
        setState(() => _customerInfo = info);
        unawaited(_reloadPlan(info));
      };
      Purchases.addCustomerInfoUpdateListener(_listener!);
    }
    _reload();
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
    if (billing == null) {
      await _reloadPlan(null);
      return;
    }
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
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final info = await billing.purchase(package);
      if (!mounted) return;
      setState(() => _customerInfo = info);
      await _reloadPlan(info);
    } catch (error) {
      if (!mounted || isPurchaseCancelled(error)) return;
      setState(() => _error = '購買未完成：$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    final billing = widget.billing;
    if (billing == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final info = await billing.restore();
      if (!mounted) return;
      setState(() => _customerInfo = info);
      await _reloadPlan(info);
    } catch (error) {
      if (mounted) setState(() => _error = '無法恢復購買：$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signOut() async {
    await widget.billing?.signOut();
    await Supabase.instance.client.auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final email =
        Supabase.instance.client.auth.currentUser?.email ?? '未提供 Email';
    final plan = _plan;
    final isPro =
        plan?.isPro == true ||
        _customerInfo?.entitlements.all[HostedConfig.entitlementId]?.isActive ==
            true;
    return Scaffold(
      appBar: AppBar(
        title: const Text('帳號與訂閱'),
        actions: [
          IconButton(
            tooltip: '重新整理',
            onPressed: _busy ? null : _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(child: Icon(Icons.person_outline)),
            title: Text(email),
            subtitle: Text(
              isPro ? 'Pro 訂閱有效' : '免費方案：每日合計 30 分鐘，可分多場使用',
            ),
          ),
          if (plan != null) ...[
            const SizedBox(height: 8),
            _PlanStatusCard(plan: plan, isPro: isPro),
          ],
          const SizedBox(height: 12),
          if (!_ready)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('尚未設定 RevenueCat 公開 SDK key，因此目前不能顯示或購買訂閱。'),
              ),
            )
          else ...[
            if (_busy) const LinearProgressIndicator(),
            if (isPro)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('目前已有有效 Pro 權益。若換機，可按下方「恢復購買」。'),
              )
            else ...[
              for (final package in _packages)
                Card(
                  child: ListTile(
                    title: Text(package.storeProduct.title),
                    subtitle: Text(
                      '${packagePeriodLabel(package)} · ${package.storeProduct.description}',
                    ),
                    trailing: FilledButton(
                      onPressed: _busy ? null : () => _purchase(package),
                      child: Text(package.storeProduct.priceString),
                    ),
                  ),
                ),
              if (!_busy && _packages.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'RevenueCat 尚未回傳 Offering，請確認商店商品與 Current Offering 設定。',
                  ),
                ),
            ],
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _busy ? null : _restore,
              child: const Text('恢復購買'),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 28),
          TextButton.icon(
            onPressed: _busy ? null : _signOut,
            icon: const Icon(Icons.logout),
            label: const Text('登出'),
          ),
        ],
      ),
    );
  }
}

class _PlanStatusCard extends StatelessWidget {
  const _PlanStatusCard({required this.plan, required this.isPro});

  final HostedPlanSnapshot plan;
  final bool isPro;

  @override
  Widget build(BuildContext context) {
    final expires = plan.expiresAt;
    final lines = <String>[
      if (isPro && expires != null)
        '有效至 ${DateFormat('yyyy/MM/dd HH:mm').format(expires.toLocal())}',
      if (isPro && expires == null) '永久 Pro 權益',
      if (!isPro) formatRemainingFreeTime(plan.remainingFreeSeconds),
      if (plan.productId != null && plan.productId!.isNotEmpty)
        '商品：${plan.productId}',
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isPro ? '目前方案：Pro' : '目前方案：免費',
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
