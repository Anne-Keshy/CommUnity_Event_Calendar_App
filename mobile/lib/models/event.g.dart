// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EventAdapter extends TypeAdapter<Event> {
  @override
  final int typeId = 1;

  @override
  Event read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Event(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      date: fields[3] as DateTime,
      category: fields[4] as String,
      locationAddress: fields[5] as String,
      location: fields[6] as LatLng,
      organizerId: fields[7] as String,
      distanceKm: fields[8] as double?,
      geofenceRadius: fields[9] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, Event obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.category)
      ..writeByte(5)
      ..write(obj.locationAddress)
      ..writeByte(6)
      ..write(obj.location)
      ..writeByte(7)
      ..write(obj.organizerId)
      ..writeByte(8)
      ..write(obj.distanceKm)
      ..writeByte(9)
      ..write(obj.geofenceRadius);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
