import 'package:hive/hive.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LatLngAdapter extends TypeAdapter<LatLng> {
  @override
  final int typeId = 10; // must not clash with others

  @override
  LatLng read(BinaryReader reader) {
    final double lat = reader.read() as double;
    final double lng = reader.read() as double;
    return LatLng(lat, lng);
  }

  @override
  void write(BinaryWriter writer, LatLng obj) {
    writer.write(obj.latitude);
    writer.write(obj.longitude);
  }
}
