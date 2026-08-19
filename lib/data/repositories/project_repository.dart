import 'dart:convert';

import 'package:cloakly/data/models/project_pack.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProjectLoadResult {
  const ProjectLoadResult({
    required this.library,
    this.migratedProjectId,
  });

  final ProjectLibrary library;
  final String? migratedProjectId;
}

class ProjectRepository {
  static const _legacyKey = 'cloakly.projectPack';
  static const _listKey = 'cloakly.projects';
  static const _activeKey = 'cloakly.activeProjectId';

  Future<ProjectLoadResult> loadLibrary() async {
    final prefs = await SharedPreferences.getInstance();
    String? migratedProjectId;
    var projects = _decodeList(prefs.getString(_listKey));

    if (projects.isEmpty) {
      final legacy = prefs.getString(_legacyKey);
      if (legacy != null && legacy.isNotEmpty) {
        final pack = ProjectPack.fromJson(
          jsonDecode(legacy) as Map<String, dynamic>,
        );
        projects = [pack];
        await prefs.setString(_listKey, jsonEncode([pack.toJson()]));
        await prefs.setString(_activeKey, pack.id);
        await prefs.remove(_legacyKey);
        migratedProjectId = pack.id;
      }
    }

    final rawActive = prefs.getString(_activeKey);
    final activeId =
        rawActive == null || rawActive == ProjectLibrary.unassignedId
            ? null
            : rawActive;

    return ProjectLoadResult(
      library: ProjectLibrary(
        projects: projects,
        activeId: activeId,
      ),
      migratedProjectId: migratedProjectId,
    );
  }

  Future<void> saveLibrary(ProjectLibrary library) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _listKey,
      jsonEncode(library.projects.map((project) => project.toJson()).toList()),
    );
    final activeId = library.active?.id;
    if (activeId == null || activeId.isEmpty) {
      await prefs.remove(_activeKey);
    } else {
      await prefs.setString(_activeKey, activeId);
    }
  }

  List<ProjectPack> _decodeList(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return [
      for (final item in decoded)
        ProjectPack.fromJson(Map<String, dynamic>.from(item as Map)),
    ];
  }
}
