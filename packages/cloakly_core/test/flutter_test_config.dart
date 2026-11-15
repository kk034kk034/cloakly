import 'package:cloakly_core/l10n/cloakly_locale.dart';
import 'package:flutter_test/flutter_test.dart';

/// Existing tests assert Traditional Chinese. Bind that locale before they run.
/// An English widget test rebinds `en` and restores this in its tear-down.
Future<void> testExecutable(Future<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  CloaklyLocale.bind(cloaklyZhHant);
  await testMain();
}
