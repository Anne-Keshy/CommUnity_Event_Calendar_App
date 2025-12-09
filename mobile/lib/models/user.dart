// Assuming LatLng is defined here or similar utility

class User {
  final String id;
  final String username;
  final String email;
  final String role;
  final String? firebaseUid;
  final String? photoUrl;
  final String? bio;
  final Map<String, dynamic>? homeLocation; // GeoJSON Point
  final List<String> following; // List of user IDs
  final List<String> followers; // List of user IDs
  final Map<String, String>? socialMedia;
  final List<String> rsvpedEvents; // List of event IDs the user has RSVP'd to
  final DateTime createdAt;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    this.firebaseUid,
    this.photoUrl,
    this.bio,
    this.homeLocation,
    this.following = const [],
    this.followers = const [],
    this.socialMedia,
    required this.createdAt,
    this.rsvpedEvents = const [],
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'], // Handle both _id and id from backend
      username: json['username'],
      email: json['email'],
      role: json['role'],
      firebaseUid: json['firebase_uid'],
      photoUrl: json['photo_url'],
      bio: json['bio'],
      homeLocation: json['home_location'], // Keep as dynamic map for now
      following: List<String>.from(json['following'] ?? []),
      followers: List<String>.from(json['followers'] ?? []),
      socialMedia: json['social_media'] != null
          ? Map<String, String>.from(json['social_media'])
          : null,
      rsvpedEvents: json['rsvped_events'] != null
          ? List<String>.from(json['rsvped_events'].map((e) => e.toString()))
          : [],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'username': username,
      'email': email,
      'role': role,
      'firebase_uid': firebaseUid,
      'photo_url': photoUrl,
      'bio': bio,
      'home_location': homeLocation,
      'following': following,
      'followers': followers,
      'social_media': socialMedia,
      'rsvped_events': rsvpedEvents,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
