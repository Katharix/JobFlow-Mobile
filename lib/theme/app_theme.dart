import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color ink = Color(0xFF1E1E24);
  static const Color primary = Color(0xFF3F67DA);
  static const Color secondary = Color(0xFF6E7180);
  static const Color success = Color(0xFF23CE6B);
  static const Color warning = Color(0xFFFFA400);
  static const Color danger = Color(0xFFED474A);
  static const Color sand = Color(0xFFEDEFF7);
  static const Color mist = Color(0xFFFAFBFF);

  static ThemeData get lightTheme {
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: primary,
      secondary: secondary,
      tertiary: success,
      surface: Colors.white,
      error: danger,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: ink,
    );

    final base = ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
    );

    return base.copyWith(
      scaffoldBackgroundColor: mist,
      textTheme: GoogleFonts.manropeTextTheme(base.textTheme).copyWith(
        titleLarge: GoogleFonts.manrope(fontWeight: FontWeight.w700),
        titleMedium: GoogleFonts.manrope(fontWeight: FontWeight.w600),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: ink,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: primary.withOpacity(0.12),
        labelTextStyle: WidgetStatePropertyAll(
          GoogleFonts.manrope(fontWeight: FontWeight.w600, fontSize: 12, color: ink),
        ),
        iconTheme: const WidgetStatePropertyAll(IconThemeData(color: ink)),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: sand,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: sand,
        selectedColor: primary.withOpacity(0.15),
        labelStyle: GoogleFonts.manrope(fontSize: 12, color: ink),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
