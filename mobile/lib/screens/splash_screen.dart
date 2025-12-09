import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';
// Import to access the initialization Future
import 'event_detail_screen.dart';

class SplashScreen extends StatefulWidget {
  final RemoteMessage? initialMessage;
  final Future<void> initialization;
  const SplashScreen(
      {super.key, this.initialMessage, required this.initialization});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _awaitInitialization();
  }

  void _awaitInitialization() async {
    try {
      debugPrint("SplashScreen: Starting initialization...");
      // Wait for all services to initialize
      await widget.initialization;
      if (!mounted) return;
      debugPrint("SplashScreen: Initialization completed successfully");

      // After initialization, decide where to navigate
      if (widget.initialMessage != null) {
        final eventId = widget.initialMessage!.data['event_id'] ??
            widget.initialMessage!.data['eventId'];
        if (eventId != null) {
            debugPrint(
              "SplashScreen: Navigating to EventDetailScreen with eventId: $eventId");
            if (!mounted) return;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => EventDetailScreen(eventId: eventId)));
          return; // Exit to avoid navigating to login
        }
      }
      // Default navigation if no initial message or eventId
          debugPrint("SplashScreen: Navigating to LoginScreen");
          if (!mounted) return;
          Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    } catch (e, stackTrace) {
          debugPrint("SplashScreen: Error during initialization: $e");
          debugPrint("StackTrace: $stackTrace");
      // Even if there's an error, try to navigate to login after a delay
      await Future.delayed(const Duration(seconds: 2));
          debugPrint("SplashScreen: Attempting to navigate to LoginScreen after error");
          if (mounted) {
          Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const LoginScreen()));
          }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6C5CE7),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/logo.png',
                    width: 160,
                    errorBuilder: (_, __, ___) => const Icon(Icons.celebration,
                        size: 120, color: Colors.white))
                .animate()
                .scale(duration: 1.5.seconds, curve: Curves.elasticOut),
            const SizedBox(height: 30),
            Text("CommUnity",
                    style: GoogleFonts.poppins(
                        fontSize: 52,
                        fontWeight: FontWeight.bold,
                        color: Colors.white))
                .animate()
                .shimmer(duration: 2.seconds),
            Text("Connect • Celebrate • Together",
                style:
                    GoogleFonts.poppins(fontSize: 18, color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}
