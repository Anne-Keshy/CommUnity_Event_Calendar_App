import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';
import '../models/event.dart';
import '../services/api_service.dart';

class EventRepository {
  final ApiService _apiService = ApiService();
  final Box<Event> _eventsBox = Hive.box<Event>('eventsBox');

  Future<void> fetchAndCacheEvents() async {
    try {
      final events = await _apiService.getEvents();
      await _eventsBox.clear();
      await _eventsBox.addAll(events);
    } catch (e) {
      debugPrint('Failed to fetch and cache events: $e');
      // Keep existing cached events if fetch fails
    }
  }
}
