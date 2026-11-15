import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cloakly_core/app.dart';
import 'package:cloakly_core/core/theme/app_theme.dart';
import 'package:cloakly_core/data/models/models.dart';
import 'package:cloakly_core/data/models/project_pack.dart';
import 'package:cloakly_core/features/session/session_controller.dart';
import 'package:cloakly_core/state/project_provider.dart';
import 'package:cloakly_core/state/providers.dart';
import 'package:cloakly_mobile/features/account_copy.dart';
import 'package:cloakly_mobile/features/configuration_error_app.dart';
import 'package:cloakly_mobile/features/hosted_account_screen.dart';
import 'package:cloakly_mobile/features/hosted_subscription_screen.dart';
import 'package:cloakly_mobile/services/hosted_plan.dart';
import 'package:cloakly_mobile/auth/hosted_auth_gate.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Writes docs/screenshots when CLOAKLY_SCREENSHOTS=1.
void main() {
  final enabled = Platform.environment['CLOAKLY_SCREENSHOTS'] == '1';

  testWidgets(
    'capture mobile screens',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 1100));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.runAsync(_loadFonts);

      final root = Directory('../../docs/screenshots');
      await tester.runAsync(() async {
        await Directory('${root.path}/zh-Hant').create(recursive: true);
        await Directory('${root.path}/en').create(recursive: true);
      });

      await _shoot(
        tester,
        'zh-Hant/01-login.png',
        _shell(home: const HostedLoginScreen()),
      );
      await tester.enterText(find.byType(TextField).at(0), 'demo@example.com');
      await tester.enterText(find.byType(TextField).at(1), 'demo-pass');
      await _frames(tester);
      await _save(tester, 'zh-Hant/01-login.png');

      await tester.tap(find.text('沒有帳號？註冊'));
      await _frames(tester);
      await _save(tester, 'zh-Hant/02-sign-up.png');

      await _shoot(
        tester,
        'zh-Hant/03-configuration.png',
        ConfigurationErrorApp(theme: _theme()),
      );
      await _shoot(
        tester,
        'zh-Hant/04-startup-error.png',
        StartupErrorApp(message: '示範：設定檔無法讀取。', theme: _theme()),
      );

      await _shootRoute(tester, 'zh-Hant/05-projects.png', '/');
      await _shootRoute(tester, 'zh-Hant/06-home.png', '/home');
      await _shootRoute(tester, 'zh-Hant/07-meetings.png', '/home/meetings');
      await _shootRoute(tester, 'zh-Hant/08-meeting.png', '/home/meeting/m1');
      await _shootRoute(
        tester,
        'zh-Hant/09-questions.png',
        '/home/project/p1/questions',
      );
      await _shootRoute(tester, 'zh-Hant/10-plan.png', '/home/project/p1/plan');
      await tester.ensureVisible(find.text('看板'));
      await tester.tap(find.text('看板'));
      await _frames(tester);
      await _save(tester, 'zh-Hant/11-plan-board.png');
      await _shootRoute(tester, 'zh-Hant/12-project.png', '/home/project');
      await _shootRoute(
        tester,
        'zh-Hant/13-session.png',
        '/home/session',
        session: _liveSession,
      );

      await _shoot(
        tester,
        'zh-Hant/14-account.png',
        _shell(
          home: HostedAccountScreen(
            accountEmail: 'demo@example.com',
            planLoader: () async => _freePlan,
          ),
        ),
      );
      await _shoot(
        tester,
        'zh-Hant/15-subscription.png',
        _shell(home: _subscriptionPreview(english: false)),
      );
      await _shoot(
        tester,
        'en/14-account.png',
        _shell(
          locale: const Locale('en'),
          home: HostedAccountScreen(
            accountEmail: 'demo@example.com',
            planLoader: () async => _freePlan,
          ),
        ),
      );
      await _shoot(
        tester,
        'en/15-subscription.png',
        _shell(
          locale: const Locale('en'),
          home: _subscriptionPreview(english: true),
        ),
      );
    },
    skip: !enabled,
    timeout: const Timeout(Duration(minutes: 3)),
  );
}

