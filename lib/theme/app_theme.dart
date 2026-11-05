import 'package:flutter/material.dart';

abstract final class AppColors {
  static const emerald = Color(0xFF2B7058);
  static const night = Color(0xFF142127);
  static const moonlight = Color(0xFF94C7B0);
}

/// Sakina in light mode; Layl in dark mode.
ThemeData appTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.emerald,
        brightness: brightness,
      ).copyWith(
        surface: dark ? const Color(0xFF1C3032) : Colors.white,
        onSurface: dark ? const Color(0xFFE4EDE8) : const Color(0xFF173E31),
        onSurfaceVariant: dark
            ? const Color(0xFFB6C9C0)
            : const Color(0xFF536C5D),
        primary: dark ? AppColors.moonlight : AppColors.emerald,
        onPrimary: dark ? const Color(0xFF162B26) : Colors.white,
        outlineVariant: dark
            ? const Color(0xFF354C48)
            : const Color(0xFFDCE6D6),
      );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'Tajawal',
    scaffoldBackgroundColor: dark ? AppColors.night : const Color(0xFFF5F8F3),
    visualDensity: VisualDensity.standard,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      scrolledUnderElevation: 0,
      centerTitle: true,
      foregroundColor: scheme.onSurface,
      titleTextStyle: TextStyle(
        fontFamily: 'Tajawal',
        fontSize: 19,
        fontWeight: FontWeight.bold,
        color: scheme.onSurface,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(
          fontFamily: 'Tajawal',
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size(48, 48),
        iconSize: 22,
        padding: const EdgeInsets.all(12),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: dark ? AppColors.night : const Color(0xFFF5F8F3),
      indicatorColor: dark ? const Color(0xFF29463F) : const Color(0xFFE4EEDF),
      elevation: 0,
      labelTextStyle: const WidgetStatePropertyAll(
        TextStyle(fontFamily: 'Tajawal', fontSize: 12),
      ),
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant),
  );
}
