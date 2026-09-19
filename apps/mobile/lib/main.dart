import 'package:cloakly_core/bootstrap.dart';
import 'package:cloakly_mobile/auth/hosted_auth_gate.dart';
import 'package:cloakly_mobile/config/hosted_config.dart';
import 'package:cloakly_mobile/features/configuration_error_app.dart';
import 'package:cloakly_mobile/features/hosted_account_screen.dart';
import 'package:cloakly_mobile/services/hosted_ai_service.dart';
import 'package:cloakly_mobile/services/hosted_stt_factory.dart';
import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!HostedConfig.hasSupabase) {
    runApp(const ConfigurationErrorApp());
    return;
  }

  await Supabase.initialize(
    url: HostedConfig.supabaseUrl,
    publishableKey: HostedConfig.supabasePublishableKey,
  );

  var revenueCatReady = false;
  final revenueCatKey = HostedConfig.revenueCatApiKey;
  if (revenueCatKey.isNotEmpty) {
    await Purchases.configure(PurchasesConfiguration(revenueCatKey));
    revenueCatReady = true;
  }

  final supabase = Supabase.instance.client;
  final usageCoordinator = HostedSessionCoordinator(supabase);
  await runCloaklyApp(
    hostedMode: true,
    aiServiceFactory: (_) => HostedAiService(supabase),
    sttEngineFactory: createHostedSttEngineFactory(
      supabase,
      usage: usageCoordinator,
    ),
    sessionUsageReporter: usageCoordinator.finish,
    appShellBuilder: (child) =>
        HostedAuthGate(revenueCatReady: revenueCatReady, child: child),
    settingsBuilder: (_) =>
        HostedAccountScreen(revenueCatReady: revenueCatReady),
  );
}
