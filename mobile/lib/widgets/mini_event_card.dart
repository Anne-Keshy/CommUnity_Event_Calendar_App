import 'package:flutter/material.dart';
import 'package:community/models/event.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:community/screens/event_detail_screen.dart';
import 'package:community/theme.dart';

class MiniEventCard extends StatelessWidget {
  final Event event;
  const MiniEventCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => EventDetailScreen(eventId: event.id))),
      child: Container(
        width: 260,
        decoration: AppTheme.glassmorphismDecoration,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(event.title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),
              Text(event.locationAddress, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${event.date.month}/${event.date.day} ${event.date.hour}:${event.date.minute.toString().padLeft(2, '0')}',
                    style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppTheme.primaryColor, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => EventDetailScreen(eventId: event.id))),
                    child: const Text('View', style: TextStyle(fontSize: 12)),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
