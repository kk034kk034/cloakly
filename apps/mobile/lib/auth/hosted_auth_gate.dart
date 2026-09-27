import 'dart:async';

import 'package:cloakly_core/core/theme/app_theme.dart';
import 'package:cloakly_core/core/theme/theme_controller.dart';
import 'package:cloakly_core/features/settings/theme_mode_setting.dart';
import 'package:cloakly_mobile/services/hosted_access.dart';
import 'package:cloakly_mobile/services/hosted_billing.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HostedAuthGate extends StatefulWidget {
  const HostedAuthGate({required this.child, this.billing, super.key});

  final Widget child;
  final HostedBilling? billing;

  @override
  State<HostedAuthGate> createState() => _HostedAuthGateState();
}

class _HostedAuthGateState extends State<HostedAuthGate> {
  late Session? _session;
  StreamSubscription<AuthState>? _subscription;
  String? _notice;
  var _clearingUnconfirmed = false;

  @override
  void initState() {
    super.initState();
    final auth = Supabase.instance.client.auth;
    _session = _accepted(auth.currentSession);
    _subscription = auth.onAuthStateChange.listen((event) {
      final previous = _session;
      final next = _accepted(event.session);
      if (mounted) setState(() => _session = next);
      unawaited(_syncRevenueCat(previous, next));
    });
    unawaited(_syncRevenueCat(null, _session));
  }

  Session? _accepted(Session? session) {
    if (session == null) return null;
    if (hostedEmailConfirmed(session.user)) return session;
    _notice = unconfirmedEmailMessage;
    if (_clearingUnconfirmed) return null;
    _clearingUnconfirmed = true;
    unawaited(() async {
      try {
        await widget.billing?.signOut();
      } catch (_) {}
      try {
        await Supabase.instance.client.auth.signOut();
      } finally {
        _clearingUnconfirmed = false;
      }
    }());
    return null;
  }

  Future<void> _syncRevenueCat(Session? previous, Session? current) async {
    final billing = widget.billing;
    if (billing == null) return;
    try {
      if (current != null) {
        if (previous != null && previous.user.id != current.user.id) {
          await billing.signOut();
        }
        await billing.identify(
          userId: current.user.id,
          email: current.user.email,
        );
      } else if (previous != null) {
        await billing.signOut();
      }
    } catch (_) {
      // Authentication must remain usable if the store SDK is unavailable.
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_session != null) return widget.child;
    return _AuthApp(notice: _notice);
  }
}

class _AuthApp extends StatelessWidget {
  const _AuthApp({this.notice});

  final String? notice;

  @override
  Widget build(BuildContext context) {
    return ThemeModeBuilder(
      builder: (context, mode) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: mode,
        home: _EmailPasswordScreen(notice: notice),
      ),
    );
  }
}

class _EmailPasswordScreen extends StatefulWidget {
  const _EmailPasswordScreen({this.notice});

  final String? notice;

  @override
  State<_EmailPasswordScreen> createState() => _EmailPasswordScreenState();
}

class _EmailPasswordScreenState extends State<_EmailPasswordScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  var _signUp = false;
  var _busy = false;
  var _showPassword = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _message = widget.notice;
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty || password.length < 8) {
      setState(() => _message = '請輸入 Email，密碼至少 8 個字元。');
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      if (_signUp) {
        final result = await Supabase.instance.client.auth.signUp(
          email: email,
          password: password,
        );
        final user = result.user;
        if (user != null &&
            result.session != null &&
            hostedEmailConfirmed(user)) {
          return;
        }
        if (result.session != null) {
          await Supabase.instance.client.auth.signOut();
        }
        if (mounted) setState(() => _message = unconfirmedEmailMessage);
      } else {
        final result = await Supabase.instance.client.auth.signInWithPassword(
          email: email,
          password: password,
        );
        final user = result.user;
        if (user != null && !hostedEmailConfirmed(user)) {
          await Supabase.instance.client.auth.signOut();
          if (mounted) setState(() => _message = unconfirmedEmailMessage);
        }
      }
    } on AuthException catch (error) {
      if (mounted) {
        setState(() => _message = hostedAuthErrorMessage(error.message));
      }
    } catch (error) {
      if (mounted) setState(() => _message = '無法連線：$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Align(
                    alignment: Alignment.centerRight,
                    child: ThemeModeToggleButton(),
                  ),
                  const Icon(Icons.graphic_eq, size: 58),
                  const SizedBox(height: 18),
                  Text(
                    _signUp ? '建立 Cloakly 帳號' : '登入 Cloakly',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _password,
                    obscureText: !_showPassword,
                    autofillHints: const [AutofillHints.password],
                    decoration: InputDecoration(
                      labelText: '密碼',
                      suffixIcon: IconButton(
                        tooltip: _showPassword ? '隱藏密碼' : '顯示密碼',
                        onPressed: () =>
                            setState(() => _showPassword = !_showPassword),
                        icon: Icon(
                          _showPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                      ),
                    ),
                    onSubmitted: (_) => _busy ? null : _submit(),
                  ),
                  if (_message != null) ...[
                    const SizedBox(height: 12),
                    Text(_message!, textAlign: TextAlign.center),
                  ],
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: Text(_busy ? '處理中…' : (_signUp ? '註冊' : '登入')),
                  ),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() {
                            _signUp = !_signUp;
                            _showPassword = false;
                            _message = null;
                          }),
                    child: Text(_signUp ? '已有帳號？登入' : '沒有帳號？註冊'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
