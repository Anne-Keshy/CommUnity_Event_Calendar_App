import 'package:flutter/material.dart';

class RSVPButtons extends StatelessWidget {
  final String eventId;
  final String? currentStatus;
  final Function(String) onRSVP;

  const RSVPButtons({super.key, required this.eventId, this.currentStatus, required this.onRSVP});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: ['Yes', 'Maybe', 'No'].map((status) => GestureDetector(
          onTap: () => onRSVP(status),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: currentStatus == status ? Theme.of(context).primaryColor : null,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(status, style: TextStyle(color: currentStatus == status ? Colors.white : null)),
          ),
        )).toList(),
      ),
    );
  }
}