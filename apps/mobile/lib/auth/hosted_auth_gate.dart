import 'dart:async';

import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HostedAuthGate extends StatefulWidget {
  const HostedAuthGate({
    required this.child,
    required this.revenueCatReady,
    super.key,
  });

  final Widget child;
  final bool revenueCatReady;

  @override
  State<HostedAuthGate> createState() => _HostedAuthGateState();
}

class _HostedAuthGateState extends State<HostedAuthGate> {
  late Session? _session;
  StreamSubscription<AuthState>? _subscription;

  @override
  void initState() {
    super.initState();
    final auth = Supabase.instance.client.auth;
    _session = auth.currentSession;
    _subscription = auth.onAuthStateChange.listen((event) {
      final previous = _session;
      if (mounted) setState(() => _session = event.session);
      unawaited(_syncRevenueCat(previous, event.session));
    });
    unawaited(_syncRevenueCat(null, _session));
  }

  Future<void> _syncRevenueCat(Session? previous, Session? current) async {
    if (!widget.revenueCatReady) return;
    try {
      if (current != null) {
        await Purchases.logIn(current.user.id);
        await _refreshServerEntitlement();
      } else if (previous != null) {
        await Purchases.logOut();
      }
    } catch (_) {
      // Authentication must remain usable if the store SDK is unavailable.
    }
  }

  Future<void> _refreshServerEntitlement() async {
    try {
      await Supabase.instance.client.functions.invoke('sync-entitlement');
    } catch (_) {
      // RevenueCat's webhook is the fallback when an immediate sync is offline.
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
    return const _AuthApp();
  }
}

class _AuthApp extends StatelessWidget {
  const _AuthApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const _EmailPasswordScreen(),
    );
  }
}

class _EmailPasswordScreen extends StatefulWidget {
  const _EmailPasswordScreen();

  @override
  State<_EmailPasswordScreen> createState() => _EmailPasswordScreenState();
}

class _EmailPasswordScreenState extends State<_EmailPasswordScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  var _signUp = false;
  var _busy = false;
  String? _message;

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
        if (result.session == null && mounted) {
          setState(() => _message = '註冊完成，請到信箱確認後再登入。');
        }
      } else {
        await Supabase.instance.client.auth.signInWithPassword(
          email: email,
          password: password,
        );
      }
    } on AuthException catch (error) {
      if (mounted) setState(() => _message = error.message);
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
                    obscureText: true,
                    autofillHints: const [AutofillHints.password],
                    decoration: const InputDecoration(labelText: '密碼'),
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
