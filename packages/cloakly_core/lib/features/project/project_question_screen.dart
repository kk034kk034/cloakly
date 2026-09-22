import 'package:cloakly_core/data/models/project_pack.dart';
import 'package:cloakly_core/state/project_provider.dart';
import 'package:cloakly_core/widgets/project_question_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProjectQuestionScreen extends ConsumerWidget {
  const ProjectQuestionScreen({super.key, required this.projectId});
  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final library = ref.watch(projectsProvider);
    ProjectPack? pack;
    for (final item in library.valueOrNull?.projects ?? <ProjectPack>[]) {
      if (item.id == projectId) pack = item;
    }
    if (pack == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('專案問答')),
        body: Center(
          child: Text(library.isLoading ? '載入專案中…' : '找不到此專案，請回到專案列表。'),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text('${pack.name} · 專案問答')),
      body: SafeArea(child: ProjectQuestionPanel(project: pack)),
    );
  }
}
