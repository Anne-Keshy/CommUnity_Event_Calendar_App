import 'package:community/models/event.dart';
import 'package:community/services/api_service.dart';
import 'package:community/services/auth_service.dart';
import 'package:community/screens/create_event_screen.dart';
import 'package:community/screens/edit_event_screen.dart';
import 'package:community/widgets/organizer_event_card.dart';
import 'package:community/screens/event_stats_screen.dart';
import 'package:community/screens/social_media_settings_screen.dart';
import 'package:community/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';

class OrganizerDashboardScreen extends StatefulWidget {
  const OrganizerDashboardScreen({super.key});

  @override
  State<OrganizerDashboardScreen> createState() =>
      _OrganizerDashboardScreenState();
}

class _OrganizerDashboardScreenState extends State<OrganizerDashboardScreen>
    with SingleTickerProviderStateMixin {
  late Future<List<Event>> _organizerEventsFuture;
  late Future<List<dynamic>> _feedbacksFuture;
  late Future<Map<String, dynamic>> _rsvpStatsFuture;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _organizerEventsFuture = ApiService().getOrganizerEvents();
    _feedbacksFuture = ApiService().getFeedbacksForOrganizer();
    _rsvpStatsFuture = ApiService().getOrganizerRsvpStats();
    _tabController = TabController(length: 3, vsync: this);
  }

  Future<void> _refreshEvents() async {
    setState(() {
      // Re-fetch the events and update the future
      _organizerEventsFuture = ApiService().getOrganizerEvents();
    });
  }

  Future<void> _refreshFeedbacks() async {
    setState(() {
      // Re-fetch the feedbacks and update the future
      _feedbacksFuture = ApiService().getFeedbacksForOrganizer();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.gradientBackground,
        ),
        child: Column(
          children: [
            Container(
              decoration: AppTheme.glassmorphismDecoration,
              padding: const EdgeInsets.only(
                  top: 50, left: 16, right: 16, bottom: 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "My Dashboard",
                          style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings, color: Colors.white),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const SocialMediaSettingsScreen()),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout, color: Colors.white),
                        onPressed: () async {
                          await AuthService().logout();
                          if (!mounted) return;
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                                builder: (_) => const LoginScreen()),
                            (route) => false,
                          );
                        },
                      ),
                    ],
                  ),
                  TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(text: 'Events'),
                      Tab(text: 'Feedbacks'),
                      Tab(text: 'RSVP Stats'),
                    ],
                    labelStyle: GoogleFonts.poppins(color: Colors.white),
                    unselectedLabelStyle:
                        GoogleFonts.poppins(color: Colors.white70),
                    indicatorColor: Colors.white,
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Events Tab
                  RefreshIndicator(
                    onRefresh: _refreshEvents,
                    child: FutureBuilder<List<Event>>(
                      future: _organizerEventsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError ||
                            !snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          return const Center(
                            child: Text(
                              "You haven't created any events yet.",
                              style: TextStyle(
                                  fontSize: 16, color: Colors.white70),
                            ),
                          );
                        }

                        final events = snapshot.data!;

                        return ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: events.length,
                          itemBuilder: (context, index) {
                            final event = events[index];
                            return FutureBuilder<Map<String, dynamic>>(
                              future: ApiService().getEventStats(event.id),
                              builder: (context, statsSnapshot) {
                                final rsvpCount =
                                    statsSnapshot.data?['rsvp_count'] ?? 0;
                                return OrganizerEventCard(
                                  event: event,
                                  rsvpCount: rsvpCount,
                                  onEdit: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              EditEventScreen(event: event))),
                                  onViewStats: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => EventStatsScreen(
                                              eventId: event.id))),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                  // Feeds Tab
                  RefreshIndicator(
                    onRefresh: _refreshFeedbacks,
                    child: FutureBuilder<List<dynamic>>(
                      future: _feedbacksFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError ||
                            !snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          return const Center(
                            child: Text(
                              "No feedbacks yet.",
                              style: TextStyle(
                                  fontSize: 16, color: Colors.white70),
                            ),
                          );
                        }

                        final feedbacks = snapshot.data!;

                        return ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: feedbacks.length,
                          itemBuilder: (context, index) {
                            final feedback = feedbacks[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              color: Colors.white.withOpacity(0.9),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      feedback['event_title'] ?? 'Event',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      feedback['feedback'] ?? '',
                                      style: GoogleFonts.poppins(
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'By: ${feedback['attendee_name'] ?? 'Anonymous'}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  // RSVP Stats Tab
                  RefreshIndicator(
                    onRefresh: () async {
                      setState(() {
                        _rsvpStatsFuture = ApiService().getOrganizerRsvpStats();
                      });
                    },
                    child: FutureBuilder<Map<String, dynamic>>(
                      future: _rsvpStatsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError ||
                            !snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          return const Center(
                            child: Text(
                              "No RSVP statistics available.",
                              style: TextStyle(
                                  fontSize: 16, color: Colors.white70),
                            ),
                          );
                        }

                        final stats = snapshot.data!;
                        final totalEvents = stats['total_events'] ?? 0;
                        final totalRsvps = stats['total_rsvps'] ?? 0;
                        final averageRsvps = stats['average_rsvps'] ?? 0.0;
                        final eventStats = stats['event_stats'] ?? [];

                        return ListView(
                          padding: const EdgeInsets.all(16.0),
                          children: [
                            // Summary Cards
                            Row(
                              children: [
                                Expanded(
                                  child: Card(
                                    color: Colors.white.withOpacity(0.9),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        children: [
                                          Text(
                                            totalEvents.toString(),
                                            style: GoogleFonts.poppins(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.purple,
                                            ),
                                          ),
                                          Text(
                                            'Total Events',
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Card(
                                    color: Colors.white.withOpacity(0.9),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        children: [
                                          Text(
                                            totalRsvps.toString(),
                                            style: GoogleFonts.poppins(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green,
                                            ),
                                          ),
                                          Text(
                                            'Total RSVPs',
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Card(
                              color: Colors.white.withOpacity(0.9),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  children: [
                                    Text(
                                      averageRsvps.toStringAsFixed(1),
                                      style: GoogleFonts.poppins(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                    Text(
                                      'Average RSVPs per Event',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Event Details',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Event Stats List
                            ...eventStats.map<Widget>((event) {
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                color: Colors.white.withOpacity(0.9),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        event['title'] ?? 'Event',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(Icons.people,
                                              size: 16, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${event['rsvp_count'] ?? 0} RSVPs',
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateEventScreen()),
          );
          if (!mounted) return;
          _refreshEvents(); // Refresh after creating event
        },
        backgroundColor: Colors.white,
        tooltip: 'Create Event',
        child: const Icon(Icons.add, color: Colors.purple),
      ),
    );
  }
}
