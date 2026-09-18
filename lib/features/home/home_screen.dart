import 'package:cloakly/data/models/models.dart';
import 'package:cloakly/features/session/session_controller.dart';
import 'package:cloakly/state/project_provider.dart';
import 'package:cloakly/state/providers.dart';
import 'package:cloakly/widgets/meeting_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meetings = ref.watch(meetingsProvider);
    final settings = ref.watch(settingsProvider);
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _startMeeting(context, ref),
        icon: const Icon(Icons.mic_none),
        label: const Text('開始會議'),
      ),
      body: Column(
        children: [
          if (settings.isDemo)
            MaterialBanner(
              content: const Text(
                '目前是示範模式。金鑰與系統聲音請到專案列表右上角的設定填寫。',
              ),
              actions: [
                TextButton(
                  onPressed: () => context.go('/'),
                  child: const Text('回專案列表'),
                ),
              ],
            ),
          Expanded(
            child: meetings.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('讀取失敗：$error')),
              data: (items) => _MeetingList(
                items: items,
                hasProject: active != null,
                projectName: active?.name,
                onOpen: (id) => context.push('/home/meeting/$id'),
                onDelete: (id) => ref.read(meetingsProvider.notifier).remove(id),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startMeeting(BuildContext context, WidgetRef ref) async {
    await ref.read(sessionControllerProvider.notifier).start(title: '');
    if (!context.mounted) return;
    final session = ref.read(sessionControllerProvider);
    if (session.phase != SessionPhase.live) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(session.error ?? '無法開始會議，請檢查設定。'),
          action: SnackBarAction(
            label: '回專案列表',
            onPressed: () => context.go('/'),
          ),
        ),
      );
      return;
    }
    context.push('/home/session');
  }
}

class _MeetingList extends StatelessWidget {
  const _MeetingList({
    required this.items,
    required this.hasProject,
    required this.onOpen,
    required this.onDelete,
    this.projectName,
  });

  final List<Meeting> items;
  final bool hasProject;
  final String? projectName;
  final ValueChanged<String> onOpen;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
        child: _EmptyState(hasProject: hasProject, projectName: projectName),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        Text('會議', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _MeetingTile(
            meeting: items[i],
            onOpen: () => onOpen(items[i].id),
            onDelete: () => onDelete(items[i].id),
          ),
        ],
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasProject, this.projectName});

  final bool hasProject;
  final String? projectName;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasProject ? Icons.graphic_eq : Icons.inbox_outlined,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              hasProject ? '${projectName ?? '這個專案'}還沒有會議' : '還沒有未分類會議',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),
            Text(
              hasProject
                  ? '開始會議後，錄音與逐字稿會存在這個專案底下。右上角可勾選要納入提示的文件。'
                  : '這裡只顯示沒有綁定專案的會議。要依專案文件給提示，請回到專案列表選一個專案。',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
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
