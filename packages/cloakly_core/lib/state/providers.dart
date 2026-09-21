import 'package:cloakly_core/data/db/app_database.dart';
import 'package:cloakly_core/data/models/models.dart';
import 'package:cloakly_core/data/repositories/meeting_repository.dart';
import 'package:cloakly_core/data/repositories/settings_repository.dart';
import 'package:cloakly_core/services/llm/llm_service.dart';
import 'package:cloakly_core/services/project/project_retrieval.dart';
import 'package:cloakly_core/services/stt/stt_engine.dart';
import 'package:cloakly_core/services/stt/stt_factory.dart';
import 'package:cloakly_core/state/project_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

AppSettings? bootSettings;

typedef AiServiceFactory = AiService Function(AppSettings settings);
typedef SttEngineFactory =
    SttEngine Function(
      AppSettings settings, {
      required SttLane lane,
      int Function()? elapsedMs,
    });

final hostedModeProvider = Provider<bool>((ref) => false);

final aiServiceFactoryProvider = Provider<AiServiceFactory>(
  (ref) => DirectAiService.new,
);
typedef SessionUsageReporter =
    Future<void> Function({required int durationSeconds});

final sttEngineFactoryProvider = Provider<SttEngineFactory>(
  (ref) => createSttEngine,
);

final sessionUsageReporterProvider = Provider<SessionUsageReporter?>(
  (ref) => null,
);

final databaseProvider = Provider<AppDatabase>((ref) {
  throw StateError('databaseProvider 必須在 main 裡 override');
});

final meetingRepositoryProvider = Provider<MeetingRepository>((ref) {
  return MeetingRepository(ref.watch(databaseProvider));
});

final projectRetrievalProvider = Provider<ProjectRetrieval>((ref) {
  return ProjectRetrieval(ref.watch(meetingRepositoryProvider));
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository();
});

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

final aiServiceProvider = Provider<AiService>((ref) {
  final factory = ref.watch(aiServiceFactoryProvider);
  return factory(ref.watch(settingsProvider));
});

final sttAvailableProvider = Provider<bool>((ref) {
  return ref.watch(hostedModeProvider) ||
      ref.watch(settingsProvider.select((settings) => settings.hasLiveDiarize));
});

final demoModeProvider = Provider<bool>((ref) {
  return !ref.watch(sttAvailableProvider) &&
      !ref.watch(aiServiceProvider).isConfigured;
});

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() => bootSettings ?? AppSettings.defaults();

  Future<void> hydrate(AppSettings settings) async {
    state = settings;
  }

  Future<void> update(AppSettings settings) async {
    await ref.read(settingsRepositoryProvider).save(settings);
    state = settings;
  }
}

final meetingsProvider = AsyncNotifierProvider<MeetingsNotifier, List<Meeting>>(
  MeetingsNotifier.new,
);

class MeetingsNotifier extends AsyncNotifier<List<Meeting>> {
  @override
  Future<List<Meeting>> build() async {
    final repo = ref.read(meetingRepositoryProvider);
    await repo.purgeOrphanAudio();
    final library = await ref.watch(projectsProvider.future);
    if (!library.hasSelection) {
      return repo.list(unassignedOnly: true);
    }
    return repo.list(projectId: library.active!.id);
  }

  Future<void> refresh() async {
    final repo = ref.read(meetingRepositoryProvider);
    await repo.purgeOrphanAudio();
    final library = ref.read(projectsProvider).valueOrNull;
    if (library == null || !library.hasSelection) {
      state = AsyncData(await repo.list(unassignedOnly: true));
      return;
    }
    state = AsyncData(await repo.list(projectId: library.active!.id));
  }

  Future<void> remove(String id) async {
    await ref.read(meetingRepositoryProvider).deleteMeeting(id);
    await refresh();
  }
}

final meetingBundleProvider = FutureProvider.family<MeetingBundle, String>((
  ref,
  id,
) {
  return ref.watch(meetingRepositoryProvider).loadBundle(id);
});
