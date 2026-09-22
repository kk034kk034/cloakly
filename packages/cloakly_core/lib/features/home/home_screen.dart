import 'package:cloakly_core/data/models/models.dart';
import 'package:cloakly_core/data/models/project_pack.dart';
import 'package:cloakly_core/features/session/session_controller.dart';
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

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: '切換專案',
          onPressed: () => context.go('/'),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(active?.name ?? '未分類'),
        actions: [
          if (active != null)
            IconButton(
              tooltip: '專案設定',
              onPressed: () => context.push('/home/project'),
              icon: const Icon(Icons.settings_outlined),
            ),
        ],
      ),
      body: meetings.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('讀取失敗：$error')),
        data: (items) {
          if (active == null) {
            return _UnassignedBody(
              isDemo: isDemo,
              items: items,
              onStartMeeting: () => _startMeeting(context, ref),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isDemo)
                MaterialBanner(
                  content: const Text('目前是示範模式。金鑰與系統聲音請到專案列表右上角的設定填寫。'),
                  actions: [
                    TextButton(
                      onPressed: () => context.go('/'),
                      child: const Text('回專案列表'),
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
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                  child: FilledButton.icon(
                    onPressed: () => _startMeeting(context, ref),
                    icon: const Icon(Icons.mic_none),
                    label: const Text('開始會議'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _startMeeting(BuildContext context, WidgetRef ref) async {
    await ref.read(sessionControllerProvider.notifier).start(title: '');
    if (!context.mounted) return;
    final session = ref.read(sessionControllerProvider);
    if (session.phase != SessionPhase.live) {
      final hosted = ref.read(hostedModeProvider);
      final needsSubscription =
          hosted && (session.error?.contains('免費會議額度') ?? false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(session.error ?? '無法開始會議，請檢查設定。'),
          action: SnackBarAction(
            label: needsSubscription ? '查看訂閱' : '回專案列表',
            onPressed: () => context.go(needsSubscription ? '/settings' : '/'),
          ),
        ),
      );
      return;
    }
    context.push('/home/session');
  }
}

class _UnassignedBody extends StatelessWidget {
  const _UnassignedBody({
    required this.isDemo,
    required this.items,
    required this.onStartMeeting,
  });

  final bool isDemo;
  final List<Meeting> items;
  final VoidCallback onStartMeeting;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                    content: const Text('目前是示範模式。金鑰與系統聲音請到專案列表右上角的設定填寫。'),
                    actions: [
                      TextButton(
                        onPressed: () => context.go('/'),
                        child: const Text('回專案列表'),
                      ),
                    ],
                  ),
                ),
              Text('未分類會議', style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                '沒有綁定專案時，仍可直接開始會議。要依專案文件問答，請先選一個專案。',
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
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: FilledButton.icon(
              onPressed: onStartMeeting,
              icon: const Icon(Icons.mic_none),
              label: const Text('開始會議'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProjectStatusCard extends StatelessWidget {
  const _ProjectStatusCard({
    required this.project,
    required this.onOpenPlan,
  });

  final ProjectPack project;
  final VoidCallback onOpenPlan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
        ? '尚未建立階段'
        : tasks.isEmpty
        ? '${phase.name} · 尚無工作'
        : '${phase.name} · 進行中 $inProgress · 阻塞 $blocked · 未完成 $open';

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
                    Text('專案狀態', style: theme.textTheme.titleSmall),
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
    final subtitle = items.isEmpty
        ? (hasProject ? '還沒有會議' : '還沒有未分類會議')
        : '${items.length} 場 · 最近 ${DateFormat('MM/dd HH:mm').format(items.first.startedAt)}';

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
                    Text('會議紀錄', style: theme.textTheme.titleSmall),
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
