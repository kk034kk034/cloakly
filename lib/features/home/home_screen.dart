import 'package:cloakly/core/constants.dart';
import 'package:cloakly/data/models/models.dart';
import 'package:cloakly/data/models/project_pack.dart';
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
    final project = ref.watch(projectProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cloakly'),
        actions: [
          IconButton(
            tooltip: '專案知識庫',
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _ProjectBanner(project: project),
          ),
          Expanded(
            child: meetings.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('讀取失敗：$error')),
              data: (items) {
                if (items.isEmpty) {
                  return const _EmptyState();
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
    final pack = ref.read(projectProvider).valueOrNull;
    if (pack == null) {
      final goProject = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('還沒選定專案資料夾'),
          content: const Text(
            '沒有 WBS、Spec、Issue 當依據時，回答提示很容易變成臨場編造。建議先選定專案資料夾。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('仍要開會'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('先選資料夾'),
            ),
          ],
        ),
      );
      if (goProject == true && context.mounted) {
        context.push('/project');
        return;
      }
      if (!context.mounted) return;
    }
    final draft = await showDialog<StartMeetingDraft>(
      context: context,
      builder: (context) => StartMeetingDialog(
        initialMode: settings.listenMode,
        initialTrigger: settings.autoTrigger,
        initialPace: settings.pace,
        projectName: pack?.name,
      ),
    );
    if (draft == null || !context.mounted) return;
    await ref.read(sessionControllerProvider.notifier).start(
          title: draft.title,
          mode: draft.mode,
          trigger: draft.trigger,
          pace: draft.pace,
        );
    if (!context.mounted) return;
    context.push('/session');
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

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
                Icons.graphic_eq,
                size: 56,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                '會議進行中就能記筆記、拿回答提示',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 10),
              Text(
                '先選定專案資料夾，開會時被問到才會依規格與現況給提示，而不是臨場編答案。',
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

class _ProjectBanner extends StatelessWidget {
  const _ProjectBanner({required this.project});

  final AsyncValue<ProjectPack?> project;

  @override
  Widget build(BuildContext context) {
    return project.when(
      loading: () => const LinearProgressIndicator(),
      error: (error, _) => Card(
        child: ListTile(
          leading: const Icon(Icons.error_outline),
          title: Text('專案資料夾讀取失敗：$error'),
        ),
      ),
      data: (pack) {
        if (pack == null) {
          return Card(
            child: ListTile(
              onTap: () => GoRouter.of(context).push('/project'),
              leading: const Icon(Icons.folder_open),
              title: const Text('尚未選定專案資料夾'),
              subtitle: const Text('會議前先讓助手讀過 Spec、WBS、Issue'),
              trailing: const Icon(Icons.chevron_right),
            ),
          );
        }
        return Card(
          child: ListTile(
            onTap: () => GoRouter.of(context).push('/project'),
            leading: const Icon(Icons.folder),
            title: Text(pack.name),
            subtitle: Text('已納入 ${pack.includedCount} 份文件，開會時提示會讀這些內容'),
            trailing: const Icon(Icons.chevron_right),
          ),
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
          '$date · ${formatDuration(meeting.duration)} · ${meeting.listenMode.label}',
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

class StartMeetingDraft {
  const StartMeetingDraft({
    required this.title,
    required this.mode,
    required this.trigger,
    required this.pace,
  });

  final String title;
  final ListenMode mode;
  final AutoTrigger trigger;
  final Pace pace;
}

class StartMeetingDialog extends StatefulWidget {
  const StartMeetingDialog({
    super.key,
    required this.initialMode,
    required this.initialTrigger,
    required this.initialPace,
    this.projectName,
  });

  final ListenMode initialMode;
  final AutoTrigger initialTrigger;
  final Pace initialPace;
  final String? projectName;

  @override
  State<StartMeetingDialog> createState() => _StartMeetingDialogState();
}

class _StartMeetingDialogState extends State<StartMeetingDialog> {
  late final TextEditingController _title;
  late ListenMode _mode;
  late AutoTrigger _trigger;
  late Pace _pace;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController();
    _mode = widget.initialMode;
    _trigger = widget.initialTrigger;
    _pace = widget.initialPace;
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('開始會議'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.projectName == null
                    ? '這場會議沒有綁定專案資料夾。'
                    : '將使用專案：${widget.projectName}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _title,
                decoration: const InputDecoration(
                  labelText: '標題（可空白）',
                  hintText: '例如：產品週會',
                ),
              ),
              const SizedBox(height: 16),
              const Text('模式'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ListenMode.values.map((mode) {
                  return ChoiceChip(
                    label: Text(mode.label),
                    selected: _mode == mode,
                    onSelected: (_) => setState(() => _mode = mode),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Text('自動提示'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: AutoTrigger.values.map((trigger) {
                  return ChoiceChip(
                    label: Text(trigger.label),
                    selected: _trigger == trigger,
                    onSelected: (_) => setState(() => _trigger = trigger),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              Text(
                _trigger.hint,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              const Text('節奏'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: Pace.values.map((pace) {
                  return ChoiceChip(
                    label: Text(pace.label),
                    selected: _pace == pace,
                    onSelected: (_) => setState(() => _pace = pace),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(
              context,
              StartMeetingDraft(
                title: _title.text,
                mode: _mode,
                trigger: _trigger,
                pace: _pace,
              ),
            );
          },
          child: const Text('開始錄音'),
        ),
      ],
    );
  }
}
