import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Fazilet app theme configuration
/// Applies brand-guidelines: Poppins for headings, Lora for body
/// Colors: Dark #141413, Light #faf9f5, Accents #d97757, #6a9bcc, #788c5d

class FaziletTheme {
  // Brand color palette
  static const Color darkPrimary = Color(0xFF141413);   // Dark
  static const Color lightBackground = Color(0xFFfaf9f5); // Light
  static const Color accentPrimary = Color(0xFFd97757);   // Warm accent
  static const Color accentSecondary = Color(0xFF6a9bcc); // Cool accent
  static const Color accentTertiary = Color(0xFF788c5d);  // Green accent

  /// Light theme (default for Fazilet app)
  static ThemeData lightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: darkPrimary,
      scaffoldBackgroundColor: lightBackground,
      colorScheme: const ColorScheme.light(
        primary: darkPrimary,
        onPrimary: lightBackground,
        secondary: accentPrimary,
        onSecondary: lightBackground,
        background: lightBackground,
        onBackground: darkPrimary,
        surface: lightBackground,
        onSurface: darkPrimary,
      ),
      textTheme: TextTheme(
        // Headings use Poppins (brand-guidelines)
        displayLarge: GoogleFonts.poppins(
          color: darkPrimary,
          fontWeight: FontWeight.w700,
        ),
        displayMedium: GoogleFonts.poppins(
          color: darkPrimary,
          fontWeight: FontWeight.w600,
        ),
        displaySmall: GoogleFonts.poppins(
          color: darkPrimary,
          fontWeight: FontWeight.w600,
        ),
        headlineMedium: GoogleFonts.poppins(
          color: darkPrimary,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: GoogleFonts.poppins(
          color: darkPrimary,
          fontWeight: FontWeight.w500,
        ),
        titleLarge: GoogleFonts.poppins(
          color: darkPrimary,
          fontWeight: FontWeight.w500,
        ),
        // Body text uses Lora (brand-guidelines)
        bodyLarge: GoogleFonts.lora(
          color: darkPrimary,
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: GoogleFonts.lora(
          color: darkPrimary,
          fontWeight: FontWeight.w400,
        ),
        bodySmall: GoogleFonts.lora(
          color: darkPrimary,
          fontWeight: FontWeight.w400,
        ),
        labelLarge: GoogleFonts.poppins(
          color: darkPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkPrimary,
        foregroundColor: lightBackground,
        titleTextStyle: GoogleFonts.poppins(
          color: lightBackground,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accentPrimary,
        foregroundColor: lightBackground,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentPrimary,
          foregroundColor: lightBackground,
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: accentSecondary),
          foregroundColor: accentSecondary,
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentPrimary,
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500),
        ),
      ),
      cardTheme: CardThemeData(
        color: lightBackground,
        shadowColor: darkPrimary.withOpacity(0.1),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  /// Dark theme (optional, for potential dark mode support)
  static ThemeData darkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: lightBackground,
      scaffoldBackgroundColor: darkPrimary,
      colorScheme: const ColorScheme.dark(
        primary: lightBackground,
        onPrimary: darkPrimary,
        secondary: accentPrimary,
        onSecondary: darkPrimary,
        background: darkPrimary,
        onBackground: lightBackground,
        surface: Color(0xFF2a2a2a),
        onSurface: lightBackground,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.poppins(
          color: lightBackground,
          fontWeight: FontWeight.w700,
        ),
        displayMedium: GoogleFonts.poppins(
          color: lightBackground,
          fontWeight: FontWeight.w600,
        ),
        displaySmall: GoogleFonts.poppins(
          color: lightBackground,
          fontWeight: FontWeight.w600,
        ),
        headlineMedium: GoogleFonts.poppins(
          color: lightBackground,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: GoogleFonts.poppins(
          color: lightBackground,
          fontWeight: FontWeight.w500,
        ),
        titleLarge: GoogleFonts.poppins(
          color: lightBackground,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: GoogleFonts.lora(
          color: lightBackground,
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: GoogleFonts.lora(
          color: lightBackground,
          fontWeight: FontWeight.w400,
        ),
        bodySmall: GoogleFonts.lora(
          color: lightBackground,
          fontWeight: FontWeight.w400,
        ),
        labelLarge: GoogleFonts.poppins(
          color: lightBackground,
          fontWeight: FontWeight.w500,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkPrimary,
        foregroundColor: lightBackground,
        titleTextStyle: GoogleFonts.poppins(
          color: lightBackground,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accentPrimary,
        foregroundColor: lightBackground,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF2a2a2a),
        shadowColor: lightBackground.withOpacity(0.1),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
