import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const themeModePreferenceKey = 'cloakly.themeMode';

/// 啟動時讀入的外觀。未設定時維持既有的深色介面。
ThemeMode bootThemeMode = ThemeMode.dark;

ThemeMode themeModeFromName(String? name) => switch (name) {
  'light' => ThemeMode.light,
  'dark' => ThemeMode.dark,
  _ => ThemeMode.dark,
};

Future<ThemeMode> loadThemeMode() async {
  final prefs = await SharedPreferences.getInstance();
  return themeModeFromName(prefs.getString(themeModePreferenceKey));
}

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => bootThemeMode;

  Future<void> setMode(ThemeMode mode) async {
    if (mode == ThemeMode.system || state == mode) return;
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(themeModePreferenceKey, mode.name);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class ThemeModeBuilder extends ConsumerWidget {
  const ThemeModeBuilder({super.key, required this.builder});

  final Widget Function(BuildContext context, ThemeMode mode) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return builder(context, ref.watch(themeModeProvider));
  }
}
