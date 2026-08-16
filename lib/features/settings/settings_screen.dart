import 'package:cloakly/core/constants.dart';
import 'package:cloakly/data/models/models.dart';
import 'package:cloakly/state/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _openaiKey;
  late final TextEditingController _chatModel;
  late final TextEditingController _context;
  late String _language;
  late AutoTrigger _trigger;
  late Pace _pace;
  late ListenMode _mode;
  late bool _captureSystemAudio;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _openaiKey = TextEditingController(text: settings.openaiApiKey);
    _chatModel = TextEditingController(text: settings.chatModel);
    _context = TextEditingController(text: settings.personalContext);
    _language = settings.language;
    _trigger = settings.autoTrigger;
    _pace = settings.pace;
    _mode = settings.listenMode;
    _captureSystemAudio = settings.captureSystemAudio;
  }

  @override
  void dispose() {
    _openaiKey.dispose();
    _chatModel.dispose();
    _context.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('儲存'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text('OpenAI', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _openaiKey,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'OpenAI API 金鑰',
              hintText: 'sk-...',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _chatModel,
            decoration: const InputDecoration(
              labelText: '對話模型',
              helperText: '例如 gpt-4o-mini。轉寫固定用 OpenAI，系統聲音會拆對方A/B。',
            ),
          ),
          const SizedBox(height: 24),
          Text('系統聲音', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('擷取電腦正在播放的聲音'),
            subtitle: const Text(
              '戴耳機開 Teams / Meet / Zoom 時，才能聽到客戶。麥克風是「我」；系統聲音會依聲紋拆成對方A、對方B。手機做不到，請用電腦版。',
            ),
            value: _captureSystemAudio,
            onChanged: (value) => setState(() => _captureSystemAudio = value),
          ),
          const SizedBox(height: 24),
          Text('語言', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'zh', label: Text('中文')),
              ButtonSegment(value: 'en', label: Text('English')),
              ButtonSegment(value: 'auto', label: Text('自動')),
            ],
            selected: {_language},
            onSelectionChanged: (value) {
              setState(() => _language = value.first);
            },
          ),
          const SizedBox(height: 24),
          Text('預設會議行為', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          DropdownButtonFormField<ListenMode>(
            key: ValueKey(_mode),
            initialValue: _mode,
            decoration: const InputDecoration(labelText: '預設模式'),
            items: ListenMode.values
                .map(
                  (mode) => DropdownMenuItem(
                    value: mode,
                    child: Text(mode.label),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _mode = value);
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<AutoTrigger>(
            key: ValueKey(_trigger),
            initialValue: _trigger,
            decoration: const InputDecoration(labelText: '預設自動提示'),
            items: AutoTrigger.values
                .map(
                  (trigger) => DropdownMenuItem(
                    value: trigger,
                    child: Text(trigger.label),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _trigger = value);
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<Pace>(
            key: ValueKey(_pace),
            initialValue: _pace,
            decoration: const InputDecoration(labelText: '預設節奏'),
            items: Pace.values
                .map(
                  (pace) => DropdownMenuItem(
                    value: pace,
                    child: Text(pace.label),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _pace = value);
            },
          ),
          const SizedBox(height: 24),
          Text('個人背景', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _context,
            minLines: 6,
            maxLines: 12,
            decoration: const InputDecoration(
              hintText: '職稱、專案、產品重點、常用數字。提示會優先用這裡的內容，避免當場編造。',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final next = AppSettings(
      openaiApiKey: _openaiKey.text.trim(),
      chatModel: _chatModel.text.trim().isEmpty ? 'gpt-4o-mini' : _chatModel.text.trim(),
      language: _language,
      personalContext: _context.text,
      autoTrigger: _trigger,
      pace: _pace,
      listenMode: _mode,
      captureSystemAudio: _captureSystemAudio,
    );
    await ref.read(settingsProvider.notifier).update(next);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已儲存')),
    );
  }
}
