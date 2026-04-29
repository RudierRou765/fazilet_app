import 'package:flutter/material.dart';

class FaziletTheme {
  // Brand Colors - High Precision Palette
  static const Color darkPrimary = Color(0xFF141413);
  static const Color lightBackground = Color(0xFFfaf9f5);
  static const Color accentPrimary = Color(0xFFd97757);
  static const Color accentSecondary = Color(0xFF6a9bcc);
  static const Color accentTertiary = Color(0xFF788c5d);

  // Legacy/Helper Mappings
  static const Color primaryColor = accentPrimary;
  static const Color backgroundColor = lightBackground;
  static const Color surfaceColor = Colors.white;
  static const Color errorColor = Color(0xFFe74c3c);

  // Text Colors
  static const Color textPrimaryColor = darkPrimary;
  static const Color textSecondaryColor = Color(0xFF7f8c8d);
  static const Color textOnPrimaryColor = Colors.white;

  // Light Theme
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primaryColor,
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      primaryContainer: primaryColor,
      secondary: accentSecondary,
      secondaryContainer: accentSecondary,
      tertiary: accentTertiary,
      surface: surfaceColor,
      error: errorColor,
      onPrimary: textOnPrimaryColor,
      onSecondary: textOnPrimaryColor,
      onSurface: textPrimaryColor,
    ),
    scaffoldBackgroundColor: backgroundColor,
    appBarTheme: const AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 2,
      backgroundColor: primaryColor,
      foregroundColor: textOnPrimaryColor,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: textOnPrimaryColor,
      ),
      iconTheme: IconThemeData(
        color: textOnPrimaryColor,
      ),
    ),
    // FIXED: Using CardThemeData instead of CardTheme
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: surfaceColor,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: textOnPrimaryColor,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: primaryColor, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor.withValues(alpha: 0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorColor),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: surfaceColor,
      selectedItemColor: primaryColor,
      unselectedItemColor: textSecondaryColor,
      elevation: 8,
      type: BottomNavigationBarType.fixed,
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: textOnPrimaryColor,
      unselectedLabelColor: textOnPrimaryColor.withValues(alpha: 0.7),
      indicatorColor: textOnPrimaryColor,
      indicatorSize: TabBarIndicatorSize.tab,
    ),
    dividerTheme: DividerThemeData(
      color: primaryColor.withValues(alpha: 0.2),
      thickness: 1,
      space: 1,
    ),
    iconTheme: const IconThemeData(
      color: textPrimaryColor,
      size: 24,
    ),
    primaryIconTheme: const IconThemeData(
      color: textOnPrimaryColor,
      size: 24,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        color: textPrimaryColor,
      ),
      displayMedium: TextStyle(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        color: textPrimaryColor,
      ),
      displaySmall: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        color: textPrimaryColor,
      ),
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: textPrimaryColor,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: textPrimaryColor,
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: textPrimaryColor,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: textPrimaryColor,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textPrimaryColor,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textPrimaryColor,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textPrimaryColor,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textPrimaryColor,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: textSecondaryColor,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textPrimaryColor,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: textPrimaryColor,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: textSecondaryColor,
      ),
    ),
  );

  // Dark Theme
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: primaryColor,
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      primaryContainer: primaryColor,
      secondary: accentSecondary,
      secondaryContainer: accentSecondary,
      tertiary: accentTertiary,
      surface: Color(0xFF1e1e1e),
      error: errorColor,
      onPrimary: textOnPrimaryColor,
      onSecondary: textOnPrimaryColor,
      onSurface: Color(0xFFe0e0e0),
    ),
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 2,
      backgroundColor: Color(0xFF1e1e1e),
      foregroundColor: Color(0xFFe0e0e0),
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(0xFFe0e0e0),
      ),
      iconTheme: IconThemeData(
        color: Color(0xFFe0e0e0),
      ),
    ),
    // FIXED: Using CardThemeData instead of CardTheme
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: const Color(0xFF1e1e1e),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: textOnPrimaryColor,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: accentPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: accentPrimary,
        side: const BorderSide(color: accentPrimary, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2d2d2d),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor.withValues(alpha: 0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorColor),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1e1e1e),
      selectedItemColor: primaryColor,
      unselectedItemColor: Color(0xFF757575),
      elevation: 8,
      type: BottomNavigationBarType.fixed,
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: accentPrimary,
      unselectedLabelColor: Color(0xFF757575),
      indicatorColor: accentPrimary,
      indicatorSize: TabBarIndicatorSize.tab,
    ),
    dividerTheme: DividerThemeData(
      color: primaryColor.withValues(alpha: 0.3),
      thickness: 1,
      space: 1,
    ),
    iconTheme: const IconThemeData(
      color: Color(0xFFe0e0e0),
      size: 24,
    ),
    primaryIconTheme: const IconThemeData(
      color: accentPrimary,
      size: 24,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        color: Color(0xFFe0e0e0),
      ),
      displayMedium: TextStyle(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        color: Color(0xFFe0e0e0),
      ),
      displaySmall: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        color: Color(0xFFe0e0e0),
      ),
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: Color(0xFFe0e0e0),
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: Color(0xFFe0e0e0),
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: Color(0xFFe0e0e0),
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: Color(0xFFe0e0e0),
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Color(0xFFe0e0e0),
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFFe0e0e0),
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: Color(0xFFe0e0e0),
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: Color(0xFFe0e0e0),
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: Color(0xFF757575),
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFFe0e0e0),
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Color(0xFFe0e0e0),
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Color(0xFF757575),
      ),
    ),
  );
}
