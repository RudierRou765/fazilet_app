import 'package:hive/hive.dart';
import 'district.dart';

class DistrictAdapter extends TypeAdapter<District> {
  @override
  final int typeId = 0;

  @override
  District read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return District(
      id: fields[0] as int,
      name: fields[1] as String,
      city: fields[2] as String,
      latitude: fields[3] as double,
      longitude: fields[4] as double,
      cityId: fields[5] as int,
      countryId: fields[6] as int,
      timeZone: fields[7] as String,
      fajrOffset: fields[8] as int,
      dhuhrOffset: fields[9] as int,
      asrOffset: fields[10] as int,
      maghribOffset: fields[11] as int,
      ishaOffset: fields[12] as int,
    );
  }

  @override
  void write(BinaryWriter writer, District obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.city)
      ..writeByte(3)
      ..write(obj.latitude)
      ..writeByte(4)
      ..write(obj.longitude)
      ..writeByte(5)
      ..write(obj.cityId)
      ..writeByte(6)
      ..write(obj.countryId)
      ..writeByte(7)
      ..write(obj.timeZone)
      ..writeByte(8)
      ..write(obj.fajrOffset)
      ..writeByte(9)
      ..write(obj.dhuhrOffset)
      ..writeByte(10)
      ..write(obj.asrOffset)
      ..writeByte(11)
      ..write(obj.maghribOffset)
      ..writeByte(12)
      ..write(obj.ishaOffset);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DistrictAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
