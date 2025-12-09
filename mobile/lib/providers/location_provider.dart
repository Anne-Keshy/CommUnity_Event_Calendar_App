import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../services/geolocation_service.dart';

final locationProvider =
    StateNotifierProvider<LocationNotifier, AsyncValue<Position?>>(
        (ref) => LocationNotifier());

class LocationNotifier extends StateNotifier<AsyncValue<Position?>> {
  final GeolocationService _geo = GeolocationService();
  LocationNotifier() : super(const AsyncValue.loading()) {
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    state = AsyncValue.data(await _geo.getLocationWithFallback());
  }

  Future<void> setHomeLocation(double lat, double lon) async {
    await _geo.saveHomeLocation(lat, lon);
    _loadLocation(); // Reload
  }
}
