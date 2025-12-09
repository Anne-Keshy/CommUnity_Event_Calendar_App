import 'package:community/models/event.dart';
import 'package:community/widgets/event_card.dart';
import 'package:community/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:community/services/recommendation_service.dart';
import 'package:community/widgets/recommendation_panel.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:community/services/api_service.dart';
import '../theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

enum _ViewMode { list, map }

class _HomeScreenState extends State<HomeScreen> {
  String _searchQuery = '';
  _ViewMode _viewMode = _ViewMode.list;
  Event? _selectedEvent;
  CameraPosition? _currentCameraPosition;

  void _toggleViewMode() {
    setState(() => _viewMode =
        _viewMode == _ViewMode.list ? _ViewMode.map : _ViewMode.list);
  }

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _fetchEvents();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Handle case where location services are disabled.
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentCameraPosition = CameraPosition(
            target: LatLng(position.latitude, position.longitude), zoom: 14);
      });
    } catch (e) {
      debugPrint("Error getting current location: $e");
    }
  }

  Future<void> _fetchEvents() async {
    try {
      final events = await ApiService().getEvents(
        latitude: _currentCameraPosition?.target.latitude ?? -1.286389,
        longitude: _currentCameraPosition?.target.longitude ?? 36.817223,
      );
      final box = Hive.box<Event>('eventsBox');
      await box.clear();
      for (final event in events) {
        await box.put(event.id, event);
      }
    } catch (e) {
      debugPrint("Error fetching events: $e");
    }
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
            // Custom App Bar with Glassmorphism
            Container(
              decoration: AppTheme.glassmorphismDecoration,
              padding: const EdgeInsets.only(
                  top: 50, left: 16, right: 16, bottom: 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search events by name or location...',
                        hintStyle: TextStyle(color: Colors.white70),
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.search, color: Colors.white70),
                        filled: true,
                        fillColor: AppTheme.glassWhite,
                      ),
                      onChanged: (query) {
                        setState(() {
                          _searchQuery = query;
                        });
                      },
                      onSubmitted: (query) async {
                        // Record search terms for recommendations
                        try {
                          await RecommendationService().recordSearch(query);
                        } catch (_) {}
                      },
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                        _viewMode == _ViewMode.list
                            ? Icons.map_outlined
                            : Icons.list,
                        color: Colors.white),
                    onPressed: _toggleViewMode,
                  ),
                  IconButton(
                    icon: const Icon(Icons.person_outline, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ProfileScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: ValueListenableBuilder<Box<Event>>(
                valueListenable: Hive.box<Event>('eventsBox').listenable(),
                builder: (context, box, _) {
                  final events = box.values.toList();

                  if (events.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.event_busy,
                              size: 60, color: Colors.white70),
                          const SizedBox(height: 16),
                          Text("No events found nearby.",
                              style: GoogleFonts.poppins(
                                  fontSize: 16, color: Colors.white70)),
                        ],
                      ),
                    );
                  }

                  // Filter events based on search query
                  final filteredEvents = events.where((event) {
                    final titleLower = event.title.toLowerCase();
                    final locationLower = event.locationAddress.toLowerCase();
                    final searchLower = _searchQuery.toLowerCase();
                    return titleLower.contains(searchLower) ||
                        locationLower.contains(searchLower);
                  }).toList();

                  if (_viewMode == _ViewMode.list) {
                    return Column(
                      children: [
                        // Recommendation panel (attendees)
                        RecommendationPanel(
                            location: _currentCameraPosition?.target,
                            radiusKm: 20.0),
                        Expanded(child: _buildListView(filteredEvents)),
                      ],
                    );
                  } else {
                    return _buildMapView(filteredEvents);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListView(List<Event> events) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return EventCard(event: event);
      },
    );
  }

  Widget _buildMapView(List<Event> events) {
    final markers = events.map((event) {
      return Marker(
        markerId: MarkerId(event.id),
        position: event.location,
        infoWindow: InfoWindow(
          title: event.title,
          snippet: event.locationAddress,
        ),
        onTap: () {
          setState(() {
            _selectedEvent = event;
          });
        },
      );
    }).toSet();

    if (_currentCameraPosition == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: _currentCameraPosition ??
              const CameraPosition(
                  target: LatLng(-1.286389, 36.817223), zoom: 12),
          markers: markers,
          onTap: (_) {
            // Clear selection when tapping the map
            setState(() {
              _selectedEvent = null;
            });
          },
        ),
        if (_selectedEvent != null)
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: EventCard(event: _selectedEvent!).animate().slideY(
                begin: 1, end: 0, duration: 300.ms, curve: Curves.easeOut),
          ),
      ],
    );
  }
}
