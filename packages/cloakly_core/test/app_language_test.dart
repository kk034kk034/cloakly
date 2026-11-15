import 'package:cloakly_core/core/constants.dart';
import 'package:cloakly_core/features/settings/language_setting.dart';
import 'package:cloakly_core/l10n/app_language.dart';
import 'package:cloakly_core/l10n/app_localizations.dart';
import 'package:cloakly_core/l10n/cloakly_locale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    bootAppLanguage = AppLanguageChoice.system;
    CloaklyLocale.bind(cloaklyZhHant);
  });

  test('未設定或無法辨識時跟隨系統，儲存後可讀回', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await loadAppLanguage(), AppLanguageChoice.system);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(appLanguagePreferenceKey, 'zh_Hant');
    expect(await loadAppLanguage(), AppLanguageChoice.zhHant);

    await prefs.setString(appLanguagePreferenceKey, 'en');
    expect(await loadAppLanguage(), AppLanguageChoice.en);

    await prefs.setString(appLanguagePreferenceKey, 'nope');
    expect(await loadAppLanguage(), AppLanguageChoice.system);
    expect(appLanguageFromStored(null), AppLanguageChoice.system);
  });

  test('跟隨系統沿用 zh* → 繁中、其餘英文；指定語言蓋過裝置', () {
    expect(
      resolveAppLanguage(AppLanguageChoice.system, const Locale('zh', 'TW')),
      cloaklyZhHant,
    );
    expect(
      resolveAppLanguage(AppLanguageChoice.system, const Locale('zh', 'CN')),
      cloaklyZhHant,
    );
    expect(
      resolveAppLanguage(
        AppLanguageChoice.system,
        const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
      ),
      cloaklyZhHant,
    );
    expect(
      resolveAppLanguage(AppLanguageChoice.system, const Locale('en', 'US')),
      cloaklyEn,
    );
    expect(
      resolveAppLanguage(AppLanguageChoice.system, const Locale('ja')),
      cloaklyEn,
    );
    expect(resolveAppLanguage(AppLanguageChoice.system, null), cloaklyEn);

    expect(
      resolveAppLanguage(AppLanguageChoice.zhHant, const Locale('en', 'US')),
      cloaklyZhHant,
    );
    expect(
      resolveAppLanguage(AppLanguageChoice.en, const Locale('zh', 'TW')),
      cloaklyEn,
    );
    expect(localeOverrideFor(AppLanguageChoice.system), isNull);
  });

  test('AI 輸出語言跟著生效中的 app locale', () {
    CloaklyLocale.bind(cloaklyEn);
    expect(llmOutputLanguageRule(), contains('English'));
    CloaklyLocale.bind(cloaklyZhHant);
    expect(llmOutputLanguageRule(), contains('繁體中文'));
  });

  testWidgets('選擇語言會立刻套用並記住', (tester) async {
    SharedPreferences.setMockInitialValues({});
    bootAppLanguage = AppLanguageChoice.system;
    tester.platformDispatcher.localesTestValue = const [Locale('zh', 'TW')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    await tester.pumpWidget(const ProviderScope(child: _Harness()));
    await tester.pumpAndSettle();

    expect(find.text('語言'), findsOneWidget);
    expect(find.text('跟隨系統'), findsOneWidget);
    expect(CloaklyLocale.current, cloaklyZhHant);
    expect(llmOutputLanguageRule(), contains('繁體中文'));

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Follow system'), findsOneWidget);
    expect(CloaklyLocale.current, cloaklyEn);
    expect(llmOutputLanguageRule(), contains('English'));

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(appLanguagePreferenceKey), 'en');

    await tester.tap(find.text('繁體中文'));
    await tester.pumpAndSettle();
    expect(find.text('語言'), findsOneWidget);
    expect(CloaklyLocale.current, cloaklyZhHant);
    expect(prefs.getString(appLanguagePreferenceKey), 'zh_Hant');

    await tester.tap(find.text('跟隨系統'));
    await tester.pumpAndSettle();
    expect(find.text('語言'), findsOneWidget);
    expect(CloaklyLocale.current, cloaklyZhHant);
    expect(prefs.getString(appLanguagePreferenceKey), 'system');
    expect(tester.takeException(), isNull);
  });

  testWidgets('手機寬度下語言列維持單行', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(390, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const ProviderScope(child: _Harness()));
    await tester.pumpAndSettle();

    expect(
      tester.getSize(find.byType(SegmentedButton<AppLanguageChoice>)).height,
      LanguageSetting.controlHeight,
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byType(SegmentedButton<AppLanguageChoice>)).height,
      LanguageSetting.controlHeight,
    );
    expect(tester.takeException(), isNull);
  });
}

class _Harness extends ConsumerWidget {
  const _Harness();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      locale: localeOverrideFor(ref.watch(appLanguageProvider)),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      localeResolutionCallback: resolveCloaklyLocale,
      builder: cloaklyLocaleBuilder,
      home: const Scaffold(
        body: Padding(padding: EdgeInsets.all(16), child: LanguageSetting()),
      ),
    );
  }
}
