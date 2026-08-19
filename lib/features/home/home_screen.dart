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
        title: Text(active?.name ?? 'Cloakly'),
        actions: [
          IconButton(
            tooltip: '專案',
            onPressed: () => context.push('/project'),
            icon: const Icon(Icons.folder_outlined),
          ),
          IconButton(
            tooltip: '設定',
            onPressed: () => context.push('/settings'),
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
                '目前是示範模式：沒有 API 金鑰時會播放模擬會議。填入 OpenAI 金鑰後即可即時轉寫。',
              ),
              actions: [
                TextButton(
                  onPressed: () => context.push('/settings'),
                  child: const Text('前往設定'),
                ),
              ],
            ),
          Expanded(
            child: meetings.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('讀取失敗：$error')),
              data: (items) {
                if (items.isEmpty) {
                  return _EmptyState(
                    hasProject: active != null,
                    projectName: active?.name,
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final meeting = items[index];
                    return _MeetingTile(
                      meeting: meeting,
                      onOpen: () => context.push('/meeting/${meeting.id}'),
                      onDelete: () => ref
                          .read(meetingsProvider.notifier)
                          .remove(meeting.id),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startMeeting(BuildContext context, WidgetRef ref) async {
    final settings = ref.read(settingsProvider);
    await ref.read(sessionControllerProvider.notifier).start(
          title: '',
          trigger: settings.autoTrigger,
          pace: settings.pace,
        );
    if (!context.mounted) return;
    context.push('/session');
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
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                hasProject ? Icons.graphic_eq : Icons.folder_open,
                size: 56,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                hasProject
                    ? '${projectName ?? '這個專案'}還沒有會議'
                    : '還沒有會議',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 10),
              Text(
                hasProject
                    ? '開始會議後，錄音與逐字稿會存在這個專案底下。'
                    : '可以直接開始會議。要依專案文件給提示，再到右上角資料夾選一個專案。',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
              ),
            ],
          ),
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
        subtitle: Text(
          '$date · ${formatDuration(meeting.duration)}',
        ),
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
