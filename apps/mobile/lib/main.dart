import 'package:cloakly_core/bootstrap.dart';
import 'package:cloakly_mobile/auth/hosted_auth_gate.dart';
import 'package:cloakly_mobile/config/hosted_config.dart';
import 'package:cloakly_mobile/features/configuration_error_app.dart';
import 'package:cloakly_mobile/features/hosted_account_screen.dart';
import 'package:cloakly_mobile/services/hosted_ai_service.dart';
import 'package:cloakly_mobile/services/hosted_billing.dart';
import 'package:cloakly_mobile/services/hosted_stt_factory.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exceptionAsString()}');
  };

  try {
    await _start();
  } catch (error, stack) {
    debugPrint('Startup failed: $error\n$stack');
    runApp(StartupErrorApp(message: error.toString()));
  }
}

Future<void> _start() async {
  if (!HostedConfig.hasSupabase) {
    runApp(const ConfigurationErrorApp());
    return;
  }

  await Supabase.initialize(
    url: HostedConfig.supabaseUrl,
    publishableKey: HostedConfig.supabasePublishableKey,
  );

  final supabase = Supabase.instance.client;
  final billing = await HostedBilling.configure(
    supabase: supabase,
    appUserId: supabase.auth.currentUser?.id,
  );
  final usageCoordinator = HostedSessionCoordinator(supabase);
  await runCloaklyApp(
    hostedMode: true,
    aiServiceFactory: (_) => HostedAiService(supabase),
    sttEngineFactory: createHostedSttEngineFactory(
      supabase,
      usage: usageCoordinator,
    ),
    sessionUsageReporter: usageCoordinator.finish,
    appShellBuilder: (child) => HostedAuthGate(billing: billing, child: child),
    settingsBuilder: (_) => HostedAccountScreen(billing: billing),
  );
}
