import 'package:cloakly_core/data/models/models.dart';
import 'package:cloakly_core/state/project_provider.dart';
import 'package:cloakly_core/state/providers.dart';
import 'package:cloakly_core/widgets/meeting_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class MeetingsListScreen extends ConsumerWidget {
  const MeetingsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meetings = ref.watch(meetingsProvider);
    final projectName =
        ref.watch(projectsProvider).valueOrNull?.active?.name;

    return Scaffold(
      appBar: AppBar(
        title: Text(projectName == null ? '會議紀錄' : '$projectName · 會議紀錄'),
      ),
      body: meetings.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('讀取失敗：$error')),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  projectName == null
                      ? '還沒有未分類會議。'
                      : '還沒有會議。開始後會收在這裡。',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final meeting = items[index];
              return _MeetingTile(
                meeting: meeting,
                onOpen: () => context.push('/home/meeting/${meeting.id}'),
                onDelete: () =>
                    ref.read(meetingsProvider.notifier).remove(meeting.id),
              );
            },
          );
        },
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
