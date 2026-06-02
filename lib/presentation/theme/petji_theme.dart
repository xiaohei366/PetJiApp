import 'package:flutter/material.dart';

class PetjiColors {
  const PetjiColors._();

  static const primary = Color(0xFFF97316);
  static const secondary = Color(0xFFFB923C);
  static const cta = Color(0xFF2563EB);
  static const background = Color(0xFFFFF7ED);
  static const text = Color(0xFF9A3412);
  static const surface = Color(0xFFFFFFFF);
  static const muted = Color(0xFF7C2D12);
  static const success = Color(0xFF059669);
}

class PetjiTheme {
  const PetjiTheme._();

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: PetjiColors.primary,
      primary: PetjiColors.primary,
      secondary: PetjiColors.cta,
      surface: PetjiColors.surface,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: PetjiColors.background,
      fontFamily: 'Roboto',
      textTheme: _textTheme(PetjiColors.text),
      cardTheme: CardThemeData(
        color: PetjiColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFFFEDD5)),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: PetjiColors.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: PetjiColors.primary, width: 2),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: PetjiColors.surface,
        indicatorColor: PetjiColors.primary.withValues(alpha: 0.14),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        ),
      ),
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: PetjiColors.primary,
      brightness: Brightness.dark,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFF1C1917),
      textTheme: _textTheme(const Color(0xFFFFEDD5)),
    );
  }

  static TextTheme _textTheme(Color textColor) {
    return TextTheme(
      headlineMedium: TextStyle(
        color: textColor,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
      ),
      titleLarge: TextStyle(
        color: textColor,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
      ),
      titleMedium: TextStyle(
        color: textColor,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
      bodyMedium: TextStyle(color: textColor, letterSpacing: 0, height: 1.4),
      labelLarge: TextStyle(
        color: textColor,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
    );
  }
}
