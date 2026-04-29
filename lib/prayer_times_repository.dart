import 'package:adhan/adhan.dart' as adhan;
import 'package:intl/intl.dart';
import 'database_provider.dart';
import 'models/district.dart';
import 'models/prayer_time.dart';
import 'services/notification_service.dart';

/// Prayer time result with applied Fazilet offsets
class PrayerTimes {
  final DateTime fajr;
  final DateTime dhuhr;
  final DateTime asr;
  final DateTime maghrib;
  final DateTime isha;
  final District district;

  const PrayerTimes({
    required this.fajr,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.district,
  });

  /// Get prayer time by name
  DateTime timeForPrayer(String prayer) {
    switch (prayer.toLowerCase()) {
      case 'fajr':
        return fajr;
      case 'dhuhr':
        return dhuhr;
      case 'asr':
        return asr;
      case 'maghrib':
        return maghrib;
      case 'isha':
        return isha;
      default:
        throw InvalidPrayerException('Unknown prayer: $prayer');
    }
  }

  /// Get all prayer names in order
  static List<String> get prayerNames =>
      ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];

  /// Format all times as a map (for UI consumption)
  Map<String, DateTime> toMap() => {
        'fajr': fajr,
        'dhuhr': dhuhr,
        'asr': asr,
        'maghrib': maghrib,
        'isha': isha,
      };
}

/// Prayer Times Repository
/// Offline-first: queries local district DB, applies Fazilet methodology offsets
/// Zero AI-Slop: Production-ready, strongly-typed, comprehensive error handling
class PrayerTimesRepository {
  final DatabaseProvider _dbProvider;

  PrayerTimesRepository({DatabaseProvider? dbProvider})
      : _dbProvider = dbProvider ?? DatabaseProvider();

  /// Fetch district by ID from local SQLite database
  Future<District> getDistrictById(int districtId) async {
    try {
      final db = await _dbProvider.getDistrictDatabase();

      final results = await db.query(
        'districts',
        where: 'DistrictID = ?',
        whereArgs: [districtId],
        limit: 1,
      );

      if (results.isEmpty) {
        throw DistrictNotFoundException(
          'District with ID $districtId not found in local database',
        );
      }

      return District.fromMap(results.first);
    } catch (e, stackTrace) {
      if (e is DistrictNotFoundException) rethrow;
      throw PrayerTimesException(
        'Failed to fetch district $districtId: $e',
        stackTrace,
      );
    }
  }

  /// Search districts by name (for offline search)
  Future<List<District>> searchDistrictsByName(String query) async {
    try {
      final db = await _dbProvider.getDistrictDatabase();

      final results = await db.query(
        'districts',
        where: 'Name LIKE ?',
        whereArgs: ['%$query%'],
        orderBy: 'Name ASC',
        limit: 50,
      );

      return results.map((map) => District.fromMap(map)).toList();
    } catch (e, stackTrace) {
      throw PrayerTimesException(
        'Failed to search districts: $e',
        stackTrace,
      );
    }
  }

  /// Get all districts (for initial load/hierarchical selection)
  Future<List<District>> getAllDistricts() async {
    try {
      final db = await _dbProvider.getDistrictDatabase();

      final results = await db.query(
        'districts',
        orderBy: 'CountryID, CityID, Name ASC',
      );

      return results.map((map) => District.fromMap(map)).toList();
    } catch (e, stackTrace) {
      throw PrayerTimesException(
        'Failed to fetch all districts: $e',
        stackTrace,
      );
    }
  }

