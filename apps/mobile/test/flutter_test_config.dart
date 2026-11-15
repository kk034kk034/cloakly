import 'package:cloakly_core/l10n/cloakly_locale.dart';
import 'package:flutter_test/flutter_test.dart';

/// Unit tests that call hosted copy without a widget still expect zh-Hant.
Future<void> testExecutable(Future<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  CloaklyLocale.bind(cloaklyZhHant);
  await testMain();
}
