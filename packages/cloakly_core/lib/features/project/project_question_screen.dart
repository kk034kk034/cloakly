import 'package:cloakly_core/data/models/project_pack.dart';
import 'package:cloakly_core/l10n/cloakly_locale.dart';
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
    final l10n = context.l10n;
    ProjectPack? pack;
    for (final item in library.valueOrNull?.projects ?? <ProjectPack>[]) {
      if (item.id == projectId) pack = item;
    }
    if (pack == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.projectQa)),
        body: Center(
          child: Text(
            library.isLoading ? l10n.loadingProject : l10n.projectMissingBack,
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(l10n.projectQaTitle(pack.name))),
      body: SafeArea(child: ProjectQuestionPanel(project: pack)),
    );
  }
}
