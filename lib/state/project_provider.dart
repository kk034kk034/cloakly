import 'dart:io';

import 'package:cloakly/data/models/project_pack.dart';
import 'package:cloakly/data/repositories/project_repository.dart';
import 'package:cloakly/services/project/project_context_builder.dart';
import 'package:cloakly/services/project/project_indexer.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  return ProjectRepository();
});

final projectProvider =
    AsyncNotifierProvider<ProjectNotifier, ProjectPack?>(ProjectNotifier.new);

class ProjectNotifier extends AsyncNotifier<ProjectPack?> {
  final _indexer = ProjectIndexer();
  final _contextBuilder = ProjectContextBuilder();

  @override
  Future<ProjectPack?> build() {
    return ref.read(projectRepositoryProvider).load();
  }

  Future<void> pickFolder() async {
    final path = await FilePicker.platform.getDirectoryPath(
      dialogTitle: '選定會議要用的專案資料夾',
    );
    if (path == null) return;
    await indexFolder(path);
  }

  Future<void> indexFolder(String folderPath) async {
    final previous = state.valueOrNull;
    state = const AsyncLoading();
    try {
      var pack = await _indexer.index(folderPath);
      if (previous != null &&
          p.equals(previous.folderPath, folderPath) &&
          previous.docs.isNotEmpty) {
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
      await ref.read(projectRepositoryProvider).save(pack);
      state = AsyncData(pack);
    } catch (error, stack) {
      state = AsyncError(error, stack);
    }
  }

  Future<void> reindex() async {
    final current = state.valueOrNull;
    if (current == null) return;
    await indexFolder(current.folderPath);
  }

  Future<void> toggle(String relativePath, bool included) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final next = current.copyWith(
      docs: [
        for (final doc in current.docs)
          if (doc.relativePath == relativePath)
            doc.copyWith(included: included)
          else
            doc,
      ],
    );
    await ref.read(projectRepositoryProvider).save(next);
    state = AsyncData(next);
  }

  Future<void> clear() async {
    await ref.read(projectRepositoryProvider).save(null);
    state = const AsyncData(null);
  }

  Future<String> contextBlock() async {
    final current = state.valueOrNull;
    if (current == null) return '（尚未選定專案資料夾）';
    if (!Directory(current.folderPath).existsSync()) {
      return '（專案資料夾已不存在：${current.folderPath}）';
    }
    return _contextBuilder.build(current);
  }
}
