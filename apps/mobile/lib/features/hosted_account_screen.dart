import 'dart:async';

import 'package:cloakly_core/features/settings/language_setting.dart';
import 'package:cloakly_core/features/settings/theme_mode_setting.dart';
import 'package:cloakly_mobile/config/hosted_config.dart';
import 'package:cloakly_mobile/features/account_copy.dart';
import 'package:cloakly_mobile/features/current_plan_row.dart';
import 'package:cloakly_mobile/features/hosted_subscription_screen.dart';
import 'package:cloakly_mobile/services/hosted_billing.dart';
import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

typedef HostedPlanLoader = Future<HostedPlanSnapshot?> Function();

class HostedAccountScreen extends StatefulWidget {
  const HostedAccountScreen({
    this.billing,
    this.accountEmail,
    this.planLoader,
    super.key,
  });

  final HostedBilling? billing;

  /// When set, the screen does not read Supabase for the email line.
  final String? accountEmail;

  /// When set, replaces the store and entitlement fetch. Production leaves this null.
  final HostedPlanLoader? planLoader;

  @override
  State<HostedAccountScreen> createState() => _HostedAccountScreenState();
}

class _HostedAccountScreenState extends State<HostedAccountScreen> {
  CustomerInfo? _customerInfo;
  HostedPlanSnapshot? _plan;
  PlanRowPhase _phase = PlanRowPhase.loading;
  var _deleting = false;
  CustomerInfoUpdateListener? _listener;

  bool get _isPro =>
      _plan?.isPro == true ||
      _customerInfo?.entitlements.all[HostedConfig.entitlementId]?.isActive ==
          true;

  @override
  void initState() {
    super.initState();
    final willLoad = widget.planLoader != null || widget.billing != null;
    _phase = willLoad ? PlanRowPhase.loading : PlanRowPhase.unavailable;
    if (widget.planLoader == null && widget.billing != null) {
      _listener = (info) {
        if (!mounted) return;
        setState(() => _customerInfo = info);
        unawaited(_reloadPlan(info));
      };
      Purchases.addCustomerInfoUpdateListener(_listener!);
    }
    if (willLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_reload());
      });
    }
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
    final loader = widget.planLoader;
    if (loader != null) {
      await _load(loader);
      return;
    }
    final billing = widget.billing;
    if (billing == null) {
      if (mounted) setState(() => _phase = PlanRowPhase.unavailable);
      return;
    }
    await _load(() async {
      CustomerInfo? info = _customerInfo;
      try {
        info = await billing.loadCustomerInfo();
        if (mounted) setState(() => _customerInfo = info);
      } catch (_) {}
      return billing.loadPlan(customerInfo: info);
    });
  }

  Future<void> _load(HostedPlanLoader loader) async {
    final showSkeleton = _phase != PlanRowPhase.ready;
    if (showSkeleton && _phase != PlanRowPhase.loading && mounted) {
      setState(() => _phase = PlanRowPhase.loading);
    }
    try {
      final plan = await loader();
      if (!mounted) return;
      setState(() {
        _plan = plan;
        _phase = PlanRowPhase.ready;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (_phase != PlanRowPhase.ready) _phase = PlanRowPhase.failed;
      });
    }
  }

  Future<void> _reloadPlan(CustomerInfo? info) async {
    final billing = widget.billing;
    if (billing == null || widget.planLoader != null) return;
    try {
      final plan = await billing.loadPlan(customerInfo: info);
      if (!mounted) return;
      setState(() {
        _plan = plan;
        if (_phase != PlanRowPhase.loading) _phase = PlanRowPhase.ready;
      });
    } catch (_) {}
  }

  Future<void> _openPlan() async {
    final navigator = Navigator.of(context);
    await navigator.push(
      MaterialPageRoute<void>(
        builder: (context) => HostedSubscriptionScreen(
          billing: widget.billing,
          onCustomerInfo: (info) {
            if (!mounted) return;
            setState(() => _customerInfo = info);
            unawaited(_reloadPlan(info));
          },
        ),
      ),
    );
    if (mounted) unawaited(_reload());
  }

  Future<void> _signOut() async {
    await widget.billing?.signOut();
    await Supabase.instance.client.auth.signOut();
  }

  void _report(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _deleteAccount() async {
    final copy = AccountCopy.of(context);
    final email = Supabase.instance.client.auth.currentUser?.email?.trim();
    if (email == null || email.isEmpty) {
      _report(copy.deleteNeedsEmail);
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
              title: Text(copy.deleteAccount),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(copy.deleteIntro),
                    const SizedBox(height: 12),
                    Text(copy.deleteStoreWarning),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: acknowledged,
                      onChanged: (value) {
                        setDialogState(() => acknowledged = value ?? false);
                      },
                      title: Text(copy.deleteAcknowledge),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    TextField(
                      controller: password,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: copy.deletePasswordLabel,
                      ),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: Text(copy.cancel),
                ),
                TextButton(
                  onPressed: canDelete
                      ? () => Navigator.pop(dialogContext, true)
                      : null,
                  child: Text(
                    copy.deleteAccount,
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

    setState(() => _deleting = true);
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
      _report(copy.wrongPassword);
    } on FunctionException catch (error) {
      _report(deleteAccountErrorMessage(error, copy));
    } catch (error) {
      _report(copy.deleteFailed(error));
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  String _email(AccountCopy copy) {
    final override = widget.accountEmail?.trim();
    if (override != null && override.isNotEmpty) return override;
    final current = Supabase.instance.client.auth.currentUser?.email?.trim();
    if (current != null && current.isNotEmpty) return current;
    return copy.emailMissing;
  }

  @override
  Widget build(BuildContext context) {
    final copy = AccountCopy.of(context);
    final failed = _phase == PlanRowPhase.failed;
    return Scaffold(
      appBar: AppBar(
        title: Text(copy.accountTitle),
        actions: [
          IconButton(
            tooltip: copy.refresh,
            onPressed: _deleting ? null : _reload,
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
            title: Text(_email(copy)),
          ),
          const SizedBox(height: 8),
          const ThemeModeSetting(),
          const SizedBox(height: 16),
          const LanguageSetting(),
          const SizedBox(height: 8),
          CurrentPlanRow(
            title: copy.currentPlan,
            status: copy.rowStatus(phase: _phase, isPro: _isPro, plan: _plan),
            loading: _phase == PlanRowPhase.loading,
            statusColor: failed ? Theme.of(context).colorScheme.error : null,
            onTap: _openPlan,
          ),
          const SizedBox(height: 24),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.logout),
            title: Text(copy.signOut),
            onTap: _deleting ? null : _signOut,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.delete_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              copy.deleteAccount,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: _deleting ? null : _deleteAccount,
          ),
        ],
      ),
    );
  }
}

String deleteAccountErrorMessage(FunctionException error, AccountCopy copy) {
  final details = error.details;
  final code = details is Map ? details['error']?.toString() : null;
  return switch (code) {
    'CONFIRMATION_MISMATCH' => copy.deleteConfirmationMismatch,
    'AUTH_REQUIRED' || 'INVALID_ACCESS_TOKEN' => copy.deleteAuthExpired,
    'ACCOUNT_DELETE_FAILED' => copy.deleteIncomplete,
    _ =>
      error.status == 404
          ? copy.deleteNotDeployed
          : copy.deleteFailedStatus(error.status),
  };
}
