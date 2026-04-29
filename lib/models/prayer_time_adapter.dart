import 'package:hive/hive.dart';
import 'prayer_time.dart';

class PrayerTimeAdapter extends TypeAdapter<PrayerTime> {
  @override
  final int typeId = 2;

  @override
  PrayerTime read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PrayerTime(
      name: fields[0] as String,
      time: fields[1] as String,
      date: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, PrayerTime obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.time)
      ..writeByte(2)
      ..write(obj.date);
  }
}
