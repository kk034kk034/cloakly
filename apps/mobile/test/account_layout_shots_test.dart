import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cloakly_core/core/theme/app_theme.dart';
import 'package:cloakly_core/features/settings/theme_mode_setting.dart';
import 'package:cloakly_mobile/features/account_copy.dart';
import 'package:cloakly_mobile/features/hosted_account_screen.dart';
import 'package:cloakly_mobile/features/hosted_subscription_screen.dart';
import 'package:cloakly_mobile/services/hosted_plan.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Widget renders of the account layout. Not a device or store screenshot.
/// Run with CLOAKLY_SCREENSHOTS=1.
void main() {
  final enabled = Platform.environment['CLOAKLY_SCREENSHOTS'] == '1';

  testWidgets(
    'writes before and after account layout shots',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.runAsync(_loadShotFont);

      await _shoot(
        tester,
        'before-loading',
        _frame(const _LegacyAccountPreview(loaded: false)),
      );
      await _shoot(
        tester,
        'before-loaded',
        _frame(const _LegacyAccountPreview(loaded: true)),
      );
      await _shoot(
        tester,
        'after-loading',
        _frame(
          HostedAccountScreen(
            key: const Key('after-loading'),
            accountEmail: 'member@example.com',
            planLoader: () => Completer<HostedPlanSnapshot?>().future,
          ),
        ),
      );
      await _shoot(
        tester,
        'after-loaded',
        _frame(
          HostedAccountScreen(
            key: const Key('after-loaded'),
            accountEmail: 'member@example.com',
            planLoader: () async => const HostedPlanSnapshot(
              isPro: false,
              remainingFreeSeconds: 1800,
            ),
          ),
        ),
      );
      await _shoot(
        tester,
        'after-error',
        _frame(
          HostedAccountScreen(
            key: const Key('after-error'),
            accountEmail: 'member@example.com',
            planLoader: () async => throw StateError('offline'),
          ),
        ),
      );
      await _shoot(
        tester,
        'after-plan-zh',
        _frame(const Scaffold(body: _PlanPreview(english: false))),
      );
      await _shoot(
        tester,
        'after-plan-en',
        _frame(
          const Scaffold(body: _PlanPreview(english: true)),
          locale: const Locale('en'),
        ),
      );
    },
    skip: !enabled,
    timeout: const Timeout(Duration(seconds: 60)),
  );
}

Future<void> _loadShotFont() async {
  Future<void> load(String family, String path) async {
    final bytes = await File(path).readAsBytes();
    final loader = FontLoader(family)
      ..addFont(Future.value(ByteData.sublistView(bytes)));
    await loader.load();
  }

  await load(
    'CloaklyLatin',
    '/usr/share/fonts/truetype/macos/Inter-Regular.ttf',
  );
  await load(
    'CloaklyCjk',
    '/usr/share/fonts/truetype/droid/DroidSansFallbackFull.ttf',
  );
}

Widget _frame(Widget child, {Locale locale = const Locale('zh', 'TW')}) {
  final base = AppTheme.dark();
  return ProviderScope(
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        textTheme: base.textTheme.apply(
          fontFamily: 'CloaklyLatin',
          fontFamilyFallback: const ['CloaklyCjk'],
        ),
        primaryTextTheme: base.primaryTextTheme.apply(
          fontFamily: 'CloaklyLatin',
          fontFamilyFallback: const ['CloaklyCjk'],
        ),
      ),
      locale: locale,
      supportedLocales: const [Locale('zh', 'TW'), Locale('en')],
      localizationsDelegates: const [
        _AnyMaterialDelegate(),
        _AnyWidgetsDelegate(),
        _AnyCupertinoDelegate(),
      ],
      home: RepaintBoundary(key: const Key('shot'), child: child),
    ),
  );
}

class _AnyMaterialDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const _AnyMaterialDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<MaterialLocalizations> load(Locale locale) {
    return DefaultMaterialLocalizations.load(locale);
  }

  @override
  bool shouldReload(
    covariant LocalizationsDelegate<MaterialLocalizations> old,
  ) {
    return false;
  }
}

class _AnyCupertinoDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const _AnyCupertinoDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<CupertinoLocalizations> load(Locale locale) {
    return DefaultCupertinoLocalizations.load(locale);
  }

  @override
  bool shouldReload(
    covariant LocalizationsDelegate<CupertinoLocalizations> old,
  ) {
    return false;
  }
}

class _AnyWidgetsDelegate extends LocalizationsDelegate<WidgetsLocalizations> {
  const _AnyWidgetsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<WidgetsLocalizations> load(Locale locale) {
    return DefaultWidgetsLocalizations.load(locale);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<WidgetsLocalizations> old) {
    return false;
  }
}

