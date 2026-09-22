import 'dart:io';

import 'package:cloakly_core/data/models/project_pack.dart';
import 'package:cloakly_core/data/repositories/project_repository.dart';
import 'package:cloakly_core/services/project/project_context_builder.dart';
import 'package:cloakly_core/services/project/project_indexer.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  return ProjectRepository();
});

final projectsProvider =
    AsyncNotifierProvider<ProjectsNotifier, ProjectLibrary>(
      ProjectsNotifier.new,
    );

class ProjectsNotifier extends AsyncNotifier<ProjectLibrary> {
  final _indexer = ProjectIndexer();
  final _contextBuilder = ProjectContextBuilder();
  final _uuid = const Uuid();

  @override
  Future<ProjectLibrary> build() async {
    final result = await ref.read(projectRepositoryProvider).loadLibrary();
    return result.library;
  }

  ProjectPack? get active => state.valueOrNull?.active;

  Future<void> select(String? id) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final next = ProjectLibrary(projects: current.projects, activeId: id);
    await ref.read(projectRepositoryProvider).saveLibrary(next);
    state = AsyncData(next);
  }

  Future<void> addFolder() async {
    final path = await FilePicker.platform.getDirectoryPath(
      dialogTitle: '新增專案資料夾',
    );
    if (path == null) return;
    await indexFolder(path);
  }

  Future<void> indexFolder(String folderPath) async {
    final current = state.valueOrNull ?? const ProjectLibrary();
    state = const AsyncLoading();
    try {
      ProjectPack? previous;
      for (final project in current.projects) {
        if (p.equals(project.folderPath, folderPath)) {
          previous = project;
          break;
        }
      }
      final id = previous?.id ?? _uuid.v4();
      var pack = await _indexer.index(folderPath, id: id);
      if (previous != null) {
        pack = pack.copyWith(
          personalContext: previous.personalContext,
          transcriptionTerms: previous.transcriptionTerms,
          tasks: previous.tasks,
          phases: previous.phases,
          activePhaseId: previous.activePhaseId,
        );
      }
      final projects = [
        for (final project in current.projects)
          if (project.id == id) pack else project,
        if (previous == null) pack,
      ];
      final next = ProjectLibrary(projects: projects, activeId: id);
      await ref.read(projectRepositoryProvider).saveLibrary(next);
      state = AsyncData(next);
    } catch (error, stack) {
      state = AsyncError(error, stack);
    }
  }

  Future<void> reindex([String? projectId]) async {
    final pack = _byId(projectId);
    if (pack == null) return;
    await indexFolder(pack.folderPath);
  }

  Future<void> updateDetails(String id, String background, String terms) async {
    final pack = _byId(id);
    if (pack == null) throw StateError('專案已不存在');
    await _replace(
      pack.copyWith(personalContext: background, transcriptionTerms: terms),
    );
  }

  Future<void> updateTasks(String id, List<ProjectTask> tasks) async {
    final pack = _byId(id);
    if (pack == null) throw StateError('專案已不存在');
    await _replace(pack.copyWith(tasks: tasks).withNormalizedPhases());
  }

  Future<void> updatePlan(
    String id, {
    List<ProjectTask>? tasks,
    List<ProjectPhase>? phases,
    String? activePhaseId,
    bool clearActivePhaseId = false,
  }) async {
    final pack = _byId(id);
    if (pack == null) throw StateError('專案已不存在');
    await _replace(
      pack
          .copyWith(
            tasks: tasks,
            phases: phases,
            activePhaseId: activePhaseId,
            clearActivePhaseId: clearActivePhaseId,
          )
          .withNormalizedPhases(),
    );
  }

  Future<void> remove(String id) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final projects = [
      for (final project in current.projects)
        if (project.id != id) project,
    ];
    final next = ProjectLibrary(
      projects: projects,
      activeId: current.activeId == id ? null : current.activeId,
    );
    await ref.read(projectRepositoryProvider).saveLibrary(next);
    state = AsyncData(next);
  }

  Future<String> contextBlock({
    String? projectId,
    String? personalContext,
  }) async {
    final pack = _byId(projectId);
    if (pack == null) return '（尚未選定專案資料夾）';
    final background = (personalContext ?? pack.personalContext).trim();
    if (!Directory(pack.folderPath).existsSync()) {
      return [
        '專案：${pack.name}',
        if (background.isNotEmpty) '角色與背景：$background',
        '（專案資料夾已不存在）',
      ].join('\n');
    }
    return _contextBuilder.build(pack, personalContext: background);
  }

  Future<void> _replace(ProjectPack pack) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final next = ProjectLibrary(
      projects: [
        for (final project in current.projects)
          if (project.id == pack.id) pack else project,
      ],
      activeId: current.activeId,
    );
    await ref.read(projectRepositoryProvider).saveLibrary(next);
    state = AsyncData(next);
  }

  ProjectPack? _byId(String? id) {
    if (id == null) return null;
    final projects = state.valueOrNull?.projects ?? const [];
    for (final project in projects) {
      if (project.id == id) return project;
    }
    return null;
  }
}
