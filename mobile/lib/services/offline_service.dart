import 'package:hive/hive.dart';
import '../models/event.dart';
import '../models/rsvp.dart';

class OfflineService {
  final Box<Event> _eventsBox = Hive.box<Event>('events');
  final Box<RSVP> _rsvpsBox = Hive.box<RSVP>('rsvps');

  void cacheEvents(List<Event> events) {
    for (var e in events) {
      _eventsBox.put(e.id, e);
    }
  }

  List<Event> getCachedEvents() => _eventsBox.values.toList();

  void cacheRSVP(RSVP rsvp) => _rsvpsBox.put(rsvp.eventId, rsvp);

  RSVP? getCachedRSVP(String eventId) => _rsvpsBox.get(eventId);

  Future<void> clearCache() async {
    await _eventsBox.clear();
    await _rsvpsBox.clear();
  }
}