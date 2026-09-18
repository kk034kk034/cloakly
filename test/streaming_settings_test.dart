import 'package:cloakly/data/repositories/settings_repository.dart';
import 'package:cloakly/features/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'legacy settings migrate without losing keys; new STT settings persist',
    () async {
      SharedPreferences.setMockInitialValues({
        'cloakly.openaiApiKey': 'old-test-key',
        'cloakly.language': 'zh',
      });
      final repository = SettingsRepository();
      final old = await repository.load();
      expect(old.sonioxApiKey, isEmpty);
      expect(old.openaiApiKey, 'old-test-key');
      await repository.save(
        old.copyWith(
          sonioxApiKey: 'new-test-key',
          language: 'zh-en',
          transcriptionTerms: '博士班\nTransformer',
        ),
      );
      final saved = await repository.load();
      expect(saved.openaiApiKey, 'old-test-key');
      expect(saved.sonioxApiKey, 'new-test-key');
      expect(saved.language, 'zh-en');
      expect(saved.transcriptionTerms, '博士班\nTransformer');
    },
  );

  testWidgets(
    'streaming settings fit a narrow screen and keep secrets obscured',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: SettingsScreen())),
      );
      expect(find.text('Soniox API 金鑰'), findsOneWidget);
      final fields = tester
          .widgetList<TextField>(find.byType(TextField))
          .toList();
      expect(fields.first.obscureText, isTrue);
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
