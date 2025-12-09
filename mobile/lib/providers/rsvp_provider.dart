import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/rsvp.dart';
import '../services/api_service.dart';
import '../models/event.dart';
import 'ai_provider.dart';
import 'event_provider.dart' as ep;
import 'package:google_maps_flutter/google_maps_flutter.dart';

final rsvpProvider =
    StateNotifierProvider.family<RSVPNotifier, AsyncValue<RSVP?>, String>(
        (ref, eventId) {
  return RSVPNotifier(ref, eventId);
});

class RSVPNotifier extends StateNotifier<AsyncValue<RSVP?>> {
  final Ref ref;
  final String eventId;
  final ApiService _api = ApiService();

  RSVPNotifier(this.ref, this.eventId) : super(const AsyncValue.loading()) {
    _loadRSVP();
  }

  Future<void> _loadRSVP() async {
    // For simplicity, assume RSVP status is not cached, just set to null or default
    state = const AsyncValue.data(null);
  }

  Future<void> submit(String status) async {
    state = const AsyncValue.loading();
    try {
      final success = await _api.rsvpToEvent(
          eventId: eventId,
          username: 'current_user'); // Assuming username is handled
      if (success) {
        final rsvp = RSVP(eventId: eventId, status: status);
        state = AsyncValue.data(rsvp);

        // Trigger AI confirmation
        final ai = ref.read(aiProvider);
        final events = ref.read(ep.eventProvider).value ?? [];
        final event = events.firstWhere((e) => e.id == eventId,
            orElse: () => Event(
                id: '',
                title: '',
                description: '',
                date: DateTime.now(),
                locationAddress: '',
                location: const LatLng(0, 0),
                organizerId: ''));
        await ai.getConfirmation(status, event);
        // Show in UI via SnackBar (confirmation text currently ignored)
      } else {
        throw Exception('RSVP failed');
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}
