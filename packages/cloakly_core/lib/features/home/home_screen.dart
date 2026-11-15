import 'package:cloakly_core/data/models/models.dart';
import 'package:cloakly_core/data/models/project_pack.dart';
import 'package:cloakly_core/features/session/session_controller.dart';
import 'package:cloakly_core/l10n/cloakly_locale.dart';
import 'package:cloakly_core/features/settings/theme_mode_setting.dart';
import 'package:cloakly_core/state/project_provider.dart';
import 'package:cloakly_core/state/providers.dart';
import 'package:cloakly_core/widgets/project_question_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meetings = ref.watch(meetingsProvider);
    final isDemo = ref.watch(demoModeProvider);
    final active = ref.watch(projectsProvider).valueOrNull?.active;
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: l10n.switchProject,
          onPressed: () => context.go('/'),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(active?.name ?? l10n.unassigned),
        actions: [
          const ThemeModeToggleButton(),
          if (active != null)
            IconButton(
              tooltip: l10n.projectSettings,
              onPressed: () => context.push('/home/project'),
              icon: const Icon(Icons.settings_outlined),
            ),
        ],
      ),
      body: meetings.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(l10n.loadFailed('$error'))),
        data: (items) {
          if (active == null) {
            return _UnassignedBody(isDemo: isDemo, items: items);
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isDemo)
                MaterialBanner(
                  content: Text(l10n.demoBanner),
                  actions: [
                    TextButton(
                      onPressed: () => context.go('/'),
                      child: Text(l10n.backToProjects),
                    ),
                  ],
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _ProjectStatusCard(
                        project: active,
                        onOpenPlan: () => context.push(
                          '/home/project/${Uri.encodeComponent(active.id)}/plan',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MeetingsCard(
                        items: items,
                        hasProject: true,
                        onOpenList: () => context.push('/home/meetings'),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ProjectQuestionPanel(
                  project: active,
                  compactIntro: true,
                ),
              ),
              const Divider(height: 1),
              const _StartMeetingBar(),
            ],
          );
        },
      ),
    );
  }
}

class _StartMeetingBar extends ConsumerWidget {
  const _StartMeetingBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    final starting = session.busyHint && session.phase == SessionPhase.idle;
    final label = session.startupStep == SessionStartupStep.none
        ? SessionStartupStep.preparing.label
        : session.startupStep.label;
    final l10n = context.l10n;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: starting
            ? Row(
                key: const Key('start-meeting-progress'),
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(label)),
                  TextButton(
                    key: const Key('start-meeting-cancel'),
                    onPressed: () => ref
                        .read(sessionControllerProvider.notifier)
                        .cancelStart(),
                    child: Text(l10n.cancel),
                  ),
                ],
              )
            : FilledButton.icon(
                key: const Key('start-meeting-button'),
                onPressed: () => _startMeeting(context, ref),
                icon: const Icon(Icons.mic_none),
                label: Text(l10n.startMeeting),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
              ),
      ),
    );
  }
}

Future<void> _startMeeting(BuildContext context, WidgetRef ref) async {
  final before = ref.read(sessionControllerProvider);
  if (before.busyHint || before.phase == SessionPhase.live) return;

  await ref.read(sessionControllerProvider.notifier).start(title: '');
  if (!context.mounted) return;
  final session = ref.read(sessionControllerProvider);
  if (session.phase == SessionPhase.live) {
    context.push('/home/session');
    return;
  }
  final error = session.error;
  if (error == null || error.isEmpty) return;
  final hosted = ref.read(hostedModeProvider);
  final l10n = context.l10n;
  final needsSubscription =
      hosted && error.contains(l10n.freeMeetingQuotaMarker);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(error),
      action: SnackBarAction(
        label: needsSubscription ? l10n.viewSubscription : l10n.backToProjects,
        onPressed: () => context.go(needsSubscription ? '/settings' : '/'),
      ),
    ),
  );
}

class _UnassignedBody extends StatelessWidget {
  const _UnassignedBody({required this.isDemo, required this.items});

  final bool isDemo;
  final List<Meeting> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            children: [
              if (isDemo)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: MaterialBanner(
                    content: Text(l10n.demoBanner),
                    actions: [
                      TextButton(
                        onPressed: () => context.go('/'),
                        child: Text(l10n.backToProjects),
                      ),
                    ],
                  ),
                ),
              Text(l10n.unassignedMeetings, style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                l10n.unassignedHint,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              _MeetingsCard(
                items: items,
                hasProject: false,
                onOpenList: () => context.push('/home/meetings'),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        const _StartMeetingBar(),
      ],
    );
  }
}

class _ProjectStatusCard extends StatelessWidget {
  const _ProjectStatusCard({required this.project, required this.onOpenPlan});

  final ProjectPack project;
  final VoidCallback onOpenPlan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final normalized = project.withNormalizedPhases();
    final phase = normalized.activePhase;
    final tasks = normalized.activePhaseTasks;
    final inProgress = tasks
        .where((task) => task.status == ProjectTaskStatus.inProgress)
        .length;
    final blocked = tasks
        .where((task) => task.status == ProjectTaskStatus.blocked)
        .length;
    final done = tasks
        .where((task) => task.status == ProjectTaskStatus.done)
        .length;
    final open = tasks.length - done;

    final subtitle = phase == null
        ? l10n.noPhaseYet
        : tasks.isEmpty
        ? l10n.phaseNoTasks(phase.name)
        : l10n.phaseTaskSummary(phase.name, inProgress, blocked, open);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpenPlan,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(l10n.projectStatus, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.view_timeline_outlined,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MeetingsCard extends StatelessWidget {
  const _MeetingsCard({
    required this.items,
    required this.hasProject,
    required this.onOpenList,
  });

  final List<Meeting> items;
  final bool hasProject;
  final VoidCallback onOpenList;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final subtitle = items.isEmpty
        ? (hasProject ? l10n.noMeetingsYet : l10n.noUnassignedMeetings)
        : l10n.meetingsRecent(
            items.length,
            DateFormat('MM/dd HH:mm').format(items.first.startedAt),
          );

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpenList,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(l10n.meetingsTitle, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
