import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: const CameraPosition(target: LatLng(6.5244, 3.3792), zoom: 12),
      myLocationEnabled: true,
      markers: {
        const Marker(markerId: MarkerId("event"), position: LatLng(6.5244, 3.3792), infoWindow: InfoWindow(title: "Event Location")),
      },
    );
  }
}