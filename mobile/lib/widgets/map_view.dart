import 'package:flutter/material.dart';
import '../models/event.dart';

class MapView extends StatelessWidget {
  final List<Event> events;
  const MapView({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Map view not implemented'),
    );
  }
}
