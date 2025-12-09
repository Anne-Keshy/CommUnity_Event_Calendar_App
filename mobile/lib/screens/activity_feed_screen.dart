import 'package:community/services/api_service.dart';
import 'package:community/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/event.dart';

class ActivityFeedScreen extends StatefulWidget {
  const ActivityFeedScreen({super.key});

  @override
  State<ActivityFeedScreen> createState() => _ActivityFeedScreenState();
}

class _ActivityFeedScreenState extends State<ActivityFeedScreen> {
  late Future<List<dynamic>> _feedFuture;
  late Future<List<Event>> _eventsFuture;

  @override
  void initState() {
    super.initState();
    _feedFuture = ApiService().getActivityFeed();
    _eventsFuture = ApiService().getEvents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Activity Feed",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _feedFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.feed_outlined, size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("Your feed is empty.",
                      style: TextStyle(fontSize: 16, color: Colors.grey)),
                  Text("Follow organizers to see their events here!",
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final feedItems = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: feedItems.length,
            itemBuilder: (context, index) {
              final item = feedItems[index];
              final actorName = item['actor_name'] ?? 'Someone';
              final summary = item['summary'] ?? '';
              String timeText = '';
              try {
                if (item['timestamp'] != null) {
                  final dt = DateTime.parse(item['timestamp']);
                  timeText =
                      '${dt.month}/${dt.day}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
                }
              } catch (e) {
                timeText = item['timestamp']?.toString() ?? '';
              }

              return InkWell(
                onTap: () {
                  // If actor_id is present, navigate to their profile
                  if (item['actor_id'] != null) {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => ProfileScreen(userId: item['actor_id']),
                    ));
                    return;
                  }
                },
                child: Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 26,
                          child: Text(actorName.isNotEmpty
                              ? actorName[0].toUpperCase()
                              : 'U'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(actorName,
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              Text(summary,
                                  style: GoogleFonts.poppins(
                                      color: Colors.black87)),
                              const SizedBox(height: 8),
                              Text(timeText,
                                  style: GoogleFonts.poppins(
                                      fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
