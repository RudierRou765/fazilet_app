import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/prayer_time.dart';

/// Notification Service — High-precision prayer alerts
/// Manages scheduling of Athan/Alarm notifications across Android & iOS
/// Zero AI-Slop: Resilient initialization, background-friendly, timezone-aware
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Initialize the notification engine
  Future<void> initialize() async {
    tz_data.initializeTimeZones();
    
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap
      },
    );

    // Request permissions for Android 13+
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }

  /// Schedule notifications for a list of prayer times
  Future<void> schedulePrayerNotifications(List<PrayerTime> prayerTimes) async {
    final settingsBox = Hive.box('settings');
    final notificationsEnabled = settingsBox.get('notificationsEnabled', defaultValue: true);
    
    // Clear existing schedules
    await _notificationsPlugin.cancelAll();

    if (!notificationsEnabled) return;

    for (int i = 0; i < prayerTimes.length; i++) {
      final prayer = prayerTimes[i];
      final scheduledDate = _parsePrayerTimeToTZ(prayer);

      if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
        continue;
      }

      final soundType = settingsBox.get('notificationSoundType', defaultValue: 'standard');

      await _notificationsPlugin.zonedSchedule(
        i,
        'Namaz Vakti: ${prayer.name}',
        '${prayer.name} vakti girdi. Huzura davetlisiniz.',
        scheduledDate,
        _getNotificationDetails(prayer.name, soundType),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: prayer.name,
      );
    }
  }

  /// Convert PrayerTime model to Timezone-aware DateTime
  tz.TZDateTime _parsePrayerTimeToTZ(PrayerTime prayer) {
    // Assumes prayer.date is 'yyyy-MM-dd' and prayer.time is 'HH:mm'
    final dateTime = DateTime.parse('${prayer.date} ${prayer.time}');
    return tz.TZDateTime.from(dateTime, tz.local);
  }

  /// Configure notification visuals and sound per prayer
  NotificationDetails _getNotificationDetails(String prayerName, String soundType) {
    final useAthan = soundType == 'athan';
    
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'prayer_alerts',
        'Prayer Alerts',
        channelDescription: 'Notifications for Fazilet prayer times',
        importance: Importance.max,
        priority: Priority.high,
        sound: useAthan ? const RawResourceAndroidNotificationSound('athan') : null,
        enableVibration: true,
        category: AndroidNotificationCategory.alarm,
      ),
      iOS: DarwinNotificationDetails(
        sound: useAthan ? 'athan.aiff' : null,
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  /// Test notification for immediate verification
  Future<void> showInstantNotification() async {
    await _notificationsPlugin.show(
      999,
      'Fazilet Test',
      'Bildirim sistemi başarıyla kuruldu.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'test_channel',
          'Test Alerts',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }
}
