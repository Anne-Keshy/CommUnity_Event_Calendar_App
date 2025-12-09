import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert'; // ← THIS WAS MISSING! Fixed the error
import '../core/constants.dart';

class LocationShareScreen extends StatefulWidget {
  final String eventId;
  final String eventTitle;

  const LocationShareScreen({
    super.key,
    required this.eventId,
    required this.eventTitle,
  });

  @override
  State<LocationShareScreen> createState() => _LocationShareScreenState();
}

class _LocationShareScreenState extends State<LocationShareScreen> {
  GoogleMapController? mapController;
  Position? currentPosition;
  Timer? locationTimer;
  bool isSharing = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocationAndMoveCamera();
  }

  // Get initial location and center map
  Future<void> _getCurrentLocationAndMoveCamera() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location services are disabled.")),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location permission denied.")),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location permissions are permanently denied.")),
      );
      return;
    }

    try {
      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() => currentPosition = pos);

      mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(pos.latitude, pos.longitude),
          16.0,
        ),
      );
    } catch (e) {
      debugPrint("Error getting location: $e");
    }
  }

  // Toggle live location sharing
  void toggleSharing() async {
    setState(() => isSharing = !isSharing);

    if (isSharing) {
      // Start sending location every 5 seconds
      locationTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
        try {
          Position p = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );

          // Update UI marker (optional visual feedback)
          setState(() => currentPosition = p);

          final response = await http.post(
            Uri.parse("${Constants.baseUrl}/api/v1/events/${widget.eventId}/location/share"),
            headers: {"Content-Type": "application/json"},
            body: json.encode({
              "user_id": "francis123",     // Replace with real user ID later
              "username": "Francis",
              "lat": p.latitude,
              "lng": p.longitude,
            }),
          );

          if (response.statusCode == 200) {
            debugPrint("Location shared successfully");
          } else {
            debugPrint("Failed to share location: ${response.statusCode}");
          }
        } catch (e) {
          debugPrint("Error sharing location: $e");
          // Optionally show a message to user
        }
      });
    } else {
      // Stop sharing
      locationTimer?.cancel();
      locationTimer = null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Live location sharing stopped")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Live Location - ${widget.eventTitle}"),
        backgroundColor: const Color(0xFF6C5CE7),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(6.5244, 3.3792), // Lagos as fallback
              zoom: 15,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            onMapCreated: (GoogleMapController controller) {
              mapController = controller;
              if (currentPosition != null) {
                mapController?.animateCamera(
                  CameraUpdate.newLatLngZoom(
                    LatLng(currentPosition!.latitude, currentPosition!.longitude),
                    16.0,
                  ),
                );
              }
            },
          ),

          // Live Sharing Button
          Positioned(
            bottom: 100,
            left: 20,
            right: 20,
            child: ElevatedButton.icon(
              onPressed: toggleSharing,
              icon: Icon(isSharing ? Icons.stop : Icons.share_location),
              label: Text(
                isSharing ? "STOP SHARING" : "START SHARING LIVE LOCATION",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isSharing ? Colors.red : Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                textStyle: const TextStyle(fontSize: 16),
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),

          // Optional: Show current status
          if (isSharing)
            Positioned(
              top: 20,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, color: Colors.white, size: 12),
                    SizedBox(width: 8),
                    Text("LIVE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    locationTimer?.cancel();
    mapController?.dispose();
    super.dispose();
  }
}