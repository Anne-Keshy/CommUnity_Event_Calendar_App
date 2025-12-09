import 'package:hive/hive.dart';

@HiveType(typeId: 1)
class RSVP extends HiveObject {
  @HiveField(0) String eventId;
  @HiveField(1) String status;
  @HiveField(2) DateTime createdAt;

  RSVP({required this.eventId, required this.status, required this.createdAt});
}

class RSVPAdapter extends TypeAdapter<RSVP> {
  @override
  final int typeId = 1;

  @override
  RSVP read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RSVP(
      eventId: fields[0] as String,
      status: fields[1] as String,
      createdAt: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, RSVP obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.eventId)
      ..writeByte(1)
      ..write(obj.status)
      ..writeByte(2)
      ..write(obj.createdAt);
  }
}