Uint8List _encodePng(Uint8List rgba, int width, int height) {
  final raw = BytesBuilder(copy: false);
  final stride = width * 4;
  for (var y = 0; y < height; y++) {
    raw.addByte(0);
    raw.add(rgba.sublist(y * stride, (y + 1) * stride));
  }
  final compressed = ZLibEncoder(level: 1).convert(raw.takeBytes());
  final out = BytesBuilder();
  out.add(const [137, 80, 78, 71, 13, 10, 26, 10]);

  void chunk(String type, List<int> data) {
    final typeBytes = ascii.encode(type);
    final length = ByteData(4)..setUint32(0, data.length);
    out.add(length.buffer.asUint8List());
    out.add(typeBytes);
    out.add(data);
    final crc = ByteData(4)..setUint32(0, _crc32([...typeBytes, ...data]));
    out.add(crc.buffer.asUint8List());
  }

  final header = ByteData(13)
    ..setUint32(0, width)
    ..setUint32(4, height)
    ..setUint8(8, 8)
    ..setUint8(9, 6);
  chunk('IHDR', header.buffer.asUint8List());
  chunk('IDAT', compressed);
  chunk('IEND', const []);
  return out.takeBytes();
}

int _crc32(List<int> data) {
  var crc = 0xFFFFFFFF;
  for (final byte in data) {
    crc ^= byte;
    for (var bit = 0; bit < 8; bit++) {
      if ((crc & 1) != 0) {
        crc = (crc >> 1) ^ 0xEDB88320;
      } else {
        crc >>= 1;
      }
    }
  }
  return (crc ^ 0xFFFFFFFF) & 0xFFFFFFFF;
}

Future<void> _shoot(WidgetTester tester, String name, Widget widget) async {
  await tester.pumpWidget(widget);
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const Key('shot')),
  );
  final image = (await tester.runAsync(() => boundary.toImage()))!;
  final bytes = (await tester.runAsync(
    () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
  ))!;
  final data = _encodePng(
    bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
    image.width,
    image.height,
  );
  await tester.runAsync(() async {
    for (final directory in const [
      '/tmp/cloakly-account-shots',
      '/opt/cursor/artifacts',
    ]) {
      final file = File('$directory/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(data);
    }
  });
}

class _LegacyAccountPreview extends StatelessWidget {
  const _LegacyAccountPreview({required this.loaded});

  final bool loaded;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('帳號與訂閱'),
        actions: const [IconButton(onPressed: null, icon: Icon(Icons.refresh))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(child: Icon(Icons.person_outline)),
            title: Text('member@example.com'),
            subtitle: Text(
              '免費方案：會議每天合計 30 分鐘；專案問答 5 次、計畫建議 5 次。同一支手機每天只能使用一個帳號的免費額度。',
            ),
          ),
          const SizedBox(height: 8),
          const ThemeModeSetting(),
          if (loaded) ...[
            const SizedBox(height: 8),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('目前方案：免費'),
                    SizedBox(height: 6),
                    Text('今日免費額度剩餘 30 分鐘'),
                    SizedBox(height: 12),
                    LinearProgressIndicator(value: 0),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (!loaded)
            const SizedBox(
              height: 4,
              child: ColoredBox(color: Color(0xFF14685C)),
            ),
          if (loaded) ...[
            Card(
              child: ListTile(
                title: const Text('Cloakly Pro 月繳'),
                subtitle: const Text('月繳 · 每月續訂'),
                trailing: FilledButton(
                  onPressed: () {},
                  child: const Text(r'US$19.99'),
                ),
              ),
            ),
            Card(
              child: ListTile(
                title: const Text('Cloakly Pro 年繳'),
                subtitle: const Text('年繳 · 每年續訂'),
                trailing: FilledButton(
                  onPressed: () {},
                  child: const Text(r'US$199.99'),
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          OutlinedButton(onPressed: () {}, child: const Text('恢復購買')),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: () {}, child: const Text('管理商店訂閱')),
          const SizedBox(height: 24),
          const Divider(),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.logout),
            title: Text('登出'),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.delete_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              '刪除帳號',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanPreview extends StatelessWidget {
  const _PlanPreview({required this.english});

  final bool english;

  @override
  Widget build(BuildContext context) {
    final copy = english ? const AccountCopy.en() : const AccountCopy.zh();
    return Scaffold(
      appBar: AppBar(title: Text(copy.currentPlan)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SubscriptionPlanBody(
            copy: copy,
            ready: true,
            busy: false,
            isPro: false,
            storeIsIos: true,
            plan: const HostedPlanSnapshot(
              isPro: false,
              remainingFreeSeconds: 1800,
            ),
            offers: [
              SubscriptionOffer(
                title: english ? 'Cloakly Pro Monthly' : 'Cloakly Pro 月繳',
                subtitle: english
                    ? 'Monthly · Renews every month'
                    : '月繳 · 每月續訂',
                priceLabel: r'US$19.99',
              ),
              SubscriptionOffer(
                title: english ? 'Cloakly Pro Yearly' : 'Cloakly Pro 年繳',
                subtitle: english ? 'Yearly · Renews every year' : '年繳 · 每年續訂',
                priceLabel: r'US$199.99',
              ),
            ],
            onPurchase: (_) {},
            onRestore: () {},
            onManage: () {},
            onOpenLink: (_) {},
          ),
        ],
      ),
    );
  }
}
