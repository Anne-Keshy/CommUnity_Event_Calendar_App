import 'dart:math';
import 'package:hive/hive.dart';
import 'package:community/models/event.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:community/services/settings_service.dart';

class RecommendationService {
  RecommendationService._internal();
  static final RecommendationService _instance = RecommendationService._internal();
  factory RecommendationService() => _instance;

  // Keys for Hive boxes
  static const String _searchBox = 'rec_search_history';
  static const String _rsvpBox = 'rec_rsvps';

  Future<Box> _openBox(String name) async {
    if (Hive.isBoxOpen(name)) return Hive.box(name);
    return await Hive.openBox(name);
  }

  /// Record a user search keyword (simple frequency counting).
  Future<void> recordSearch(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return;
    final box = await _openBox(_searchBox);
    final int current = (box.get(q) as int?) ?? 0;
    await box.put(q, current + 1);
  }

  /// Record that the user RSVPed to an event.
  Future<void> recordRSVP(String eventId) async {
    if (eventId.isEmpty) return;
    final box = await _openBox(_rsvpBox);
    await box.put(eventId, DateTime.now().toIso8601String());
  }

  /// Clear stored recommendations (for testing).
  Future<void> clearAll() async {
    final s = await _openBox(_searchBox);
    final r = await _openBox(_rsvpBox);
    await s.clear();
    await r.clear();
  }

  /// Compute recommendations using local event cache and stored signals.
  /// - Prioritize events matching frequent search keywords
  /// - Boost events user RSVPed to previously
  /// - Prefer closer events within radiusKm
  Future<List<Event>> getRecommendations({LatLng? location, double radiusKm = 20.0, int limit = 10}) async {
    try {
      // Load stored signals
      final sbox = await _openBox(_searchBox);
      final rbox = await _openBox(_rsvpBox);

      // Build keyword list sorted by frequency
      final keywordEntries = sbox.toMap().entries.toList();
      keywordEntries.sort((a, b) => (b.value as int).compareTo(a.value as int));
      final keywords = keywordEntries.map((e) => e.key as String).toList();

      // Load events from Hive (if present)
      if (!Hive.isBoxOpen('eventsBox')) {
        // No cached events; return empty
        return [];
      }
      final eventsBox = Hive.box<Event>('eventsBox');
      final events = eventsBox.values.toList().cast<Event>();

      // Determine weights based on user settings
      final mode = await SettingsService().getRecommendationMode();
      double titleKwWeight = 3.0;
      double descKwWeight = 1.5;
      double rsvpBoost = 5.0;
      double proximityMaxBoost = 5.0;
      double freshnessBonus = 1.0;

      if (mode == RecommendationMode.nearby) {
        titleKwWeight = 1.5;
        descKwWeight = 0.8;
        rsvpBoost = 2.0;
        proximityMaxBoost = 8.0;
        freshnessBonus = 1.0;
      } else if (mode == RecommendationMode.interest) {
        titleKwWeight = 4.0;
        descKwWeight = 2.0;
        rsvpBoost = 8.0;
        proximityMaxBoost = 3.0;
        freshnessBonus = 1.5;
      }

      // Scoring
      final List<Map<String, dynamic>> scored = [];
      for (var ev in events) {
        double score = 0.0;

        // Keyword matching on title and description (higher weight for title)
        final title = ev.title.toLowerCase();
        final desc = ev.description.toLowerCase();
        for (int i = 0; i < keywords.length && i < 10; i++) {
          final kw = keywords[i];
          final weight = (11 - (i + 1)) / 10.0; // top keywords stronger
          if (title.contains(kw)) score += titleKwWeight * weight;
          if (desc.contains(kw)) score += descKwWeight * weight;
        }

        // RSVP boost
        if (rbox.containsKey(ev.id)) score += rsvpBoost;

        // Proximity score if location provided
        if (location != null) {
          final d = _distanceKm(location.latitude, location.longitude, ev.location.latitude, ev.location.longitude);
          if (d <= radiusKm) {
            // closer gets higher score
            score += (1 - (d / radiusKm)) * proximityMaxBoost;
          }
        }

        // Freshness bonus (events soon)
        final daysTo = ev.date.difference(DateTime.now()).inDays;
        if (daysTo >= 0 && daysTo <= 7) score += freshnessBonus; // upcoming

        scored.add({'event': ev, 'score': score});
      }

      scored.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));
      final results = scored.map((e) => e['event'] as Event).take(limit).toList();
      return results;
    } catch (e) {
      // On error return empty recommendations
      return [];
    }
  }

  double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const earthRadiusKm = 6371.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = sin(dLat/2) * sin(dLat/2) + cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) * sin(dLon/2) * sin(dLon/2);
    final c = 2 * atan2(sqrt(a), sqrt(1-a));
    return earthRadiusKm * c;
  }

  double _deg2rad(double deg) => deg * (pi / 180);
}