const _freePlan = HostedPlanSnapshot(isPro: false, remainingFreeSeconds: 900);

Future<void> _loadFonts() async {
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

ThemeData _theme() {
  final base = AppTheme.dark();
  return base.copyWith(
    textTheme: base.textTheme.apply(
      fontFamily: 'CloaklyLatin',
      fontFamilyFallback: const ['CloaklyCjk'],
    ),
    primaryTextTheme: base.primaryTextTheme.apply(
      fontFamily: 'CloaklyLatin',
      fontFamilyFallback: const ['CloaklyCjk'],
    ),
  );
}

Widget _shell({
  required Widget home,
  Locale locale = const Locale('zh', 'TW'),
  SessionState? session,
}) {
  return ProviderScope(
    overrides: _overrides(session ?? SessionState.idle()),
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _theme(),
      locale: locale,
      supportedLocales: const [Locale('zh', 'TW'), Locale('en')],
      localizationsDelegates: const [
        _AnyMaterialDelegate(),
        _AnyWidgetsDelegate(),
        _AnyCupertinoDelegate(),
      ],
      home: home,
    ),
  );
}

List<Override> _overrides(SessionState session) => [
  hostedModeProvider.overrideWithValue(true),
  projectsProvider.overrideWith(_DemoProjects.new),
  meetingsProvider.overrideWith(_DemoMeetings.new),
  meetingBundleProvider.overrideWith((ref, id) async => _bundle),
  sessionControllerProvider.overrideWith(() => _FixedSession(session)),
];

Future<void> _shootRoute(
  WidgetTester tester,
  String name,
  String location, {
  SessionState? session,
}) async {
  final router = createAppRouter(
    initialLocation: location,
    settingsBuilder: (_) => HostedAccountScreen(
      accountEmail: 'demo@example.com',
      planLoader: () async => _freePlan,
    ),
  );
  addTearDown(router.dispose);
  await _shoot(
    tester,
    name,
    ProviderScope(
      overrides: _overrides(session ?? SessionState.idle()),
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: _theme(),
        locale: const Locale('zh', 'TW'),
        supportedLocales: const [Locale('zh', 'TW'), Locale('en')],
        localizationsDelegates: const [
          _AnyMaterialDelegate(),
          _AnyWidgetsDelegate(),
          _AnyCupertinoDelegate(),
        ],
        routerConfig: router,
      ),
    ),
  );
}

Future<void> _shoot(WidgetTester tester, String name, Widget widget) async {
  await tester.pumpWidget(
    RepaintBoundary(
      key: const Key('shot'),
      child: KeyedSubtree(key: ValueKey(name), child: widget),
    ),
  );
  await _frames(tester);
  await _save(tester, name);
}

Future<void> _frames(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _save(WidgetTester tester, String name) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const Key('shot')),
  );
  final image = (await tester.runAsync(() => boundary.toImage()))!;
  final bytes = (await tester.runAsync(
    () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
  ))!;
  final png = _encodePng(
    bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
    image.width,
    image.height,
  );
  final file = File('../../docs/screenshots/$name');
  await tester.runAsync(() async {
    await file.parent.create(recursive: true);
    await file.writeAsBytes(png);
  });
}

class _DemoProjects extends ProjectsNotifier {
  @override
  Future<ProjectLibrary> build() async => _library;
}

class _DemoMeetings extends MeetingsNotifier {
  @override
  Future<List<Meeting>> build() async => _meetings;
}

class _FixedSession extends SessionController {
  _FixedSession(this._state);

  final SessionState _state;

  @override
  SessionState build() => _state;
}

final _updated = DateTime(2026, 11, 2, 9);

