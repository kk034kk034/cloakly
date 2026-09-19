import 'package:cloakly_mobile/config/hosted_config.dart';
import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HostedAccountScreen extends StatefulWidget {
  const HostedAccountScreen({required this.revenueCatReady, super.key});

  final bool revenueCatReady;

  @override
  State<HostedAccountScreen> createState() => _HostedAccountScreenState();
}

class _HostedAccountScreenState extends State<HostedAccountScreen> {
  CustomerInfo? _customerInfo;
  List<Package> _packages = const [];
  String? _error;
  var _busy = false;

  bool get _isPro =>
      _customerInfo?.entitlements.all[HostedConfig.entitlementId]?.isActive ==
      true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    if (!widget.revenueCatReady) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final values = await Future.wait<Object>([
        Purchases.getCustomerInfo(),
        Purchases.getOfferings(),
      ]);
      final info = values[0] as CustomerInfo;
      final offerings = values[1] as Offerings;
      if (!mounted) return;
      setState(() {
        _customerInfo = info;
        _packages = offerings.current?.availablePackages ?? const [];
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _purchase(Package package) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await Purchases.purchase(PurchaseParams.package(package));
      await _refreshServerEntitlement();
      if (!mounted) return;
      setState(() => _customerInfo = result.customerInfo);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final info = await Purchases.restorePurchases();
      await _refreshServerEntitlement();
      if (mounted) setState(() => _customerInfo = info);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _refreshServerEntitlement() async {
    try {
      await Supabase.instance.client.functions.invoke('sync-entitlement');
    } catch (_) {
      // The signed RevenueCat webhook will reconcile the entitlement later.
    }
  }

  Future<void> _signOut() async {
    if (widget.revenueCatReady) {
      try {
        await Purchases.logOut();
      } catch (_) {}
    }
    await Supabase.instance.client.auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final email =
        Supabase.instance.client.auth.currentUser?.email ?? '未提供 Email';
    return Scaffold(
      appBar: AppBar(title: const Text('帳號與訂閱')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(child: Icon(Icons.person_outline)),
            title: Text(email),
            subtitle: Text(_isPro ? 'Pro 訂閱有效' : '免費方案：每日合計 30 分鐘，可分多場使用'),
          ),
          const SizedBox(height: 12),
          if (!widget.revenueCatReady)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('尚未設定 RevenueCat 公開 SDK key，因此目前不能顯示或購買訂閱。'),
              ),
            )
          else ...[
            if (_busy) const LinearProgressIndicator(),
            for (final package in _packages)
              Card(
                child: ListTile(
                  title: Text(package.storeProduct.title),
                  subtitle: Text(package.storeProduct.description),
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
