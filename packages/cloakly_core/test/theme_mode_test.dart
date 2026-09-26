import 'package:cloakly_core/core/theme/app_theme.dart';
import 'package:cloakly_core/core/theme/theme_controller.dart';
import 'package:cloakly_core/features/settings/theme_mode_setting.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('未設定時維持深色，儲存後可讀回淺色', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await loadThemeMode(), ThemeMode.dark);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(themeModePreferenceKey, ThemeMode.light.name);
    expect(await loadThemeMode(), ThemeMode.light);

    await prefs.setString(themeModePreferenceKey, 'nope');
    expect(await loadThemeMode(), ThemeMode.dark);
  });

  testWidgets('外觀切換會立刻套用並記住', (tester) async {
    SharedPreferences.setMockInitialValues({});
    bootThemeMode = ThemeMode.dark;
    addTearDown(() => bootThemeMode = ThemeMode.dark);

    await tester.pumpWidget(const ProviderScope(child: _Harness()));
    await tester.pumpAndSettle();

    expect(
      Theme.of(tester.element(find.text('外觀'))).brightness,
      Brightness.dark,
    );

    await tester.tap(find.text('淺色'));
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.text('外觀'))).brightness,
      Brightness.light,
    );

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(themeModePreferenceKey), 'light');

    await tester.tap(find.text('深色'));
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.text('外觀'))).brightness,
      Brightness.dark,
    );
    expect(prefs.getString(themeModePreferenceKey), 'dark');
  });
}

class _Harness extends ConsumerWidget {
  const _Harness();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(themeModeProvider),
      home: const Scaffold(body: ThemeModeSetting()),
    );
  }
}
