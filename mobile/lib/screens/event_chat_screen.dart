import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EventChatScreen extends StatelessWidget {
  final String eventId;

  const EventChatScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Event Chat",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: Text(
          "Chat feature coming soon!",
          style: GoogleFonts.poppins(fontSize: 18),
        ),
      ),
    );
  }
}