  /// Calculate prayer times for a district on a specific date
  /// Base times are calculated astronomically, then Fazilet offsets are applied
  Future<PrayerTimes> calculatePrayerTimes({
    required int districtId,
    DateTime? date,
  }) async {
    try {
      final targetDate = date ?? DateTime.now();
      final district = await getDistrictById(districtId);

      final coordinates = adhan.Coordinates(district.latitude, district.longitude);
      final dateComponents = adhan.DateComponents.from(targetDate);
      final params = adhan.CalculationMethod.muslim_world_league.getParameters();
      params.madhab = adhan.Madhab.hanafi;

      final adhanTimes = adhan.PrayerTimes(
        coordinates,
        dateComponents,
        params,
      );

      final fajr = _applyOffset(adhanTimes.fajr, district.fajrOffset);
      final dhuhr = _applyOffset(adhanTimes.dhuhr, district.dhuhrOffset);
      final asr = _applyOffset(adhanTimes.asr, district.asrOffset);
      final maghrib = _applyOffset(adhanTimes.maghrib, district.maghribOffset);
      final isha = _applyOffset(adhanTimes.isha, district.ishaOffset);

      return PrayerTimes(
        fajr: fajr,
        dhuhr: dhuhr,
        asr: asr,
        maghrib: maghrib,
        isha: isha,
        district: district,
      );
    } catch (e, stackTrace) {
      if (e is DistrictNotFoundException) rethrow;
      throw PrayerTimesException(
        'Failed to calculate high-precision times for district $districtId: $e',
        stackTrace,
      );
    }
  }


  /// Apply offset (in seconds) to a base time
  DateTime _applyOffset(DateTime baseTime, int offsetSeconds) {
    return baseTime.add(Duration(seconds: offsetSeconds));
  }

  /// Get the next prayer time from current time
  Future<Map<String, dynamic>> getNextPrayer({
    required int districtId,
    DateTime? referenceTime,
  }) async {
    try {
      final now = referenceTime ?? DateTime.now();
      final prayerTimes = await calculatePrayerTimes(districtId: districtId);

      final times = prayerTimes.toMap();
      DateTime? nextTime;
      String? nextPrayer;

      for (final entry in times.entries) {
        if (entry.value.isAfter(now)) {
          if (nextTime == null || entry.value.isBefore(nextTime)) {
            nextTime = entry.value;
            nextPrayer = entry.key;
          }
        }
      }

      // If no next prayer today, get Fajr for tomorrow
      if (nextTime == null) {
        final tomorrowTimes = await calculatePrayerTimes(
          districtId: districtId,
          date: now.add(const Duration(days: 1)),
        );
        nextTime = tomorrowTimes.fajr;
        nextPrayer = 'fajr';
      }

      final durationUntil = nextTime.difference(now);

      return {
        'prayer': nextPrayer,
        'time': nextTime,
        'durationUntil': durationUntil,
        'allTimes': times,
      };
    } catch (e, stackTrace) {
      throw PrayerTimesException(
        'Failed to get next prayer: $e',
        stackTrace,
      );
    }
  }
  /// Refresh prayer notification schedules for the upcoming week
  Future<void> scheduleWeeklyNotifications(int districtId) async {
    try {
      final List<PrayerTime> weekSchedules = [];
      final now = DateTime.now();

      for (int i = 0; i < 7; i++) {
        final date = now.add(Duration(days: i));
        final times = await calculatePrayerTimes(districtId: districtId, date: date);
        final dateStr = DateFormat('yyyy-MM-dd').format(date);

        times.toMap().forEach((name, time) {
          weekSchedules.add(PrayerTime(
            name: name,
            time: DateFormat('HH:mm').format(time),
            date: dateStr,
          ));
        });
      }

      await NotificationService().schedulePrayerNotifications(weekSchedules);
    } catch (e, stackTrace) {
      throw PrayerTimesException(
        'Failed to schedule weekly notifications: $e',
        stackTrace,
      );
    }
  }
}

/// Custom exceptions
class DistrictNotFoundException implements Exception {
  final String message;
  DistrictNotFoundException(this.message);
  @override
  String toString() => 'DistrictNotFoundException: $message';
}

class PrayerTimesException implements Exception {
  final String message;
  final StackTrace? stackTrace;
  PrayerTimesException(this.message, this.stackTrace);
  @override
  String toString() => 'PrayerTimesException: $message';
}

class InvalidPrayerException implements Exception {
  final String message;
  InvalidPrayerException(this.message);
  @override
  String toString() => 'InvalidPrayerException: $message';
}
