import 'package:flutter/material.dart';

class AppTheme {
  static const seed = Color(0xFF1F8A7A);

  static ThemeData dark() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.dark,
        ).copyWith(
          surface: const Color(0xFF101614),
          surfaceContainerLowest: const Color(0xFF0B100F),
          surfaceContainerLow: const Color(0xFF151C1A),
          surfaceContainer: const Color(0xFF1B2421),
          surfaceContainerHigh: const Color(0xFF222C29),
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.4)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainer,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

Color speakerColor(int index) {
  const colors = [
    Color(0xFF2A9D8F),
    Color(0xFFE9C46A),
    Color(0xFF4C8DFF),
    Color(0xFFC77DFF),
    Color(0xFFE76F51),
    Color(0xFF90BE6D),
  ];
  return colors[index % colors.length];
}
