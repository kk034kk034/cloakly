import 'package:cloakly_core/features/settings/language_setting.dart';
import 'package:cloakly_core/features/settings/theme_mode_setting.dart';
import 'package:cloakly_core/l10n/cloakly_locale.dart';
import 'package:cloakly_core/state/providers.dart';
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
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
        actions: [TextButton(onPressed: _save, child: Text(l10n.save))],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          const ThemeModeSetting(),
          const SizedBox(height: 16),
          const LanguageSetting(),
          const SizedBox(height: 24),
          Text(
            l10n.streamingTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _sonioxKey,
            obscureText: true,
            decoration: InputDecoration(
              labelText: l10n.sonioxKey,
              helperText: l10n.sonioxHelp,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(l10n.projectLanguageHint),
          ),
          const SizedBox(height: 24),
          Text('OpenAI', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _openaiKey,
            obscureText: true,
            decoration: InputDecoration(
              labelText: l10n.openaiKey,
              hintText: 'sk-...',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _chatModel,
            decoration: InputDecoration(
              labelText: l10n.chatModel,
              helperText: l10n.chatModelHelp,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.systemAudio,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.captureSystemAudio),
            subtitle: Text(l10n.captureSystemAudioHelp),
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
    ).showSnackBar(SnackBar(content: Text(context.l10n.saved)));
  }
}
