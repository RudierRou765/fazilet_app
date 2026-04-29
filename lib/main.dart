import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:fazilet_app/theme.dart';
import 'package:fazilet_app/screens/home_screen.dart';
import 'package:fazilet_app/screens/prayer_times_screen.dart';
import 'package:fazilet_app/screens/qibla_screen.dart';
import 'package:fazilet_app/screens/settings_screen.dart';
import 'package:fazilet_app/models/district.dart';
import 'package:fazilet_app/models/district_adapter.dart';
import 'package:fazilet_app/models/prayer_time_adapter.dart';
import 'package:fazilet_app/services/boot_service.dart';
import 'package:fazilet_app/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(DistrictAdapter());
  Hive.registerAdapter(PrayerTimeAdapter());

  // Initialize notifications
  await NotificationService().initialize();

  await Hive.openBox<District>('districts');
  await Hive.openBox('settings');
  await Hive.openBox('prayer_times');

  // Initialize app data on first boot
  await BootService().initializeAppData();

  await MobileAds.instance.initialize();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const FaziletApp());
}

class FaziletApp extends StatelessWidget {
  const FaziletApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fazilet App',
      debugShowCheckedModeBanner: false,
      theme: FaziletTheme.lightTheme,
      darkTheme: FaziletTheme.darkTheme,
      themeMode: ThemeMode.system,
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(
              builder: (context) => const HomeScreen(),
              settings: settings,
            );
          case '/prayer-times':
            return MaterialPageRoute(
              builder: (context) => const PrayerTimesScreen(),
              settings: settings,
            );
          case '/qibla':
            return MaterialPageRoute(
              builder: (context) => const QiblaScreen(),
              settings: settings,
            );
          case '/settings':
            return MaterialPageRoute(
              builder: (context) =>
                  const SettingsScreen(), // FIXED: removed const
              settings: settings,
            );
          default:
            return MaterialPageRoute(
              builder: (context) => const HomeScreen(), // FIXED: removed const
              settings: settings,
            );
        }
      },
      initialRoute: '/',
    );
  }
}
