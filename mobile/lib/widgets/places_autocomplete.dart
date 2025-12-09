import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import '../services/api_service.dart';

class PlacesAutocomplete extends StatelessWidget {
  final Function(Map<String, dynamic>) onSelected;
  const PlacesAutocomplete({super.key, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return TypeAheadField<Map<String, dynamic>>(
      suggestionsCallback: (pattern) async =>
          await ApiService().searchPlaces(pattern),
      itemBuilder: (ctx, suggestion) =>
          ListTile(title: Text(suggestion['display_name'] ?? '')),
      onSelected: onSelected,
    );
  }
}
