import 'dart:async';
import 'dart:io';

import 'package:cloakly_core/features/settings/theme_mode_setting.dart';
import 'package:cloakly_mobile/config/hosted_config.dart';
import 'package:cloakly_mobile/services/hosted_billing.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

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
      if (!mounted) return;
      final active =
          info.entitlements.all[HostedConfig.entitlementId]?.isActive == true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(active ? '已恢復 Pro 購買。' : '沒有找到可恢復的 Pro 購買。'),
        ),
      );
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

  Future<void> _manageSubscription() async {
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
      setState(
        () => _error = '無法開啟商店訂閱頁。請到 Google Play 或 App Store 的「付款與訂閱」取消。',
      );
    }
  }

  Future<void> _deleteAccount() async {
    final email = Supabase.instance.client.auth.currentUser?.email?.trim();
    if (email == null || email.isEmpty) {
      setState(() => _error = '此帳號沒有 Email，無法在這裡刪除。');
      return;
    }

    final password = TextEditingController();
    var acknowledged = false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final canDelete = acknowledged && password.text.isNotEmpty;
            return AlertDialog(
              title: const Text('刪除帳號'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '刪除後無法復原。雲端帳號與訂閱權益紀錄會刪除。'
                      '同一個 Email 今天已使用的免費時間會保留到今天結束，重新註冊會接著計算。'
                      '這台手機上的會議、逐字稿與專案會留在裝置裡。',
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Google Play 或 App Store 的訂閱要另外到商店取消。'
                      '刪除 Cloakly 帳號後，商店仍可能在下一期續扣，也不會自動退款。',
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: acknowledged,
                      onChanged: (value) {
                        setDialogState(() => acknowledged = value ?? false);
                      },
                      title: const Text('我了解必須另外到商店取消訂閱'),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    TextField(
                      controller: password,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: '輸入密碼以確認'),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: canDelete
                      ? () => Navigator.pop(dialogContext, true)
                      : null,
                  child: Text(
                    '刪除帳號',
                    style: TextStyle(
                      color: canDelete
                          ? Theme.of(dialogContext).colorScheme.error
                          : null,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
    final passwordText = password.text;
    password.dispose();
    if (confirmed != true || !mounted) return;

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: passwordText,
      );
      await Supabase.instance.client.functions.invoke(
        'delete-account',
        body: {'confirmEmail': email},
      );
      await widget.billing?.signOut();
      try {
        await Supabase.instance.client.auth.signOut();
      } catch (_) {}
      try {
        await Supabase.instance.client.auth.signOut(scope: SignOutScope.local);
      } catch (_) {}
    } on AuthException {
      if (mounted) setState(() => _error = '密碼不正確，帳號尚未刪除。');
    } on FunctionException catch (error) {
      if (mounted) setState(() => _error = _deleteAccountError(error));
    } catch (error) {
      if (mounted) setState(() => _error = '無法刪除帳號：$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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
              isPro
                  ? 'Pro 訂閱有效'
                  : '免費方案：會議每天合計 30 分鐘；專案問答 5 次、計畫建議 5 次。同一支手機每天只能使用一個帳號的免費額度。',
            ),
          ),
          const SizedBox(height: 8),
          const ThemeModeSetting(),
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
                    title: Text(
                      displayStoreProductTitle(package.storeProduct.title),
                    ),
                    subtitle: Text(_packageSubtitle(package)),
                    trailing: FilledButton(
                      onPressed: _busy ? null : () => _purchase(package),
                      child: Text(package.storeProduct.priceString),
                    ),
                  ),
                ),
              if (!_busy && _packages.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    '還沒有可購買的方案。請到 RevenueCat 的 Current Offering，'
                    '加入 ${Platform.isIOS ? 'App Store' : 'Google Play'} 商品。',
                  ),
                ),
            ],
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _busy ? null : _restore,
              child: const Text('恢復購買'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _busy ? null : _manageSubscription,
              child: const Text('管理商店訂閱'),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 24),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.logout),
            title: const Text('登出'),
            onTap: _busy ? null : _signOut,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.delete_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              '刪除帳號',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: _busy ? null : _deleteAccount,
          ),
        ],
      ),
    );
  }
}

String _deleteAccountError(FunctionException error) {
  final details = error.details;
  final code = details is Map ? details['error']?.toString() : null;
  return switch (code) {
    'CONFIRMATION_MISMATCH' => '確認資料不一致，帳號尚未刪除。',
    'AUTH_REQUIRED' || 'INVALID_ACCESS_TOKEN' => '登入已失效，請重新登入後再刪除。',
    'ACCOUNT_DELETE_FAILED' => '刪除尚未完成，請再試一次。帳號可能還在。',
    _ =>
      error.status == 404
          ? '後端尚未部署刪除帳號，帳號尚未刪除。'
          : '無法刪除帳號（${error.status}）。帳號尚未刪除。',
  };
}

String _packageSubtitle(Package package) {
  final period = packagePeriodLabel(package);
  final description = package.storeProduct.description.trim();
  if (description.isEmpty) return period;
  return '$period · $description';
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
