import 'package:cloakly_core/data/models/models.dart';
import 'package:cloakly_core/features/session/session_controller.dart';
import 'package:cloakly_core/state/project_provider.dart';
import 'package:cloakly_core/state/providers.dart';
import 'package:cloakly_core/widgets/meeting_widgets.dart';
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
    final activePhase = active?.withNormalizedPhases().activePhase;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: '切換專案',
          onPressed: () => context.go('/'),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(active?.name ?? '未分類'),
        actions: [
          if (active != null) ...[
            IconButton(
              tooltip: activePhase == null
                  ? '甘特圖／階段看板'
                  : '甘特圖 · ${activePhase.name}',
              onPressed: () => context.push(
                '/home/project/${Uri.encodeComponent(active.id)}/plan',
              ),
              icon: const Icon(Icons.view_timeline_outlined),
            ),
            IconButton(
              tooltip: '專案設定',
              onPressed: () => context.push('/home/project'),
              icon: const Icon(Icons.settings_outlined),
            ),
          ],
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
              onOpen: (id) => context.push('/home/meeting/$id'),
              onDelete: (id) =>
                  ref.read(meetingsProvider.notifier).remove(id),
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
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _startMeeting(context, ref),
                        icon: const Icon(Icons.mic_none),
                        label: const Text('開始會議'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MeetingsCard(
                        items: items,
                        hasProject: true,
                        projectName: active.name,
                        compact: true,
                        onOpen: (id) => context.push('/home/meeting/$id'),
                        onDelete: (id) =>
                            ref.read(meetingsProvider.notifier).remove(id),
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
    required this.onOpen,
    required this.onDelete,
  });

  final bool isDemo;
  final List<Meeting> items;
  final VoidCallback onStartMeeting;
  final ValueChanged<String> onOpen;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
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
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: onStartMeeting,
          icon: const Icon(Icons.mic_none),
          label: const Text('開始會議'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
        ),
        const SizedBox(height: 12),
        _MeetingsCard(
          items: items,
          hasProject: false,
          onOpen: onOpen,
          onDelete: onDelete,
        ),
      ],
    );
  }
}

class _MeetingsCard extends StatelessWidget {
  const _MeetingsCard({
    required this.items,
    required this.hasProject,
    required this.onOpen,
    required this.onDelete,
    this.projectName,
    this.compact = false,
  });

  final List<Meeting> items;
  final bool hasProject;
  final String? projectName;
  final ValueChanged<String> onOpen;
  final ValueChanged<String> onDelete;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (items.isEmpty) {
      return Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: EdgeInsets.all(compact ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                compact ? '會議 · 0' : '會議紀錄',
                style: theme.textTheme.titleSmall,
              ),
              if (!compact) ...[
                const SizedBox(height: 8),
                Text(
                  hasProject
                      ? '還沒有會議。開始後會收在這裡。'
                      : '還沒有未分類會議。',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    final latest = items.first;
    final latestDate = DateFormat('MM/dd HH:mm').format(latest.startedAt);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showMeetingsSheet(context),
        child: Padding(
          padding: EdgeInsets.all(compact ? 12 : 16),
          child: Row(
            children: [
              if (!compact) ...[
                CircleAvatar(
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.folder_shared_outlined),
                ),
                const SizedBox(width: 14),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      compact
                          ? '會議 · ${items.length}'
                          : '會議紀錄 · ${items.length} 場',
                      style: compact
                          ? theme.textTheme.titleSmall
                          : theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      compact
                          ? latestDate
                          : '最近：${latest.title} · $latestDate',
                      maxLines: 1,
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

  Future<void> _showMeetingsSheet(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    '會議紀錄 · ${items.length} 場',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final meeting = items[index];
                      return _MeetingTile(
                        meeting: meeting,
                        onOpen: () {
                          Navigator.pop(sheetContext);
                          onOpen(meeting.id);
                        },
                        onDelete: () {
                          Navigator.pop(sheetContext);
                          onDelete(meeting.id);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _MeetingTile extends StatelessWidget {
  const _MeetingTile({
    required this.meeting,
    required this.onOpen,
    required this.onDelete,
  });

  final Meeting meeting;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('yyyy/MM/dd HH:mm').format(meeting.startedAt);
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        onTap: onOpen,
        leading: CircleAvatar(
          child: Icon(
            meeting.status == MeetingStatus.completed
                ? Icons.description_outlined
                : Icons.mic,
          ),
        ),
        title: Text(meeting.title),
        subtitle: Text('$date · ${formatDuration(meeting.duration)}'),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('刪除這場會議？'),
                content: const Text('逐字稿、筆記與提示都會一起刪除。'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('取消'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('刪除'),
                  ),
                ],
              ),
            );
            if (ok == true) onDelete();
          },
        ),
      ),
    );
  }
}
