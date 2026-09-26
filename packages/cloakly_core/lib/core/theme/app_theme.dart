import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  static const seed = Color(0xFF1F8A7A);

  static ThemeData light() => _build(
    ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
    ).copyWith(
      primary: const Color(0xFF14685C),
      onPrimary: const Color(0xFFF7FFFC),
      primaryContainer: const Color(0xFFB7E4D8),
      onPrimaryContainer: const Color(0xFF08352E),
      secondary: const Color(0xFF8C5A32),
      onSecondary: const Color(0xFFFFF8F2),
      secondaryContainer: const Color(0xFFF3DCC6),
      onSecondaryContainer: const Color(0xFF3D2412),
      surface: const Color(0xFFF6F1E6),
      surfaceDim: const Color(0xFFE8E0D0),
      surfaceBright: const Color(0xFFFFFCF7),
      surfaceContainerLowest: const Color(0xFFFFFDF9),
      surfaceContainerLow: const Color(0xFFFFFCF7),
      surfaceContainer: const Color(0xFFDCECE6),
      surfaceContainerHigh: const Color(0xFFCFE3DB),
      surfaceContainerHighest: const Color(0xFFC5DDD4),
      onSurface: const Color(0xFF1E2724),
      onSurfaceVariant: const Color(0xFF4A5A54),
      outline: const Color(0xFF6E837A),
      outlineVariant: const Color(0xFFCDBFA8),
      surfaceTint: const Color(0xFF14685C),
    ),
  );

  static ThemeData dark() => _build(
    ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark).copyWith(
      surface: const Color(0xFF101614),
      surfaceContainerLowest: const Color(0xFF0B100F),
      surfaceContainerLow: const Color(0xFF151C1A),
      surfaceContainer: const Color(0xFF1B2421),
      surfaceContainerHigh: const Color(0xFF222C29),
    ),
  );

  static ThemeData _build(ColorScheme scheme) {
    final overlay = scheme.brightness == Brightness.dark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      canvasColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: overlay.copyWith(
          statusBarColor: Colors.transparent,
        ),
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: scheme.outlineVariant.withValues(
              alpha: scheme.brightness == Brightness.light ? 0.9 : 0.4,
            ),
          ),
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

Color speakerColor(int index, {Brightness brightness = Brightness.dark}) {
  const onDark = [
    Color(0xFF2A9D8F),
    Color(0xFFE9C46A),
    Color(0xFF4C8DFF),
    Color(0xFFC77DFF),
    Color(0xFFE76F51),
    Color(0xFF90BE6D),
  ];
  const onLight = [
    Color(0xFF1A7A6E),
    Color(0xFF8A6410),
    Color(0xFF2457C5),
    Color(0xFF7A3DB8),
    Color(0xFFC25438),
    Color(0xFF3F6E32),
  ];
  final colors = brightness == Brightness.dark ? onDark : onLight;
  return colors[index % colors.length];
}
