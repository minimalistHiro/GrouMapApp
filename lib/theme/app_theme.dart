import 'package:flutter/material.dart';

import 'app_ui.dart';

abstract final class AppTheme {
  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppUi.primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppUi.primary,
      onPrimary: AppUi.onPrimary,
      surface: AppUi.surface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppUi.surface,
      canvasColor: AppUi.surface,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppUi.primary,
        foregroundColor: AppUi.onPrimary,
        centerTitle: true,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: AppUi.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppUi.cardRadius),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppUi.primary,
          foregroundColor: AppUi.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppUi.primary,
          side: const BorderSide(color: AppUi.primary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppUi.textButton,
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppUi.controlRadius),
          borderSide: const BorderSide(color: AppUi.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppUi.controlRadius),
          borderSide: const BorderSide(color: AppUi.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppUi.controlRadius),
          borderSide: const BorderSide(color: AppUi.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppUi.controlRadius),
          borderSide: const BorderSide(color: AppUi.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppUi.controlRadius),
          borderSide: const BorderSide(color: AppUi.error, width: 2),
        ),
        errorStyle: const TextStyle(
          color: AppUi.error,
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          return Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppUi.primary;
          }
          return const Color(0xFFE0E0E0);
        }),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
    );
  }
}
