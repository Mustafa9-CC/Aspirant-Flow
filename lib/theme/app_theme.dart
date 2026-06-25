import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const Color medicalTeal = Color(0xFF009688); // Teal 500
  static const Color jeeNavy = Color(0xFF1A237E); // Indigo 900

  static const Color backgroundWhite = Color(0xFFFFFFFF);
  static const Color surfaceWhite = Color(0xFFF5F5F5);

  // NEET Theme (Medical Teal)
  static ThemeData get neetTheme {
    return _buildTheme(
      seedColor: medicalTeal,
      brightness: Brightness.light,
      name: 'NEET',
    );
  }

  // JEE Theme (Navy Blue)
  static ThemeData get jeeTheme {
    return _buildTheme(
      seedColor: jeeNavy,
      brightness: Brightness.light,
      name: 'JEE',
    );
  }

  // Midnight Theme (Premium Dark)
  static ThemeData get mangaTheme {
    return _buildTheme(
      seedColor: Colors.white,
      brightness: Brightness.dark,
      name: 'Midnight',
    );
  }

  // Pink Theme
  static ThemeData get pinkTheme {
    return _buildTheme(
      seedColor: Colors.pink,
      brightness: Brightness.light,
      name: 'Pink',
    );
  }

  // Yellow Theme
  static ThemeData get yellowTheme {
    return _buildTheme(
      seedColor: Colors.yellow,
      brightness: Brightness.light,
      name: 'Yellow',
    );
  }

  static ThemeData _buildTheme({
    required Color seedColor,
    required Brightness brightness,
    required String name,
  }) {
    final isDark = brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF000000) : backgroundWhite;
    final surfaceColor = isDark ? const Color(0xFF121212) : surfaceWhite;
    final onSurfaceColor = isDark ? Colors.white : Colors.black87;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
      surface: backgroundColor,
      onSurface: onSurfaceColor,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: backgroundColor,

      // Typography
      textTheme: GoogleFonts.outfitTextTheme().apply(
        bodyColor: onSurfaceColor,
        displayColor: onSurfaceColor,
      ),

      // Component Themes
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
              color: colorScheme.outlineVariant.withAlpha(isDark ? 40 : 51)),
        ),
        color: surfaceColor,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),

      appBarTheme: AppBarThemeData(
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.outfit(
          color: onSurfaceColor,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: onSurfaceColor),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isDark && seedColor == Colors.white ? Colors.white : seedColor,
          foregroundColor:
              isDark && seedColor == Colors.white ? Colors.black : Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor:
            isDark && seedColor == Colors.white ? Colors.white : seedColor,
        foregroundColor:
            isDark && seedColor == Colors.white ? Colors.black : Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: seedColor, width: 2),
        ),
        contentPadding: const EdgeInsets.all(18),
        labelStyle: GoogleFonts.outfit(color: onSurfaceColor.withAlpha(150)),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: backgroundColor,
        indicatorColor: seedColor.withAlpha(50),
        labelTextStyle: WidgetStateProperty.all(
            GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w500)),
      ),
    );
  }
}
