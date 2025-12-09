import 'package:flutter/material.dart';
import 'package:community/services/recommendation_service.dart';
import 'package:community/services/settings_service.dart';
import 'package:community/widgets/mini_event_card.dart';
import 'package:community/models/event.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
// EventCard is not used by recommendation panel anymore; using MiniEventCard
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';

class RecommendationPanel extends StatefulWidget {
  final LatLng? location;
  final double radiusKm;
  const RecommendationPanel({super.key, this.location, this.radiusKm = 20.0});

  @override
  State<RecommendationPanel> createState() => _RecommendationPanelState();
}

class _RecommendationPanelState extends State<RecommendationPanel> {
  final RecommendationService _rec = RecommendationService();
  List<Event> _events = [];
  bool _loading = true;
  RecommendationMode _mode = RecommendationMode.balanced;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    // Load user mode preference
    try {
      _mode = await SettingsService().getRecommendationMode();
    } catch (_) {}

    final list = await _rec.getRecommendations(location: widget.location, radiusKm: widget.radiusKm, limit: 10);
    if (mounted) setState(() { _events = list; _loading = false; });
  }

  @override
  void didUpdateWidget(covariant RecommendationPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location != widget.location) {
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return SizedBox(height: 120, child: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)));
    }

    if (_events.isEmpty) {
      return SizedBox(
        height: 120,
        child: Center(child: Text('No recommendations yet — try searching or RSVP to events', style: GoogleFonts.poppins(color: Colors.white70))),
      );
    }

    return SizedBox(
      height: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recommended for you', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                // Mode toggle
                DropdownButton<RecommendationMode>(
                  value: _mode,
                  dropdownColor: AppTheme.primaryColor,
                  items: const [
                    DropdownMenuItem(value: RecommendationMode.balanced, child: Text('Balanced')),
                    DropdownMenuItem(value: RecommendationMode.nearby, child: Text('Nearby')),
                    DropdownMenuItem(value: RecommendationMode.interest, child: Text('Interest')),
                  ],
                  onChanged: (v) async {
                    if (v == null) return;
                    setState(() { _mode = v; _loading = true; });
                    await SettingsService().setRecommendationMode(v);
                    await _load();
                  },
                )
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              itemBuilder: (context, index) {
                final ev = _events[index];
                return SizedBox(
                  width: 260,
                  child: MiniEventCard(event: ev),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemCount: _events.length,
            ),
          ),
        ],
      ),
    );
  }
}
