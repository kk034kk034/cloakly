import 'package:cloakly_core/data/models/project_pack.dart';
import 'package:cloakly_core/l10n/cloakly_locale.dart';
import 'package:cloakly_core/state/project_provider.dart';
import 'package:cloakly_core/state/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 專案內設定：資料來源說明、會議背景／詞彙，以及刪除專案。
class ProjectScreen extends ConsumerWidget {
  const ProjectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final library = ref.watch(projectsProvider).valueOrNull;
    final pack = library?.active;
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.projectSettings)),
      body: pack == null
          ? Center(child: Text(l10n.unassignedProjectSettings))
          : _ProjectSettingsBody(pack: pack),
    );
  }
}

class _ProjectSettingsBody extends ConsumerWidget {
  const _ProjectSettingsBody({required this.pack});

  final ProjectPack pack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Text(
          l10n.projectSources,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.folder_outlined),
            title: Text(pack.folderPath),
            subtitle: Text(l10n.projectSourcesHelp),
          ),
        ),
        const SizedBox(height: 24),
        _ProjectDetailsSection(key: ValueKey(pack.id), pack: pack),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () => _confirmDeleteProject(context, ref, pack),
          icon: Icon(
            Icons.delete_outline,
            color: Theme.of(context).colorScheme.error,
          ),
          label: Text(
            l10n.deleteThisProject,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ],
    );
  }
}

class _ProjectDetailsSection extends ConsumerStatefulWidget {
  const _ProjectDetailsSection({super.key, required this.pack});
  final ProjectPack pack;

  @override
  ConsumerState<_ProjectDetailsSection> createState() =>
      _ProjectDetailsSectionState();
}

class _ProjectDetailsSectionState
    extends ConsumerState<_ProjectDetailsSection> {
  late final _background = TextEditingController(
    text: widget.pack.personalContext,
  );
  late final _terms = TextEditingController(
    text: widget.pack.transcriptionTerms,
  );
  bool _saving = false;

  @override
  void dispose() {
    _background.dispose();
    _terms.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.meetingPromptTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _background,
          minLines: 2,
          maxLines: 6,
          decoration: InputDecoration(
            labelText: context.l10n.roleField,
            hintText: context.l10n.roleFieldHint,
            helperText: context.l10n.roleFieldHelp,
            helperMaxLines: 2,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _terms,
          minLines: 2,
          maxLines: 5,
          decoration: InputDecoration(
            labelText: context.l10n.vocabField,
            hintText: context.l10n.vocabFieldHint,
            helperText: context.l10n.vocabFieldHelp,
            helperMaxLines: 2,
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? context.l10n.saving : context.l10n.save),
        ),
      ],
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(projectsProvider.notifier)
          .updateDetails(
            widget.pack.id,
            _background.text.trim(),
            _terms.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.projectSettingsSaved)),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.saveFailed('$error'))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

Future<void> _confirmDeleteProject(
  BuildContext context,
  WidgetRef ref,
  ProjectPack pack,
) async {
  final count =
      (await ref.read(meetingRepositoryProvider).list(projectId: pack.id))
          .length;
  if (!context.mounted) return;
  var savedAudio = count == 0;
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          final l10n = context.l10n;
          return AlertDialog(
            title: Text(l10n.deleteProjectTitle(pack.name)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count == 0
                      ? l10n.deleteProjectEmpty
                      : l10n.deleteProjectWithMeetings(count),
                ),
                if (count > 0) ...[
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: savedAudio,
                    onChanged: (value) =>
                        setState(() => savedAudio = value ?? false),
                    title: Text(l10n.deleteProjectAck),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
                onPressed: savedAudio
                    ? () => Navigator.pop(context, true)
                    : null,
                child: Text(l10n.deleteProject),
              ),
            ],
          );
        },
      );
    },
  );
  if (ok != true) return;
  await ref.read(meetingRepositoryProvider).deleteByProject(pack.id);
  await ref.read(projectsProvider.notifier).remove(pack.id);
  await ref.read(meetingsProvider.notifier).refresh();
  if (!context.mounted) return;
  context.go('/');
}
