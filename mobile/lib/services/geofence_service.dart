import 'package:community/models/event.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:geolocator/geolocator.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:community/services/api_service.dart';
import 'dart:math';

/// Callback function for the alarm manager
void geofenceCallback() {
  GeofenceService._checkGeofences();
}

class GeofenceService {
  static const int geofenceTaskId = 0;

  /// Initializes the background geofence checking service.
  static Future<void> initialize() async {
    await AndroidAlarmManager.initialize();
    await syncGeofences();
  }

  /// Clears all existing geofences and creates new ones from the Hive database.
  ///
  /// This should be called whenever the event data changes to ensure the
  /// background service is monitoring the correct locations.
  static Future<void> syncGeofences() async {
    try {
      // Cancel existing alarm
      await AndroidAlarmManager.cancel(geofenceTaskId);

      final eventsBox = Hive.box<Event>('eventsBox');
      if (eventsBox.isNotEmpty) {
        // Schedule periodic geofence checking
        await AndroidAlarmManager.periodic(
          const Duration(minutes: 15), // Check every 15 minutes
          geofenceTaskId,
          geofenceCallback,
          exact: true,
          wakeup: true,
        );
      }
      debugPrint("✅ Synced ${eventsBox.length} geofences with the database.");
    } catch (e) {
      debugPrint("❌ Failed to sync geofences: $e");
    }
  }

  /// Checks if the current location is within any geofence
  static Future<void> _checkGeofences() async {
    try {
      // Request location permission if needed
      LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint("❌ Location permission denied");
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint("❌ Location permission permanently denied");
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final eventsBox = Hive.box<Event>('eventsBox');
      for (var event in eventsBox.values) {
        double distance = _calculateDistance(
          position.latitude,
          position.longitude,
          event.location.latitude,
          event.location.longitude,
        );

        if (distance <= (event.geofenceRadius ?? 200)) {
          // User is within geofence - trigger arrival API call
          debugPrint("🎯 User entered geofence for event: ${event.title}");
          final prefs = await SharedPreferences.getInstance();
          final username = prefs.getString('username') ?? 'unknown_user';

          // Use the robust ApiService to handle the request
          await ApiService().postArrival(
            eventId: event.id,
            username: username,
          );
        }
      }
    } catch (e) {
      print("❌ Failed to check geofences: $e");
    }
  }

  /// Calculates distance between two points using Haversine formula
  static double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // Earth's radius in meters

    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }
}
