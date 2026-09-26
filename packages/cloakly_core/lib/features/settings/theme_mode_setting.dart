import 'package:cloakly_core/core/theme/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ThemeModeSetting extends ConsumerWidget {
  const ThemeModeSetting({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('外觀', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SegmentedButton<ThemeMode>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(
              value: ThemeMode.light,
              label: Text('淺色'),
              icon: Icon(Icons.light_mode_outlined),
            ),
            ButtonSegment(
              value: ThemeMode.dark,
              label: Text('深色'),
              icon: Icon(Icons.dark_mode_outlined),
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
    return IconButton(
      tooltip: dark ? '切換為淺色模式' : '切換為深色模式',
      onPressed: () {
        ref
            .read(themeModeProvider.notifier)
            .setMode(dark ? ThemeMode.light : ThemeMode.dark);
      },
      icon: Icon(dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
    );
  }
}
