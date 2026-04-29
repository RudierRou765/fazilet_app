import 'package:hive/hive.dart';

@HiveType(typeId: 0)
class District extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String city;

  @HiveField(3)
  final double latitude;

  @HiveField(4)
  final double longitude;
  
  @HiveField(5)
  final int cityId;
  
  @HiveField(6)
  final int countryId;
  
  @HiveField(7)
  final String timeZone;
  
  @HiveField(8)
  final int fajrOffset;
  
  @HiveField(9)
  final int dhuhrOffset;
  
  @HiveField(10)
  final int asrOffset;
  
  @HiveField(11)
  final int maghribOffset;
  
  @HiveField(12)
  final int ishaOffset;

  District({
    required this.id,
    required this.name,
    required this.city,
    required this.latitude,
    required this.longitude,
    this.cityId = 0,
    this.countryId = 0,
    this.timeZone = 'UTC',
    this.fajrOffset = 0,
    this.dhuhrOffset = 0,
    this.asrOffset = 0,
    this.maghribOffset = 0,
    this.ishaOffset = 0,
  });

  factory District.fromMap(Map<String, dynamic> map) {
    return District(
      id: map['DistrictID'] as int,
      name: map['Name'] as String,
      city: map['Name'] as String, // Fallback
      cityId: map['CityID'] as int,
      countryId: map['CountryID'] as int,
      latitude: map['Latitude'] as double,
      longitude: map['Longitude'] as double,
      timeZone: map['TimeZone'] as String,
      fajrOffset: map['FajrOffset'] as int,
      dhuhrOffset: map['DhuhrOffset'] as int,
      asrOffset: map['AsrOffset'] as int,
      maghribOffset: map['MaghribOffset'] as int,
      ishaOffset: map['IshaOffset'] as int,
    );
  }
}
