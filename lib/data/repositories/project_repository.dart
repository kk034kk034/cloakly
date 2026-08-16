import 'dart:convert';

import 'package:cloakly/data/models/project_pack.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProjectRepository {
  static const _key = 'cloakly.projectPack';

  Future<ProjectPack?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return null;
    return ProjectPack.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> save(ProjectPack? pack) async {
    final prefs = await SharedPreferences.getInstance();
    if (pack == null) {
      await prefs.remove(_key);
      return;
    }
    await prefs.setString(_key, jsonEncode(pack.toJson()));
  }
}
