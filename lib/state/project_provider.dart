import 'dart:io';

import 'package:cloakly/data/models/project_pack.dart';
import 'package:cloakly/data/repositories/project_repository.dart';
import 'package:cloakly/services/project/project_context_builder.dart';
import 'package:cloakly/services/project/project_indexer.dart';
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
      if (previous != null && previous.docs.isNotEmpty) {
        final previousIncluded = {
          for (final doc in previous.docs)
            if (doc.included) doc.relativePath,
        };
        pack = pack.copyWith(
          docs: [
            for (final doc in pack.docs)
              doc.copyWith(
                included: previousIncluded.contains(doc.relativePath) ||
                    (previousIncluded.isEmpty && doc.included),
              ),
          ],
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
    final pack = _byId(projectId) ?? active;
    if (pack == null) return;
    await indexFolder(pack.folderPath);
  }

  Future<void> toggle(String relativePath, bool included, {String? projectId}) async {
    final current = state.valueOrNull;
    final pack = _byId(projectId) ?? current?.active;
    if (current == null || pack == null) return;
    final updated = pack.copyWith(
      docs: [
        for (final doc in pack.docs)
          if (doc.relativePath == relativePath)
            doc.copyWith(included: included)
          else
            doc,
      ],
    );
    await _replace(updated);
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

  Future<String> contextBlock({String? projectId}) async {
    final pack = _byId(projectId) ?? active;
    if (pack == null) return '（尚未選定專案資料夾）';
    if (!Directory(pack.folderPath).existsSync()) {
      return '（專案資料夾已不存在：${pack.folderPath}）';
    }
    return _contextBuilder.build(pack);
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
