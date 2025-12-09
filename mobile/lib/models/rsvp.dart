import 'package:hive/hive.dart';

part 'rsvp.g.dart';

@HiveType(typeId: 2)
class RSVP {
  @HiveField(0)
  final String eventId;
  @HiveField(1)
  final String status;  // Yes/Maybe/No

  const RSVP({required this.eventId, required this.status});

  factory RSVP.fromJson(Map<String, dynamic> json) => RSVP(
        eventId: json['event_id'],
        status: json['status'],
      );
}