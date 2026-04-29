import 'package:hive/hive.dart';

@HiveType(typeId: 2)
class PrayerTime {
  @HiveField(0)
  final String name;
  @HiveField(1)
  final String time;
  @HiveField(2)
  final String date;

  PrayerTime({
    required this.name,
    required this.time,
    required this.date,
  });
}
