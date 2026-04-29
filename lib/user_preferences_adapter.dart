import 'package:hive/hive.dart';

/// User Preferences Model (from PRD)
/// Stores: selectedDistrictId, bookmarks, notificationsEnabled, appLanguage
@HiveType(typeId: 0)
class UserPreferences extends HiveObject {
  @HiveField(0)
  int? selectedDistrictId;

  @HiveField(1)
  Map<String, dynamic> bookmarks = {};

  @HiveField(2)
  bool notificationsEnabled = true;

  @HiveField(3)
  String appLanguage = 'tr';

  @HiveField(4)
  String? defaultBookId;
}

/// Manually written Hive TypeAdapter (no code generation required)
class UserPreferencesAdapter extends TypeAdapter<UserPreferences> {
  @override
  final int typeId = 0;

  @override
  UserPreferences read(BinaryReader reader) {
    final numFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numFields; i++) {
      switch (reader.readByte()) {
        case 0:
          fields[0] = reader.read() as int?;
        case 1:
          fields[1] = Map<String, dynamic>.from(reader.read() as Map);
        case 2:
          fields[2] = reader.read() as bool;
        case 3:
          fields[3] = reader.read() as String;
        case 4:
          fields[4] = reader.read() as String?;
      }
    }
    final obj = UserPreferences()
      ..selectedDistrictId = fields[0] as int?
      ..bookmarks = fields[1] as Map<String, dynamic>? ?? {}
      ..notificationsEnabled = fields[2] as bool? ?? true
      ..appLanguage = fields[3] as String? ?? 'tr'
      ..defaultBookId = fields[4] as String?;
    return obj;
  }

  @override
  void write(BinaryWriter writer, UserPreferences obj) {
    writer.writeByte(5); // Number of fields
    writer.writeByte(0);
    writer.write(obj.selectedDistrictId);
    writer.writeByte(1);
    writer.write(obj.bookmarks);
    writer.writeByte(2);
    writer.write(obj.notificationsEnabled);
    writer.writeByte(3);
    writer.write(obj.appLanguage);
    writer.writeByte(4);
    writer.write(obj.defaultBookId);
  }
}
