import 'package:community/models/event.dart';
import 'package:community/services/api_service.dart';
import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';

class EventRepository {
  // Don't access the Hive box at import time; open/get it lazily inside methods.
  static Future<Box<Event>> _getEventsBox() async {
    if (Hive.isBoxOpen('eventsBox')) {
      return Hive.box<Event>('eventsBox');
    }
    return await Hive.openBox<Event>('eventsBox');
  }

  /// Fetches events from the API, clears the local cache,
  /// and populates it with the new data.
  ///
  /// After caching, it triggers a geofence sync.
  static Future<void> fetchAndCacheEvents() async {
    try {
      debugPrint("🔄 Fetching latest events from the server...");
      // Assuming getEvents() is added to ApiService
      final List<Event> events = await ApiService().getEvents();

      // Clear old data only after a successful fetch and populate the cache
      final box = await _getEventsBox();
      await box.clear();

      // Populate the cache with new events
      final Map<String, Event> eventMap = {for (var e in events) e.id: e};
      await box.putAll(eventMap);

      debugPrint("✅ Cached ${events.length} events locally.");

    } catch (e) {
      debugPrint("❌ Failed to fetch or cache events: $e");
      // The cache is no longer cleared on failure, preserving offline data.
    }
  }
}
