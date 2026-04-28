import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'theme.dart';
import 'user_preferences_adapter.dart';
import 'screens/home_screen.dart';
import 'screens/library_screen.dart';
import 'screens/qibla_screen.dart';
import 'screens/settings_screen.dart';

/// Fazilet App — Main Entry Point
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Google Fonts (cached for offline use)
  await GoogleFonts.pendingFonts();

  // Initialize Hive for local storage
  await _initializeHive();

  // Initialize Google Mobile Ads SDK
  await _initializeMobileAds();

  // Run the app
  runApp(const FaziletApp());
}

Future<void> _initializeHive() async {
  try {
    await Hive.initFlutter();

    // Register UserPreferences adapter
    Hive.registerAdapter(UserPreferencesAdapter());

    // Open typed box for UserPreferences
    if (!Hive.isBoxOpen('userPreferences')) {
      await Hive.openBox<UserPreferences>('userPreferences');
    }

    // Open books metadata box (key-value)
    if (!Hive.isBoxOpen('booksMetadata')) {
      await Hive.openBox('booksMetadata');
    }

    print('Hive initialized successfully');
  } catch (e) {
    print('Error initializing hive: $e');
  }
}

Future<void> _initializeMobileAds() async {
  try {
    await MobileAds.instance.initialize();
    print('Google Mobile Ads initialized successfully');
  } catch (e) {
    print('Error initializing Google Mobile Ads: $e');
  }
}

/// Root Fazilet Application Widget
class FaziletApp extends StatelessWidget {
  const FaziletApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fazilet',
      debugShowCheckedModeBanner: false,

      // Light theme (default for Fazilet)
      theme: FaziletTheme.lightTheme(),

      // Dark theme (optional, for future use)
      darkTheme: FaziletTheme.darkTheme(),

      // Use system theme mode
      themeMode: ThemeMode.system,

      // Home screen as initial route
      home: const HomeScreen(),

      // Use onGenerateRoute for flexible routing (NO const for screen instances)
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/home':
            return MaterialPageRoute(builder: (context) => HomeScreen());
          case '/library':
            return MaterialPageRoute(builder: (context) => LibraryScreen());
          case '/qibla':
            return MaterialPageRoute(builder: (context) => QiblaScreen());
          case '/settings':
            return MaterialPageRoute(builder: (context) => SettingsScreen());
          default:
            return MaterialPageRoute(builder: (context) => HomeScreen());
        }
      },

      // Error handling for unknown routes
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        );
      },
    );
  }
}

/// Helper to get user preferences from hive
class UserPreferencesHelper {
  static const String _boxName = 'userPreferences';

  static Box get _box => Hive.box(_boxName);

  // Selected District
  static int? get selectedDistrictId => _box.get('selectedDistrictId');
  static set selectedDistrictId(int? value) => _box.put('selectedDistrictId', value);

  // Notifications Enabled
  static bool get notificationsEnabled => _box.get('notificationsEnabled', defaultValue: true);
  static set notificationsEnabled(bool value) => _box.put('notificationsEnabled', value);

  // App Language
  static String get appLanguage => _box.get('appLanguage', defaultValue: 'tr');
  static set appLanguage(String value) => _box.put('appLanguage', value);

  // Bookmarks (stored as JSON string)
  static Map<String, dynamic> get bookmarks {
    final json = _box.get('bookmarks', defaultValue: '{}');
    if (json is String) {
      try {
        return Map<String, dynamic>.from(jsonDecode(json));
      } catch (_) {
        return {};
      }
    }
    return json is Map<String, dynamic> ? json : {};
  }

  static set bookmarks(Map<String, dynamic> value) => _box.put('bookmarks', jsonEncode(value));

  // Clear all preferences
  static Future<void> clear() => _box.clear();
}
