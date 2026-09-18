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
  late final TextEditingController _sonioxKey;
  late final TextEditingController _chatModel;
  late bool _captureSystemAudio;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _openaiKey = TextEditingController(text: settings.openaiApiKey);
    _sonioxKey = TextEditingController(text: settings.sonioxApiKey);
    _chatModel = TextEditingController(text: settings.chatModel);
    _captureSystemAudio = settings.captureSystemAudio;
  }

  @override
  void dispose() {
    _openaiKey.dispose();
    _sonioxKey.dispose();
    _chatModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
        actions: [TextButton(onPressed: _save, child: const Text('儲存'))],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text('多人即時逐字稿', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _sonioxKey,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Soniox API 金鑰',
              helperText: '持續串流辨識。文字與發言人會先暫定，再隨音訊更新。',
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text('自動辨識發言語言。各專案的背景與詞彙請到該專案右上角設定。'),
          ),
          const SizedBox(height: 24),
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
              helperText: '用於回答建議與會議紀錄；即時轉寫使用上方的 Soniox 金鑰。',
            ),
          ),
          const SizedBox(height: 24),
          Text('系統聲音', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('擷取電腦正在播放的聲音'),
            subtitle: const Text(
              '戴耳機開線上會議時，麥克風是「我」，系統聲音由模型區分其他人。多人共用同一支麥克風時請關閉此項。',
            ),
            value: _captureSystemAudio,
            onChanged: (value) => setState(() => _captureSystemAudio = value),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final next = ref
        .read(settingsProvider)
        .copyWith(
          sonioxApiKey: _sonioxKey.text.trim(),
          openaiApiKey: _openaiKey.text.trim(),
          chatModel: _chatModel.text.trim().isEmpty
              ? 'gpt-4o-mini'
              : _chatModel.text.trim(),
          captureSystemAudio: _captureSystemAudio,
        );
    await ref.read(settingsProvider.notifier).update(next);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('已儲存')));
  }
}
