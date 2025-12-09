import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:community/config/constants.dart';
import 'package:community/models/event.dart';
import 'package:community/models/user.dart'; // Import User model
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart'; // Correct Uuid import
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:community/services/recommendation_service.dart';

class ApiService {
  final http.Client _client;

  // Allow injecting a client for testing, otherwise use a default one.
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  // Lazily open/get the offline queue Hive box to avoid accessing it at import/constructor time.
  Future<Box<Map>> _getOfflineBox() async {
    if (Hive.isBoxOpen('offlineQueue')) {
      return Hive.box<Map>('offlineQueue');
    }
    return await Hive.openBox<Map>('offlineQueue');
  }

  /// A private helper to get authentication headers.
  Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token != null) {
      return {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      };
    }
    return {"Content-Type": "application/json"};
  }

  /// A private helper to make authenticated requests.
  Future<http.Response> _authenticatedRequest(String method, String url,
      {Map<String, dynamic>? body}) async {
    final fullUrl = "${Constants.baseUrl}$url";
    final headers = await _getAuthHeaders();
    switch (method.toUpperCase()) {
      case 'POST':
        return await _client.post(Uri.parse(fullUrl),
            headers: headers, body: body != null ? json.encode(body) : null);
      case 'PUT':
        return await _client.put(Uri.parse(fullUrl),
            headers: headers, body: body != null ? json.encode(body) : null);
      case 'DELETE':
        return await _client.delete(Uri.parse(fullUrl), headers: headers);
      default:
        return await _client.get(Uri.parse(fullUrl), headers: headers);
    }
  }

  /// Registers a new user.
  Future<User> register({
    required String username,
    required String email,
    required String password,
    String role = 'attendee',
  }) async {
    const url = "${Constants.baseUrl}/api/v1/auth/register";
    final body = {
      "username": username,
      "email": email,
      "password": password,
      "role": role,
    };

    // Check connectivity before attempting - guard against platform errors in tests
    try {
      final connectivityCheck = await Connectivity().checkConnectivity();
      bool isOffline = false;
      if (connectivityCheck is ConnectivityResult) {
        isOffline = connectivityCheck == ConnectivityResult.none;
      } else if (connectivityCheck is Iterable) {
        isOffline =
            (connectivityCheck as Iterable).contains(ConnectivityResult.none);
      }
      if (isOffline) {
        throw Exception(
            "No internet connection. Please check your network and try again.");
      }
    } catch (e) {
      // In test environments the platform channels may not be available.
      // Assume connectivity is present and continue; tests mock HTTP responses.
    }

    try {
      final response = await _client
          .post(
            Uri.parse(url),
            headers: {"Content-Type": "application/json"},
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 30)); // Add timeout

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', data['access_token']);
        try {
          final user = User.fromJson(data['user']);
          await prefs.setString(
              'user_role', user.role); // Save role for MainScreen
          debugPrint("✅ User registered and logged in successfully!");
          return user;
        } catch (e) {
          throw Exception(
              "Registration successful but failed to parse user data. Please contact support.");
        }
      } else {
        final errorData = json.decode(response.body);
        final errorMessage =
            errorData['message'] ?? 'Registration failed. Please try again.';
        throw Exception(errorMessage);
      }
    } on TimeoutException {
      throw Exception(
          "Request timed out. Please check your connection and try again.");
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception("An unexpected error occurred during registration: $e");
    }
  }

  /// Logs in a user.
  Future<User> login({
    required String email,
    required String password,
  }) async {
    const url = "${Constants.baseUrl}/api/v1/auth/login";
    final body = {
      "email": email,
      "password": password,
    };

    // Check connectivity before attempting - guard against platform errors in tests
    try {
      final connectivityCheck = await Connectivity().checkConnectivity();
      bool isOffline = false;
      if (connectivityCheck is ConnectivityResult) {
        isOffline = connectivityCheck == ConnectivityResult.none;
      } else if (connectivityCheck is Iterable) {
        isOffline =
            (connectivityCheck as Iterable).contains(ConnectivityResult.none);
      }
      if (isOffline) {
        throw Exception(
            "No internet connection. Please check your network and try again.");
      }
    } catch (e) {
      // In test environments the platform channels may not be available.
      // Assume connectivity is present and continue; tests mock HTTP responses.
    }

    try {
      final response = await _client
          .post(
            Uri.parse(url),
            headers: {"Content-Type": "application/json"},
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 30)); // Add timeout

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', data['access_token']);
        try {
          final user = User.fromJson(data['user']);
          await prefs.setString(
              'user_role', user.role); // Save role for MainScreen
          debugPrint("✅ User logged in successfully!");
          // Backend now returns full user object
          return user;
        } catch (e) {
          throw Exception(
              "Login successful but failed to parse user data. Please contact support.");
        }
      } else {
        final errorData = json.decode(response.body);
        final errorMessage =
            errorData['message'] ?? 'Login failed. Please try again.';
        throw Exception(errorMessage);
      }
    } on TimeoutException {
      throw Exception(
          "Request timed out. Please check your connection and try again.");
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception("An unexpected error occurred during login: $e");
    }
  }

  /// Simulates a forgot password request.
  Future<bool> forgotPassword({required String email}) async {
    const url = "${Constants.baseUrl}/api/v1/auth/forgot-password";
    final body = {"email": email};
    try {
      final response = await _client.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: json.encode(body),
      );
      if (response.statusCode == 200) {
        debugPrint("✅ Password reset email simulated successfully.");
        return true;
      } else {
        final errorData = json.decode(response.body);
        debugPrint("❌ Forgot password failed: ${errorData['message']}");
        return false;
      }
    } catch (e) {
      debugPrint("❌ Error during forgot password: $e");
      return false;
    }
  }

  /// Logs out the current user by clearing the JWT token.
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    debugPrint("✅ User logged out successfully.");
    // Optionally call backend logout endpoint if there's server-side session invalidation
    // Although with stateless JWTs, client-side token deletion is usually sufficient.
  }

  /// Gets the current user's profile.
  Future<User?> getUserProfile() async {
    const url = "${Constants.baseUrl}/api/v1/auth/user/me";
    final headers = await _getAuthHeaders();
    try {
      final response = await _client.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return User.fromJson(data);
      } else {
        debugPrint("❌ Failed to get user profile: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      debugPrint("❌ Error getting user profile: $e");
      return null;
    }
  }

  /// Fetch a public profile for a given user id.
  Future<User?> getUserById(String userId) async {
    final url = "${Constants.baseUrl}/api/v1/users/$userId";
    try {
      final response = await _client.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return User.fromJson(data);
      } else {
        debugPrint("❌ Failed to get user by id: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      debugPrint("❌ Error fetching user by id: $e");
      return null;
    }
  }

  /// Update the authenticated user's profile. `fields` may include
  /// `username`, `bio`, `photo_url`, or `home_location` ({lat, lon}).
  Future<User?> updateUserProfile(
      String userId, Map<String, dynamic> fields) async {
    final url = "${Constants.baseUrl}/api/v1/users/$userId";
    final headers = await _getAuthHeaders();
    try {
      final response = await _client.put(
        Uri.parse(url),
        headers: headers,
        body: json.encode(fields),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // API returns { message, user }
        if (data is Map && data['user'] != null) {
          return User.fromJson(data['user']);
        }
        return null;
      } else {
        debugPrint("❌ Failed to update profile: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      debugPrint("❌ Error updating profile: $e");
      return null;
    }
  }

  /// Upload a profile avatar for the authenticated user.
  Future<String?> uploadUserAvatar(String userId, String imagePath) async {
    final url = "${Constants.baseUrl}/api/v1/users/$userId/avatar";
    final headers = await _getAuthHeaders();
    var request = http.MultipartRequest('POST', Uri.parse(url));

    // Add authorization header if present
    if (headers.containsKey('Authorization')) {
      request.headers['Authorization'] = headers['Authorization']!;
    }

    try {
      request.files.add(await http.MultipartFile.fromPath('photo', imagePath));
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['photo_url'] as String?;
      } else {
        debugPrint('❌ Failed to upload avatar: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error uploading avatar: $e');
      return null;
    }
  }

  /// Convenience method: fetch events near the given lat/lon (default 20 km).
  Future<List<Event>> getEventsNearby(double latitude, double longitude,
      {double radiusKm = 20.0}) async {
    return await getEvents(
        latitude: latitude, longitude: longitude, radiusKm: radiusKm);
  }

  /// Changes the current user's password.
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    const url = "${Constants.baseUrl}/api/v1/auth/user/change-password";
    final headers = await _getAuthHeaders();
    final body = {
      "current_password": currentPassword,
      "new_password": newPassword,
    };
    try {
      final response = await _client.put(
        Uri.parse(url),
        headers: headers,
        body: json.encode(body),
      );
      if (response.statusCode == 200) {
        debugPrint("✅ Password changed successfully!");
        return true;
      } else {
        final errorData = json.decode(response.body);
        debugPrint("❌ Failed to change password: ${errorData['message']}");
        return false;
      }
    } catch (e) {
      debugPrint("❌ Error changing password: $e");
      return false;
    }
  }

  /// Updates the current user's home location.
  Future<bool> updateUserLocation({
    required double latitude,
    required double longitude,
  }) async {
    const url = "${Constants.baseUrl}/api/v1/auth/user/location";
    final headers = await _getAuthHeaders();
    final body = {
      "lat": latitude,
      "lon": longitude,
    };
    try {
      final response = await _client.put(
        Uri.parse(url),
        headers: headers,
        body: json.encode(body),
      );
      if (response.statusCode == 200) {
        debugPrint("✅ User location updated successfully!");
        return true;
      } else {
        debugPrint("❌ Failed to update user location: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      debugPrint("❌ Error updating user location: $e");
      return false;
    }
  }

  /// Verifies a Firebase ID token and gets the application's internal JWT.
  Future<User?> verifyFirebaseToken({required String firebaseIdToken}) async {
    const url = "${Constants.baseUrl}/api/v1/auth/verify-token";
    final body = {"token": firebaseIdToken};
    try {
      final response = await _client.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', data['access_token']);
        debugPrint("✅ Firebase token verified, user logged in.");
        return User(
            id: '',
            username: data['username'],
            email: '',
            role: data['role'],
            createdAt: DateTime.now());
      } else {
        final errorData = json.decode(response.body);
        debugPrint(
            "❌ Firebase token verification failed: ${errorData['message']}");
        return null;
      }
    } catch (e) {
      debugPrint("❌ Error during Firebase token verification: $e");
      return null;
    }
  }

  /// Posts an event arrival and queues it if the device is offline.
  Future<void> postArrival({
    required String eventId,
    required String username,
  }) async {
    final url = "${Constants.baseUrl}/api/v1/events/$eventId/arrival";
    final body = {"username": username};
    final headers = await _getAuthHeaders(); // Use auth if needed in the future

    try {
      final response = await _client.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode >= 400) {
        // Server error, queue the request for later
        throw Exception('Server error: ${response.statusCode}');
      }
      debugPrint("✅ Successfully sent arrival for event $eventId.");
    } catch (e) {
      debugPrint("❌ Network error. Queuing arrival for event $eventId.");
      // Save the failed request to the offline box with a unique key
      final box = await _getOfflineBox();
      await box.put(const Uuid().v4(), {
        'url': url,
        'headers': headers,
        'body': body,
      });
    }
  }

  /// Retries sending all requests stored in the offline queue.
  /// This should be triggered on app start and when network connectivity is restored.
  Future<void> retryQueuedRequests() async {
    // Try to detect connectivity; if platform check fails in tests assume connected.
    try {
      final connectivityCheck = await Connectivity().checkConnectivity();
      bool isOffline = false;
      if (connectivityCheck is ConnectivityResult) {
        isOffline = connectivityCheck == ConnectivityResult.none;
      } else if (connectivityCheck is Iterable) {
        isOffline =
            (connectivityCheck as Iterable).contains(ConnectivityResult.none);
      }
      if (isOffline) {
        // No network connection, do nothing.
        return;
      }
    } catch (e) {
      // Could not determine connectivity (e.g., in test environment). Assume connected.
    }

    final box = await _getOfflineBox();
    final offlineRequests = box.toMap();
    if (offlineRequests.isEmpty) {
      return; // Nothing to retry.
    }

    debugPrint(
        "🌐 Network connection detected. Retrying ${offlineRequests.length} queued requests...");

    for (var entry in offlineRequests.entries) {
      final String key = entry.key;
      final Map requestData = entry.value;
      final headers = Map<String, String>.from(requestData['headers'] ?? {});
      final httpMethod = requestData['method'] ?? 'POST'; // Default to POST

      try {
        http.Response response;
        if (httpMethod == 'PUT') {
          response = await _client.put(
            Uri.parse(requestData['url']),
            headers: headers,
            body: json.encode(requestData['body']),
          );
        } else if (httpMethod == 'DELETE') {
          response = await _client.delete(
            Uri.parse(requestData['url']),
            headers: headers,
            // DELETE requests typically don't have a body, but we pass an empty one if present
            body: requestData['body'] != null
                ? json.encode(requestData['body'])
                : null,
          );
        } else {
          // Default to POST for backward compatibility
          response = await _client.post(
            Uri.parse(requestData['url']),
            headers: headers,
            body: json.encode(requestData['body']),
          );
        }

        if (response.statusCode < 400) {
          // Request was successful, remove it from the queue.
          debugPrint(
              "✅ Successfully sent queued request for ${requestData['url']}.");
          await box.delete(key);
        }
      } catch (e) {
        debugPrint(
            "❌ Failed to retry request for ${requestData['url']}. Will try again later.");
      }
    }
  }

  /// Fetches a list of events from the backend.
  Future<List<Event>> getEvents({
    double? latitude,
    double? longitude,
    double? radiusKm,
    String? search,
  }) async {
    var url = "${Constants.baseUrl}/api/v1/events";
    final headers = await _getAuthHeaders();
    final queryParams = <String, String>{};
    if (latitude != null) queryParams['latitude'] = latitude.toString();
    if (longitude != null) queryParams['longitude'] = longitude.toString();
    queryParams['radius_km'] = radiusKm.toString();
    if (search != null) queryParams['search'] = search;
    if (queryParams.isNotEmpty) {
      url +=
          '?${queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')}';
    }
    try {
      final response = await _client.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> eventJson = json.decode(response.body)['events'];
        final events = eventJson.map((json) => Event.fromJson(json)).toList();
        return events;
      } else {
        throw Exception('Failed to load events: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint("❌ Failed to get events from API: $e");
      return []; // Return an empty list on failure
    }
  }

  /// Fetch server-side recommendations for the authenticated user.
  Future<List<Event>> getServerRecommendations(
      {double? latitude, double? longitude, double radiusKm = 20.0}) async {
    var url = "${Constants.baseUrl}/api/v1/events/recommend";
    final headers = await _getAuthHeaders();
    final queryParams = <String, String>{};
    if (latitude != null) queryParams['latitude'] = latitude.toString();
    if (longitude != null) queryParams['longitude'] = longitude.toString();
    queryParams['radius_km'] = radiusKm.toString();
    if (queryParams.isNotEmpty) {
      url +=
          '?${queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')}';
    }

    try {
      final response = await _client
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final List<dynamic> eventJson = json.decode(response.body)['events'];
        final events = eventJson.map((json) => Event.fromJson(json)).toList();
        return events;
      } else {
        debugPrint('❌ Failed to get recommendations: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ Error fetching recommendations: $e');
      return [];
    }
  }

  /// Search places using OpenStreetMap Nominatim service for autocomplete.
  /// Returns a list of place JSON objects with at least 'display_name', 'lat', 'lon'.
  Future<List<Map<String, dynamic>>> searchPlaces(String query,
      {int limit = 5}) async {
    if (query.trim().isEmpty) return [];
    final url = Uri.parse('https://nominatim.openstreetmap.org/search')
        .replace(queryParameters: {
      'q': query,
      'format': 'json',
      'addressdetails': '1',
      'limit': limit.toString(),
    });

    try {
      final response = await _client.get(url, headers: {
        'User-Agent': 'CommUnityApp/1.0 (you@example.com)',
      }).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        debugPrint('❌ Place search failed: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ Error searching places: $e');
      return [];
    }
  }

  /// RSVP to a specific event.
  Future<bool> rsvpToEvent({
    required String eventId,
    required String username,
  }) async {
    final url = "${Constants.baseUrl}/api/v1/events/$eventId/rsvp";
    final body = {"username": username};
    final headers = await _getAuthHeaders();

    try {
      final response = await _client.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode >= 400) {
        throw Exception('Server error: ${response.statusCode}');
      }
      // Record the RSVP locally to improve recommendations (best-effort)
      try {
        await RecommendationService().recordRSVP(eventId);
      } catch (_) {}
      return true;
    } catch (e) {
      debugPrint("❌ Failed to RSVP to event: $e");
      final box = await _getOfflineBox();
      await box.put(const Uuid().v4(), {
        'url': url,
        'headers': headers,
        'body': body,
      });
      return false;
    }
  }

  /// Follow a user or organizer.
  Future<bool> followUser(String userIdToFollow) async {
    final url = "${Constants.baseUrl}/api/v1/users/$userIdToFollow/follow";
    final headers = await _getAuthHeaders();

    try {
      final response = await _client.post(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode >= 400) {
        throw Exception('Server error: ${response.statusCode}');
      }
      return true;
    } catch (e) {
      debugPrint("❌ Failed to follow user: $e. Queuing request.");
      final box = await _getOfflineBox();
      await box.put(const Uuid().v4(), {
        'url': url,
        'headers': headers,
        'body': {}, // POST request with no body
      });
      return false;
    }
  }

  /// Unfollow a user or organizer.
  Future<bool> unfollowUser(String userIdToUnfollow) async {
    final url = "${Constants.baseUrl}/api/v1/users/$userIdToUnfollow/unfollow";
    final headers = await _getAuthHeaders();

    try {
      final response = await _client.post(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode >= 400) {
        throw Exception('Server error: ${response.statusCode}');
      }
      return true;
    } catch (e) {
      debugPrint("❌ Failed to unfollow user: $e. Queuing request.");
      final box = await _getOfflineBox();
      await box
          .put(const Uuid().v4(), {'url': url, 'headers': headers, 'body': {}});
      return false;
    }
  }

  /// Creates a new event.
  Future<bool> createEvent({
    required String title,
    required String description,
    required DateTime date,
    required String locationAddress,
    required LatLng location,
  }) async {
    const url = "${Constants.baseUrl}/api/v1/events";
    final headers = await _getAuthHeaders();
    final body = {
      "title": title,
      "description": description,
      "date": date.toIso8601String(),
      "location_address": locationAddress,
      "location": {
        "type": "Point",
        "coordinates": [location.longitude, location.latitude]
      }
    };

    try {
      final response = await _client.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode == 201) {
        debugPrint("✅ Event created successfully!");
        return true;
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint("❌ Error creating event: $e");
      final box = await _getOfflineBox();
      await box.put(const Uuid().v4(), {
        'url': url,
        'headers': headers,
        'body': body,
        'method': 'POST', // Specify the method
      });
      return false;
    }
  }

  /// Updates an existing event.
  Future<bool> updateEvent({
    required String eventId,
    required String title,
    required String description,
    required DateTime date,
    required String locationAddress,
    required LatLng location,
  }) async {
    final url = "${Constants.baseUrl}/api/v1/events/$eventId";
    final headers = await _getAuthHeaders();
    final body = {
      "title": title,
      "description": description,
      "date": date.toIso8601String(),
      "location_address": locationAddress,
      "location": {
        "type": "Point",
        "coordinates": [location.longitude, location.latitude]
      }
    };

    try {
      final response = await _client.put(
        Uri.parse(url),
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        debugPrint("✅ Event updated successfully!");
        return true;
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint("❌ Error updating event: $e");
      final box = await _getOfflineBox();
      await box.put(const Uuid().v4(), {
        'url': url,
        'headers': headers,
        'body': body,
        'method': 'PUT', // Specify the method
      });
      return false;
    }
  }

  /// Deletes an existing event.
  Future<bool> deleteEvent({
    required String eventId,
  }) async {
    final url = "${Constants.baseUrl}/api/v1/events/$eventId";
    final headers = await _getAuthHeaders();

    try {
      final response = await _client.delete(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        debugPrint("✅ Event deleted successfully!");
        return true;
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint("❌ Error deleting event: $e");
      final box = await _getOfflineBox();
      await box.put(const Uuid().v4(), {
        'url': url,
        'headers': headers,
        'method': 'DELETE', // Specify the method
        // No body for DELETE typically
      });
      return false;
    }
  }

  /// Fetches statistics for a specific event.
  Future<Map<String, int>> getEventStats(String eventId) async {
    final url = "${Constants.baseUrl}/api/v1/events/$eventId/stats";
    final headers = await _getAuthHeaders();
    try {
      final response = await _client.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'rsvpCount': data['rsvp_count'] ?? 0,
          'arrivalCount': data['arrival_count'] ?? 0,
        };
      } else {
        throw Exception('Failed to load event stats: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint("❌ Failed to get event stats from API: $e");
      return {}; // Return an empty map on failure
    }
  }

  /// Fetches the personalized activity feed for the current user.
  Future<List<dynamic>> getActivityFeed() async {
    const url = "${Constants.baseUrl}/api/v1/feed"; // Corrected URL prefix
    final headers = await _getAuthHeaders();
    try {
      final response = await _client.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        return json.decode(response.body)['feed'] as List<dynamic>;
      } else {
        debugPrint("❌ Failed to get activity feed: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Error getting activity feed: $e");
    }
    return []; // Return an empty list on failure
  }

  /// Fetches all photo URLs for an event.
  Future<List<String>> getEventPhotos(String eventId) async {
    final url = "${Constants.baseUrl}/api/v1/events/$eventId/photos";
    // Photos are often public, so auth may not be needed.
    // final headers = await _getAuthHeaders(); // Uncomment if authentication is required
    try {
      final response = await _client.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return List<String>.from(json.decode(response.body)['photos']);
      } else {
        debugPrint("❌ Failed to get event photos: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Error getting event photos: $e");
    }
    return [];
  }

  /// Upload a photo for a specific event.
  Future<bool> uploadEventPhoto(String eventId, String imagePath) async {
    final url = "${Constants.baseUrl}/api/v1/events/$eventId/photos";
    final headers = await _getAuthHeaders();
    var request = http.MultipartRequest('POST', Uri.parse(url));

    // Add headers to the multipart request
    // Note: MultipartRequest handles its own Content-Type, so avoid adding "Content-Type": "application/json"
    request.headers.addAll({
      "Authorization": headers["Authorization"] ?? "",
    });

    try {
      request.files.add(await http.MultipartFile.fromPath('photo', imagePath));
      var response = await request.send();

      if (response.statusCode == 201) {
        debugPrint("✅ Photo uploaded successfully!");
        return true;
      } else {
        final responseBody = await response.stream.bytesToString();
        debugPrint(
            "❌ Failed to upload photo. Status: ${response.statusCode}, Body: $responseBody");
        return false;
      }
    } catch (e) {
      debugPrint("❌ Error uploading photo: $e");
      return false;
    }
  }

  /// Fetches a list of events created by the current organizer.
  Future<List<Event>> getOrganizerEvents() async {
    const url = "${Constants.baseUrl}/api/v1/organizer/events";
    final headers = await _getAuthHeaders();
    try {
      final response = await _client.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> eventJson = json.decode(response.body)['events'];
        final events = eventJson.map((json) => Event.fromJson(json)).toList();
        return events;
      } else {
        throw Exception(
            'Failed to load organizer events: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint("❌ Failed to get organizer events from API: $e");
      return []; // Return an empty list on failure
    }
  }

  /// Fetches feedbacks for events organized by the current user.
  Future<List<dynamic>> getFeedbacksForOrganizer() async {
    const url = "${Constants.baseUrl}/api/v1/feedback/organizer";
    final headers = await _getAuthHeaders();
    try {
      final response = await _client.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        return json.decode(response.body)['feedbacks'] as List<dynamic>;
      } else {
        throw Exception('Failed to load feedbacks: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint("❌ Failed to get feedbacks from API: $e");
      return []; // Return an empty list on failure
    }
  }

  /// Submits feedback for an event.
  Future<void> submitFeedback(
      String eventId, int rating, String comment) async {
    final response = await _authenticatedRequest(
      'POST',
      '/api/v1/feedback/submit',
      body: {
        'event_id': eventId,
        'rating': rating,
        'comment': comment,
      },
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to submit feedback');
    }
  }

  /// Sends feedback to an organizer.
  Future<void> sendFeedbackToOrganizer(
      String organizerId, String message) async {
    final response = await _authenticatedRequest(
      'POST',
      '/api/v1/feedback/send-to-organizer',
      body: {
        'organizer_id': organizerId,
        'message': message,
      },
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to send feedback to organizer');
    }
  }

  /// Fetches RSVP statistics for the organizer's events.
  Future<Map<String, dynamic>> getOrganizerRsvpStats() async {
    const url = "${Constants.baseUrl}/api/v1/events/organizer/rsvp-stats";
    final headers = await _getAuthHeaders();
    try {
      final response = await _client.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to load RSVP stats: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint("❌ Failed to get RSVP stats from API: $e");
      return {}; // Return an empty map on failure
    }
  }
}
