import 'package:flutter/material.dart';

enum AppThemeMode { dark, light, neon }

ThemeData buildAppTheme(AppThemeMode mode) {
  switch (mode) {
    case AppThemeMode.light:
      return ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF4F6F9),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF1F6F56),
          onPrimary: Colors.white,
          secondary: Color(0xFF4A7A92),
          surface: Color(0xFFFFFFFF),
          onSurface: Color(0xFF111827),
          outline: Color(0xFFB0B7C3),
          surfaceContainerHighest: Color(0xFFF0F3F8),
        ),
        textTheme: Typography.blackMountainView.apply(
          bodyColor: const Color(0xFF111827),
          displayColor: const Color(0xFF111827),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Color(0xFF111827),
          elevation: 0,
        ),
        listTileTheme: const ListTileThemeData(
          iconColor: Color(0xFF1F6F56),
        ),
      );
    case AppThemeMode.neon:
      return ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF070B17),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF58D4FF),
          onPrimary: Color(0xFF061022),
          secondary: Color(0xFFFF79C3),
          surface: Color(0xFF10142A),
          onSurface: Color(0xFFF1F7FF),
          outline: Color(0xFF3E6A95),
          surfaceContainerHighest: Color(0xFF11203D),
        ),
        textTheme: Typography.whiteMountainView.apply(
          bodyColor: const Color(0xFFF1F7FF),
          displayColor: const Color(0xFFF1F7FF),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Color(0xFFF1F7FF),
          elevation: 0,
        ),
        listTileTheme: const ListTileThemeData(
          iconColor: Color(0xFF58D4FF),
        ),
      );
    case AppThemeMode.dark:
      return ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF050505),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6EE7A0),
          onPrimary: Colors.black,
          secondary: Color(0xFF7EE7F7),
          surface: Color(0xFF050505),
          onSurface: Colors.white,
          outline: Color(0xFF4A4A4A),
          surfaceContainerHighest: Color(0xFF0F0F0F),
        ),
        textTheme: Typography.whiteMountainView.apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        listTileTheme: const ListTileThemeData(
          iconColor: Color(0xFF6EE7A0),
        ),
      );
  }
}
