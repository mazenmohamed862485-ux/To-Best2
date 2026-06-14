import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';

enum AppThemeType { dark, light, luxury, sports }

class AppTheme {
  AppTheme._();

  static ThemeData buildTheme(AppThemeType type, Color accent) {
    switch (type) {
      case AppThemeType.light:
        return _lightTheme(accent);
      case AppThemeType.luxury:
        return _luxuryTheme(accent);
      case AppThemeType.sports:
        return _sportsTheme(accent);
      case AppThemeType.dark:
      default:
        return _darkTheme(accent);
    }
  }

  // ── Dark Theme ──────────────────────────────────────────────
  static ThemeData _darkTheme(Color accent) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: accent,
        secondary: accent,
        surface: AppColors.darkSurface,
        background: AppColors.darkBg,
        onPrimary: Colors.white,
        onSurface: AppColors.darkText,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.darkBg,
      cardColor: AppColors.darkCard,
      fontFamily: 'Cairo',
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkBg,
        foregroundColor: AppColors.darkText,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarBrightness: Brightness.dark,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: accent,
        unselectedItemColor: AppColors.darkText3,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        indicatorColor: accent.withOpacity(0.2),
        iconTheme: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return IconThemeData(color: accent);
          }
          return const IconThemeData(color: AppColors.darkText3);
        }),
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.w700, fontFamily: 'Cairo');
          }
          return const TextStyle(color: AppColors.darkText3, fontSize: 11, fontFamily: 'Cairo');
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accent,
          side: BorderSide(color: accent.withOpacity(0.6)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          textStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
        hintStyle: const TextStyle(color: AppColors.darkText3, fontFamily: 'Cairo'),
        labelStyle: const TextStyle(color: AppColors.darkText2, fontFamily: 'Cairo'),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      cardTheme: CardTheme(
        color: AppColors.darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.darkBorder),
        ),
      ),
      dividerColor: AppColors.darkBorder,
      textTheme: _buildTextTheme(AppColors.darkText, AppColors.darkText2),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((s) =>
            s.contains(MaterialState.selected) ? accent : AppColors.darkText3),
        trackColor: MaterialStateProperty.resolveWith((s) =>
            s.contains(MaterialState.selected) ? accent.withOpacity(0.4) : AppColors.darkBorder),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: accent,
        thumbColor: accent,
        inactiveTrackColor: accent.withOpacity(0.2),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkCard,
        selectedColor: accent.withOpacity(0.2),
        side: const BorderSide(color: AppColors.darkBorder),
        labelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      extensions: [
        AppThemeExtension(
          bg: AppColors.darkBg,
          surface: AppColors.darkSurface,
          card: AppColors.darkCard,
          border: AppColors.darkBorder,
          text: AppColors.darkText,
          text2: AppColors.darkText2,
          text3: AppColors.darkText3,
          accent: accent,
        ),
      ],
    );
  }

  // ── Light Theme ─────────────────────────────────────────────
  static ThemeData _lightTheme(Color accent) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: accent,
        secondary: accent,
        surface: AppColors.lightSurface,
        background: AppColors.lightBg,
        onPrimary: Colors.white,
        onSurface: AppColors.lightText,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.lightBg,
      cardColor: AppColors.lightCard,
      fontFamily: 'Cairo',
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightBg,
        foregroundColor: AppColors.lightText,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarBrightness: Brightness.light,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightSurface,
        selectedItemColor: accent,
        unselectedItemColor: AppColors.lightText3,
        elevation: 2,
        type: BottomNavigationBarType.fixed,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.lightSurface,
        indicatorColor: accent.withOpacity(0.15),
        iconTheme: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return IconThemeData(color: accent);
          }
          return const IconThemeData(color: AppColors.lightText3);
        }),
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.w700, fontFamily: 'Cairo');
          }
          return const TextStyle(color: AppColors.lightText3, fontSize: 11, fontFamily: 'Cairo');
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accent,
          side: BorderSide(color: accent.withOpacity(0.6)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
        hintStyle: const TextStyle(color: AppColors.lightText3, fontFamily: 'Cairo'),
        labelStyle: const TextStyle(color: AppColors.lightText2, fontFamily: 'Cairo'),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      cardTheme: CardTheme(
        color: AppColors.lightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.lightBorder),
        ),
      ),
      dividerColor: AppColors.lightBorder,
      textTheme: _buildTextTheme(AppColors.lightText, AppColors.lightText2),
      extensions: [
        AppThemeExtension(
          bg: AppColors.lightBg,
          surface: AppColors.lightSurface,
          card: AppColors.lightCard,
          border: AppColors.lightBorder,
          text: AppColors.lightText,
          text2: AppColors.lightText2,
          text3: AppColors.lightText3,
          accent: accent,
        ),
      ],
    );
  }

  // ── Luxury Theme ─────────────────────────────────────────────
  static ThemeData _luxuryTheme(Color accent) {
    final lux = _darkTheme(AppColors.luxAccent).copyWith(
      scaffoldBackgroundColor: AppColors.luxBg,
      cardColor: AppColors.luxCard,
      extensions: [
        AppThemeExtension(
          bg: AppColors.luxBg,
          surface: AppColors.luxSurface,
          card: AppColors.luxCard,
          border: AppColors.luxBorder,
          text: AppColors.darkText,
          text2: AppColors.darkText2,
          text3: AppColors.darkText3,
          accent: AppColors.luxAccent,
        ),
      ],
    );
    return lux;
  }

  // ── Sports Theme ─────────────────────────────────────────────
  static ThemeData _sportsTheme(Color accent) {
    final sp = _darkTheme(AppColors.sportsAccent).copyWith(
      scaffoldBackgroundColor: AppColors.sportsBg,
      cardColor: AppColors.sportsCard,
      extensions: [
        AppThemeExtension(
          bg: AppColors.sportsBg,
          surface: AppColors.sportsSurface,
          card: AppColors.sportsCard,
          border: AppColors.sportsBorder,
          text: AppColors.darkText,
          text2: AppColors.darkText2,
          text3: AppColors.darkText3,
          accent: AppColors.sportsAccent,
        ),
      ],
    );
    return sp;
  }

  static TextTheme _buildTextTheme(Color primary, Color secondary) {
    return TextTheme(
      displayLarge: TextStyle(color: primary, fontFamily: 'Cairo', fontWeight: FontWeight.w800),
      displayMedium: TextStyle(color: primary, fontFamily: 'Cairo', fontWeight: FontWeight.w700),
      displaySmall: TextStyle(color: primary, fontFamily: 'Cairo', fontWeight: FontWeight.w700),
      headlineLarge: TextStyle(color: primary, fontFamily: 'Cairo', fontWeight: FontWeight.w700),
      headlineMedium: TextStyle(color: primary, fontFamily: 'Cairo', fontWeight: FontWeight.w700),
      headlineSmall: TextStyle(color: primary, fontFamily: 'Cairo', fontWeight: FontWeight.w700),
      titleLarge: TextStyle(color: primary, fontFamily: 'Cairo', fontWeight: FontWeight.w700),
      titleMedium: TextStyle(color: primary, fontFamily: 'Cairo', fontWeight: FontWeight.w600),
      titleSmall: TextStyle(color: secondary, fontFamily: 'Cairo', fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(color: primary, fontFamily: 'Cairo'),
      bodyMedium: TextStyle(color: primary, fontFamily: 'Cairo'),
      bodySmall: TextStyle(color: secondary, fontFamily: 'Cairo', fontSize: 12),
      labelLarge: TextStyle(color: primary, fontFamily: 'Cairo', fontWeight: FontWeight.w600),
      labelMedium: TextStyle(color: secondary, fontFamily: 'Cairo'),
      labelSmall: TextStyle(color: secondary, fontFamily: 'Cairo', fontSize: 11),
    );
  }
}

