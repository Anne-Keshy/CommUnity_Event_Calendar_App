import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/event.dart';
import '../services/api_service.dart';
import 'location_provider.dart';
import 'ai_provider.dart';

final eventProvider =
    StateNotifierProvider<EventNotifier, AsyncValue<List<Event>>>((ref) {
  final location = ref.watch(locationProvider);
  return EventNotifier(
      ref, location.value?.latitude ?? 0, location.value?.longitude ?? 0);
});

class EventNotifier extends StateNotifier<AsyncValue<List<Event>>> {
  final Ref ref;
  final double lat;
  final double lon;
  final ApiService _api = ApiService();
  EventNotifier(this.ref, this.lat, this.lon)
      : super(const AsyncValue.loading()) {
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final events = await _api.getEvents(latitude: lat, longitude: lon);
      // FR-AI-001: Inject suggestions
      final ai = ref.read(aiProvider);
        await ai.getSuggestions('user123', events); // From auth (suggestions currently unused)
      return events;
    });
    if (state.hasError) state = const AsyncValue.data([]); // Offline fallback
  }

  Future<void> refresh(double radiusKm) async {
    // Call API with radius (FR-GEO-002)
    final events = await _api.getEvents(
        latitude: lat, longitude: lon, radiusKm: radiusKm);
    state = AsyncValue.data(events);
  }

  Future<void> createEvent(Map<String, dynamic> data) async {
    await _api.createEvent(
      title: data['title'],
      description: data['description'],
      date: data['date'],
      locationAddress: data['locationAddress'],
      location: data['location'],
    ); // FR-MGMT-001
    _fetchEvents(); // Refresh
  }
}
