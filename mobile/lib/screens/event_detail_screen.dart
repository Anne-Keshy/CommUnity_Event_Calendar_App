import 'package:community/models/event.dart';
import 'package:flutter/material.dart';
import 'package:community/screens/photo_gallery_screen.dart';
import 'package:community/services/api_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class EventDetailScreen extends StatefulWidget {
  final String eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  _EventDetailScreenState createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  bool _isRsvped = false;

  @override
  void initState() {
    super.initState();
    _checkIfRsvped();
  }

  Future<void> _checkIfRsvped() async {
    // Check backend to see if the current user has already RSVP'd to this event.
    try {
      final user = await ApiService().getUserProfile();
      if (user != null) {
        // `User` model now includes `rsvpedEvents` parsed from the backend
        setState(() {
          _isRsvped = user.rsvpedEvents.contains(widget.eventId);
        });
        return;
      }
    } catch (e) {
      // Fall through to default behavior on error
      debugPrint('Failed to fetch user profile for RSVP check: $e');
    }

    // Fallback: assume not RSVP'd if we cannot determine
    setState(() {
      _isRsvped = false;
    });
  }

  Future<void> _rsvpToEvent() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username') ?? 'unknown_user';

    // Call the ApiService to RSVP
    final success = await ApiService().rsvpToEvent(
      eventId: widget.eventId,
      username: username,
    );

    if (success) {
      setState(() {
        _isRsvped = true;
      });
    } else {
      // The request was queued, but we can still give optimistic UI feedback.
      setState(() {
        _isRsvped = true;
      });
      // Optionally, show a toast/snackbar: "You're offline. Will RSVP when connection returns."
      debugPrint("Failed to RSVP. Request was queued.");
    }
    // Refresh backend state to ensure UI reflects authoritative status
    await _checkIfRsvped();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ValueListenableBuilder<Box<Event>>(
        valueListenable: Hive.box<Event>('eventsBox').listenable(),
        builder: (context, box, _) {
          final event = box.get(widget.eventId);

          if (event == null) {
            return const Center(
              child: Text("Event not found or has been removed."),
            );
          }

          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(event),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(
                        icon: Icons.calendar_today_outlined,
                        title: DateFormat('EEEE, MMMM d').format(event.date),
                        subtitle: DateFormat('h:mm a').format(event.date),
                      ),
                      const SizedBox(height: 20),
                      _buildInfoRow(
                        icon: Icons.location_on_outlined,
                        title: "Location",
                        subtitle: event.locationAddress,
                      ),
                      const SizedBox(height: 20),
                      _buildInfoRow(
                        icon: Icons.person_outline,
                        title: "Organizer",
                        subtitle: event.organizerId, // Will be a name later
                      ),
                      const Divider(height: 40, thickness: 1),
                      Text(
                        "About this event",
                        style: GoogleFonts.poppins(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        event.description,
                        style: const TextStyle(fontSize: 16, height: 1.5),
                      ),
                      const SizedBox(height: 30),
                      // Action Buttons
                      Column(
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isRsvped
                                  ? Colors.grey
                                  : const Color(0xFF6C5CE7),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _isRsvped ? null : _rsvpToEvent,
                            child: Text(
                              _isRsvped
                                  ? "You're Going!"
                                  : "RSVP to this Event",
                              style: GoogleFonts.poppins(
                                  fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ).animate().fade(delay: 300.ms).slideY(begin: 0.5),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.chat_bubble_outline),
                                  label: const Text("Chat"),
                                  onPressed: () {
                                    // TODO: Implement chat screen
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Chat feature coming soon!')),
                                    );
                                  },
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(0, 50),
                                    side:
                                        BorderSide(color: Colors.grey.shade300),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon:
                                      const Icon(Icons.photo_library_outlined),
                                  label: const Text("Gallery"),
                                  onPressed: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) => PhotoGalleryScreen(
                                                eventId: widget.eventId)));
                                  },
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(0, 50),
                                    side:
                                        BorderSide(color: Colors.grey.shade300),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                            ],
                          ).animate().fade(delay: 400.ms).slideY(begin: 0.5),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar(Event event) {
    return SliverAppBar(
      expandedHeight: 250.0,
      pinned: true,
      stretch: true,
      backgroundColor: const Color(0xFF6C5CE7),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          event.title,
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold, color: Colors.white),
        ),
        background: Container(
          color: Colors.grey.shade400,
          child: const Center(
            child: Icon(Icons.image, color: Colors.white, size: 80),
          ),
        ).animate().fade(),
        stretchModes: const [StretchMode.zoomBackground],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF6C5CE7), size: 28),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ],
          ),
        ),
      ],
    ).animate().fade(delay: 200.ms).slideX(begin: -0.2);
  }
}