final _library = ProjectLibrary(
  activeId: 'p1',
  projects: [
    ProjectPack(
      id: 'p1',
      folderPath: '/demo/store-refresh',
      name: '門市改版',
      indexedAt: _updated,
      personalContext: '示範專案，內容皆為虛構。',
      transcriptionTerms: '導覽\n商品卡',
      docs: const [
        KnowledgeDoc(
          relativePath: 'brief.md',
          kind: KnowledgeKind.background,
          byteLength: 2400,
          included: true,
          score: 3,
        ),
      ],
      phases: const [ProjectPhase(id: 'ph1', name: '第一期', sortOrder: 0)],
      activePhaseId: 'ph1',
      tasks: [
        ProjectTask(
          id: 't1',
          phaseId: 'ph1',
          title: '首頁導覽',
          status: ProjectTaskStatus.inProgress,
          progress: 50,
          updatedAt: _updated,
          startDate: DateTime(2026, 11, 3),
          endDate: DateTime(2026, 11, 14),
          owner: '林可恩',
        ),
        ProjectTask(
          id: 't2',
          phaseId: 'ph1',
          title: '結帳流程',
          status: ProjectTaskStatus.planned,
          updatedAt: _updated,
          startDate: DateTime(2026, 11, 10),
          endDate: DateTime(2026, 11, 21),
          owner: '陳書宇',
        ),
      ],
    ),
  ],
);

final _meetings = [
  Meeting(
    id: 'm1',
    projectId: 'p1',
    title: '週會：首頁範圍',
    startedAt: DateTime(2026, 11, 2, 10),
    endedAt: DateTime(2026, 11, 2, 10, 42),
    status: MeetingStatus.completed,
    minutesMarkdown: '## 決定\n\n首頁先做導覽與商品卡。\n\n## 待辦\n\n- 林可恩下週出示稿。',
  ),
  Meeting(
    id: 'm2',
    projectId: 'p1',
    title: '設計檢討',
    startedAt: DateTime(2026, 10, 27, 15),
    endedAt: DateTime(2026, 10, 27, 15, 30),
    status: MeetingStatus.completed,
  ),
];

final _bundle = MeetingBundle(
  meeting: _meetings.first,
  lines: const [
    TranscriptLine(
      id: 'l1',
      meetingId: 'm1',
      speaker: '林可恩',
      speakerIndex: 0,
      text: '我們先把首頁導覽定下來。',
      isFinal: true,
      startMs: 4000,
      endMs: 9000,
    ),
    TranscriptLine(
      id: 'l2',
      meetingId: 'm1',
      speaker: '陳書宇',
      speakerIndex: 1,
      text: '結帳流程下週再對。',
      isFinal: true,
      startMs: 12000,
      endMs: 17000,
    ),
  ],
  notes: [
    Note(
      id: 'n1',
      meetingId: 'm1',
      text: '商品卡先用兩欄。',
      createdAt: DateTime(2026, 11, 2, 10, 12),
    ),
  ],
  suggestions: [
    Suggestion(
      id: 's1',
      meetingId: 'm1',
      triggerText: '首頁導覽',
      answer: '可先確認導覽只放三個入口。',
      createdAt: DateTime(2026, 11, 2, 10, 8),
    ),
  ],
);

final _liveSession = SessionState(
  phase: SessionPhase.live,
  meetingId: 'm-live',
  title: '週會：首頁範圍',
  lines: _bundle.lines,
  notes: _bundle.notes,
  suggestions: _bundle.suggestions,
  elapsed: const Duration(minutes: 12, seconds: 40),
  isDemo: false,
  partialText: null,
  error: null,
  busyHint: false,
  systemAudioOn: false,
  projectName: '門市改版',
  startedAt: DateTime(2026, 11, 2, 10),
);

Widget _subscriptionPreview({required bool english}) {
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
          plan: _freePlan,
          offers: [
            SubscriptionOffer(
              title: english ? 'Cloakly Pro Monthly' : 'Cloakly Pro 月繳',
              subtitle: english ? 'Monthly' : '月繳',
              priceLabel: r'US$19.99',
            ),
            SubscriptionOffer(
              title: english ? 'Cloakly Pro Yearly' : 'Cloakly Pro 年繳',
              subtitle: english ? 'Yearly' : '年繳',
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

Uint8List _encodePng(Uint8List rgba, int width, int height) {
  final raw = BytesBuilder(copy: false);
  final stride = width * 4;
  for (var y = 0; y < height; y++) {
    raw.addByte(0);
    raw.add(rgba.sublist(y * stride, (y + 1) * stride));
  }
  final compressed = ZLibEncoder(level: 9).convert(raw.takeBytes());
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
