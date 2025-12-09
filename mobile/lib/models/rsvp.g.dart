// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rsvp.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RSVPAdapter extends TypeAdapter<RSVP> {
  @override
  final int typeId = 2;

  @override
  RSVP read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RSVP(
      eventId: fields[0] as String,
      status: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, RSVP obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.eventId)
      ..writeByte(1)
      ..write(obj.status);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RSVPAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
