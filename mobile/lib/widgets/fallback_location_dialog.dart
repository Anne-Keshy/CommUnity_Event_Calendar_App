import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/location_provider.dart';
import '../services/api_service.dart';

class FallbackLocationDialog extends ConsumerWidget {
  const FallbackLocationDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textController = TextEditingController();
    return AlertDialog(
      title: const Text('Set Home Location?'),
      content: TextField(
        controller: textController,
        decoration: const InputDecoration(hintText: 'Enter address for geocoding'),
      ),
      actions: [
        TextButton(
          onPressed: () async {
              final places = await ApiService().searchPlaces(textController.text);
              if (!context.mounted) return;
              if (places.isNotEmpty) {
                final place = places.first;
                ref.read(locationProvider.notifier).setHomeLocation(double.parse(place['lat']), double.parse(place['lon']));
              }
              Navigator.pop(context);
            },
          child: const Text('Set'),
        ),
      ],
    );
  }
}