import 'package:cloakly/data/db/app_database.dart';
import 'package:cloakly/data/models/models.dart';
import 'package:cloakly/data/repositories/meeting_repository.dart';
import 'package:cloakly/data/repositories/settings_repository.dart';
import 'package:cloakly/state/project_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

AppSettings? bootSettings;

final databaseProvider = Provider<AppDatabase>((ref) {
  throw StateError('databaseProvider 必須在 main 裡 override');
});

final meetingRepositoryProvider = Provider<MeetingRepository>((ref) {
  return MeetingRepository(ref.watch(databaseProvider));
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository();
});

final settingsProvider =
    NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

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

final meetingsProvider =
    AsyncNotifierProvider<MeetingsNotifier, List<Meeting>>(MeetingsNotifier.new);

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

final meetingBundleProvider =
    FutureProvider.family<MeetingBundle, String>((ref, id) {
  return ref.watch(meetingRepositoryProvider).loadBundle(id);
});
