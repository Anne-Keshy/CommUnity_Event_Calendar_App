import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GeolocationService {
  static const String _homeKey = 'home_location';

  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;  // Trigger fallback UI

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;  // Fallback
    }

    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  // FR-GEO-003: Fallback to cached home location
  Future<Position?> getLocationWithFallback() async {
    final pos = await getCurrentLocation();
    if (pos != null) return pos;

    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble('${_homeKey}_lat');
    final lon = prefs.getDouble('${_homeKey}_lon');
    if (lat != null && lon != null) {
      return Position(
        latitude: lat,
        longitude: lon,
        timestamp: DateTime.now(),
        accuracy: 0.0,
        altitude: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        altitudeAccuracy: 0.0,
      );
    }
    return null;  // Prompt UI for manual input
  }

  Future<void> saveHomeLocation(double lat, double lon) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('${_homeKey}_lat', lat);
    await prefs.setDouble('${_homeKey}_lon', lon);
  }
}