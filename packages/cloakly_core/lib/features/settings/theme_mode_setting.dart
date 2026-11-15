import 'package:cloakly_core/core/theme/theme_controller.dart';
import 'package:cloakly_core/l10n/cloakly_locale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ThemeModeSetting extends ConsumerWidget {
  const ThemeModeSetting({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.appearance, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SegmentedButton<ThemeMode>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(
              value: ThemeMode.light,
              label: Text(l10n.themeLight),
              icon: const Icon(Icons.light_mode_outlined),
            ),
            ButtonSegment(
              value: ThemeMode.dark,
              label: Text(l10n.themeDark),
              icon: const Icon(Icons.dark_mode_outlined),
            ),
          ],
          selected: {mode},
          onSelectionChanged: (selection) {
            ref.read(themeModeProvider.notifier).setMode(selection.first);
          },
        ),
      ],
    );
  }
}

class ThemeModeToggleButton extends ConsumerWidget {
  const ThemeModeToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = ref.watch(themeModeProvider) == ThemeMode.dark;
    final l10n = context.l10n;
    return IconButton(
      tooltip: dark ? l10n.switchToLight : l10n.switchToDark,
      onPressed: () {
        ref
            .read(themeModeProvider.notifier)
            .setMode(dark ? ThemeMode.light : ThemeMode.dark);
      },
      icon: Icon(dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
    );
  }
}
