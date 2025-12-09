import 'package:hive/hive.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

part 'event.g.dart';

@HiveType(typeId: 1)
class Event {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final String description;
  @HiveField(3)
  final DateTime date;
  @HiveField(4)
  final String category;
  @HiveField(5)
  final String locationAddress;
  @HiveField(6)
  final LatLng location; // For map
  @HiveField(7)
  final String organizerId;
  @HiveField(8)
  final double? distanceKm;
  @HiveField(9)
  final double? geofenceRadius; // in meters

  const Event({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    this.category = '',
    required this.locationAddress,
    required this.location,
    required this.organizerId,
    this.distanceKm,
    this.geofenceRadius,
  });

  factory Event.fromJson(Map<String, dynamic> json) => Event(
        id: json['event_id'],
        title: json['title'],
        description: json['description'],
        date: DateTime.parse(json['date']),
        category: json['category'] ?? '',
        locationAddress: json['location_address'],
        location: LatLng(json['location']['coordinates'][1],
            json['location']['coordinates'][0]),
        organizerId: json['organizer_id'],
        distanceKm: json['distance_km'],
        geofenceRadius: (json['geofence_radius'] as num?)?.toDouble(),
      );
}