// ── Theme Extension for custom colors ─────────────────────────
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  final Color bg;
  final Color surface;
  final Color card;
  final Color border;
  final Color text;
  final Color text2;
  final Color text3;
  final Color accent;

  const AppThemeExtension({
    required this.bg,
    required this.surface,
    required this.card,
    required this.border,
    required this.text,
    required this.text2,
    required this.text3,
    required this.accent,
  });

  @override
  ThemeExtension<AppThemeExtension> copyWith({
    Color? bg, Color? surface, Color? card, Color? border,
    Color? text, Color? text2, Color? text3, Color? accent,
  }) {
    return AppThemeExtension(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      card: card ?? this.card,
      border: border ?? this.border,
      text: text ?? this.text,
      text2: text2 ?? this.text2,
      text3: text3 ?? this.text3,
      accent: accent ?? this.accent,
    );
  }

  @override
  ThemeExtension<AppThemeExtension> lerp(
      ThemeExtension<AppThemeExtension>? other, double t) {
    if (other is! AppThemeExtension) return this;
    return AppThemeExtension(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      card: Color.lerp(card, other.card, t)!,
      border: Color.lerp(border, other.border, t)!,
      text: Color.lerp(text, other.text, t)!,
      text2: Color.lerp(text2, other.text2, t)!,
      text3: Color.lerp(text3, other.text3, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
    );
  }
}
